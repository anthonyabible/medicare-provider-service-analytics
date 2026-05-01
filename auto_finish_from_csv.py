#!/usr/bin/env python3
"""Generate portfolio-ready outputs from the official CMS 2023 CSV.

This script is intentionally chunked so it can handle a large public-use file
without loading the whole dataset into memory.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, Iterable, Tuple

import pandas as pd
import matplotlib.pyplot as plt

EXPECTED_FILENAME = 'MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv'

TEXT_COLS = [
    'Rndrng_NPI', 'Rndrng_Prvdr_Last_Org_Name', 'Rndrng_Prvdr_First_Name',
    'Rndrng_Prvdr_MI', 'Rndrng_Prvdr_Crdntls', 'Rndrng_Prvdr_Ent_Cd',
    'Rndrng_Prvdr_St1', 'Rndrng_Prvdr_St2', 'Rndrng_Prvdr_City',
    'Rndrng_Prvdr_State_Abrvtn', 'Rndrng_Prvdr_State_FIPS', 'Rndrng_Prvdr_Zip5',
    'Rndrng_Prvdr_RUCA', 'Rndrng_Prvdr_RUCA_Desc', 'Rndrng_Prvdr_Cntry',
    'Rndrng_Prvdr_Type', 'Rndrng_Prvdr_Mdcr_Prtcptg_Ind', 'HCPCS_Cd',
    'HCPCS_Desc', 'HCPCS_Drug_Ind', 'Place_Of_Srvc'
]
NUMERIC_COLS = [
    'Tot_Benes', 'Tot_Srvcs', 'Tot_Bene_Day_Srvcs', 'Avg_Sbmtd_Chrg',
    'Avg_Mdcr_Alowd_Amt', 'Avg_Mdcr_Pymt_Amt', 'Avg_Mdcr_Stdzd_Amt'
]


def money(value: float) -> str:
    if value >= 1_000_000_000:
        return f"${value/1_000_000_000:.2f}B"
    if value >= 1_000_000:
        return f"${value/1_000_000:.2f}M"
    return f"${value:,.0f}"


def pct(value: float) -> str:
    return f"{value:.1f}%"


def load_chunks(csv_path: Path, chunksize: int = 200_000) -> Iterable[pd.DataFrame]:
    dtype_map = {col: 'string' for col in TEXT_COLS + NUMERIC_COLS}
    return pd.read_csv(csv_path, dtype=dtype_map, chunksize=chunksize, low_memory=False)


def clean_chunk(chunk: pd.DataFrame) -> pd.DataFrame:
    df = chunk.copy()
    for col in TEXT_COLS:
        if col in df.columns:
            df[col] = df[col].astype('string').str.strip()
            df[col] = df[col].replace({'': pd.NA, 'nan': pd.NA, 'None': pd.NA})
    for col in NUMERIC_COLS:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
    df = df[
        df['Rndrng_NPI'].notna() &
        df['HCPCS_Cd'].notna() &
        df['Rndrng_Prvdr_Type'].notna() &
        df['Avg_Mdcr_Pymt_Amt'].notna() & (df['Avg_Mdcr_Pymt_Amt'] > 0) &
        df['Tot_Srvcs'].notna() & (df['Tot_Srvcs'] > 0)
    ].copy()
    if df.empty:
        return df

    df['provider_npi'] = df['Rndrng_NPI'].astype(str).str.zfill(10)
    df['provider_state'] = df['Rndrng_Prvdr_State_Abrvtn']
    df['provider_type'] = df['Rndrng_Prvdr_Type']
    df['hcpcs_code'] = df['HCPCS_Cd']
    df['hcpcs_desc'] = df['HCPCS_Desc'].fillna('Unknown HCPCS description')
    df['hcpcs_label'] = df['hcpcs_code'] + ' - ' + df['hcpcs_desc']
    df['drug_group'] = df['HCPCS_Drug_Ind'].map(lambda x: 'Drug' if str(x).strip().upper() == 'Y' else 'Non-Drug')
    pos_map = {'F': 'Facility', 'O': 'Non-Facility'}
    df['place_of_service'] = df['Place_Of_Srvc'].map(lambda x: pos_map.get(str(x).strip(), str(x).strip() if pd.notna(x) else None))
    df['est_total_payment'] = df['Tot_Srvcs'] * df['Avg_Mdcr_Pymt_Amt']
    df['est_total_std_payment'] = df['Tot_Srvcs'] * df['Avg_Mdcr_Stdzd_Amt']
    df['est_total_submitted_charge'] = df['Tot_Srvcs'] * df['Avg_Sbmtd_Chrg']
    return df


def add_sum(target: Dict[str, float], key: str, value: float) -> None:
    if key is None or (isinstance(key, float) and math.isnan(key)):
        return
    target[key] += float(value)


def add_pair_sum(target: Dict[Tuple[str, str], float], key1: str, key2: str, value: float) -> None:
    if not key1 or not key2:
        return
    target[(key1, key2)] += float(value)


def top_from_dict(metric_dict: Dict, n: int = 10):
    return sorted(metric_dict.items(), key=lambda kv: kv[1], reverse=True)[:n]


def build_outputs(csv_path: Path, out_dir: Path) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)

    row_count = 0
    provider_npis = set()
    states = set()
    hcpcs = set()
    total_payment = 0.0
    total_std_payment = 0.0
    total_services = 0.0

    state_services = defaultdict(float)
    state_std_payment = defaultdict(float)
    provider_type_payment = defaultdict(float)
    provider_type_services = defaultdict(float)
    ct_provider_type_payment = defaultdict(float)
    hcpcs_payment = defaultdict(float)
    hcpcs_services = defaultdict(float)
    hcpcs_std_payment = defaultdict(float)
    drug_payment = defaultdict(float)
    pos_services = defaultdict(float)
    pos_std_payment = defaultdict(float)
    combo_services = defaultdict(float)
    combo_std_payment = defaultdict(float)

    for chunk in load_chunks(csv_path):
        df = clean_chunk(chunk)
        if df.empty:
            continue
        row_count += len(df)
        provider_npis.update(df['provider_npi'].dropna().astype(str).unique().tolist())
        states.update(df['provider_state'].dropna().astype(str).unique().tolist())
        hcpcs.update(df['hcpcs_code'].dropna().astype(str).unique().tolist())
        total_payment += float(df['est_total_payment'].sum())
        total_std_payment += float(df['est_total_std_payment'].sum())
        total_services += float(df['Tot_Srvcs'].sum())

        grouped = df.groupby('provider_state', dropna=True).agg(services=('Tot_Srvcs', 'sum'), std_payment=('est_total_std_payment', 'sum'))
        for idx, rec in grouped.iterrows():
            state_services[str(idx)] += float(rec['services'])
            state_std_payment[str(idx)] += float(rec['std_payment'])

        grouped = df.groupby('provider_type', dropna=True).agg(payment=('est_total_payment', 'sum'), services=('Tot_Srvcs', 'sum'))
        for idx, rec in grouped.iterrows():
            provider_type_payment[str(idx)] += float(rec['payment'])
            provider_type_services[str(idx)] += float(rec['services'])

        ct_df = df[df['provider_state'] == 'CT']
        if not ct_df.empty:
            grouped = ct_df.groupby('provider_type', dropna=True)['est_total_payment'].sum()
            for idx, value in grouped.items():
                ct_provider_type_payment[str(idx)] += float(value)

        grouped = df.groupby('hcpcs_label', dropna=True).agg(payment=('est_total_payment', 'sum'), services=('Tot_Srvcs', 'sum'), std_payment=('est_total_std_payment', 'sum'))
        for idx, rec in grouped.iterrows():
            hcpcs_payment[str(idx)] += float(rec['payment'])
            hcpcs_services[str(idx)] += float(rec['services'])
            hcpcs_std_payment[str(idx)] += float(rec['std_payment'])

        grouped = df.groupby('drug_group', dropna=True)['est_total_payment'].sum()
        for idx, value in grouped.items():
            drug_payment[str(idx)] += float(value)

        grouped = df.groupby('place_of_service', dropna=True).agg(services=('Tot_Srvcs', 'sum'), std_payment=('est_total_std_payment', 'sum'))
        for idx, rec in grouped.iterrows():
            pos_services[str(idx)] += float(rec['services'])
            pos_std_payment[str(idx)] += float(rec['std_payment'])

        grouped = df.groupby(['provider_type', 'hcpcs_label'], dropna=True).agg(services=('Tot_Srvcs', 'sum'), std_payment=('est_total_std_payment', 'sum'))
        for (ptype, label), rec in grouped.iterrows():
            combo_services[(str(ptype), str(label))] += float(rec['services'])
            combo_std_payment[(str(ptype), str(label))] += float(rec['std_payment'])

    state_std_per_service = {
        state: (state_std_payment[state] / state_services[state])
        for state in state_services if state_services[state] > 0
    }
    national_std_per_service = total_std_payment / total_services if total_services else float('nan')
    ct_std_per_service = state_std_per_service.get('CT', float('nan'))
    state_rank_desc = sorted(state_std_per_service.items(), key=lambda kv: kv[1], reverse=True)
    ct_rank = next((i + 1 for i, (state, _) in enumerate(state_rank_desc) if state == 'CT'), None)

    top_provider_type = max(provider_type_payment.items(), key=lambda kv: kv[1]) if provider_type_payment else ('N/A', 0.0)
    top_hcpcs = max(hcpcs_payment.items(), key=lambda kv: kv[1]) if hcpcs_payment else ('N/A', 0.0)
    top_drug_group = max(drug_payment.items(), key=lambda kv: kv[1]) if drug_payment else ('N/A', 0.0)

    pos_std_per_service = {
        pos: (pos_std_payment[pos] / pos_services[pos])
        for pos in pos_services if pos_services[pos] > 0
    }
    higher_pos = max(pos_std_per_service.items(), key=lambda kv: kv[1])[0] if pos_std_per_service else 'N/A'
    ct_top_provider_type = max(ct_provider_type_payment.items(), key=lambda kv: kv[1]) if ct_provider_type_payment else ('N/A', 0.0)

    hcpcs_baseline_std_per_service = {
        label: (hcpcs_std_payment[label] / hcpcs_services[label])
        for label in hcpcs_services if hcpcs_services[label] > 0
    }

    above_baseline_candidates = []
    for combo, services in combo_services.items():
        if services <= 0:
            continue
        combo_std = combo_std_payment[combo] / services
        baseline = hcpcs_baseline_std_per_service.get(combo[1])
        if baseline is None:
            continue
        lift = combo_std - baseline
        if lift > 0:
            score = services * lift
            above_baseline_candidates.append((combo, score, combo_std, baseline, services))
    above_baseline_candidates.sort(key=lambda x: x[1], reverse=True)
    best_combo = above_baseline_candidates[0] if above_baseline_candidates else (("N/A", "N/A"), 0.0, 0.0, 0.0, 0.0)

    metrics = {
        'expected_filename': EXPECTED_FILENAME,
        'clean_record_count': int(row_count),
        'distinct_providers': int(len(provider_npis)),
        'distinct_states': int(len(states)),
        'distinct_hcpcs_codes': int(len(hcpcs)),
        'estimated_total_medicare_payment': total_payment,
        'estimated_total_standardized_payment': total_std_payment,
        'national_standardized_payment_per_service': national_std_per_service,
        'ct_standardized_payment_per_service': ct_std_per_service,
        'ct_rank_by_standardized_payment_per_service': ct_rank,
        'top_provider_type_by_payment': {'label': top_provider_type[0], 'value': top_provider_type[1]},
        'top_hcpcs_by_payment': {'label': top_hcpcs[0], 'value': top_hcpcs[1]},
        'drug_group_with_larger_payment_share': top_drug_group[0],
        'higher_standardized_payment_setting': higher_pos,
        'ct_top_provider_type_by_payment': {'label': ct_top_provider_type[0], 'value': ct_top_provider_type[1]},
        'best_above_baseline_combo': {
            'provider_type': best_combo[0][0],
            'hcpcs_label': best_combo[0][1],
            'score': best_combo[1],
            'combo_standardized_payment_per_service': best_combo[2],
            'hcpcs_baseline_standardized_payment_per_service': best_combo[3],
            'services': best_combo[4],
        },
    }
    metrics['ct_vs_national_pct_diff'] = (
        ((ct_std_per_service / national_std_per_service) - 1) * 100
        if national_std_per_service and not pd.isna(ct_std_per_service)
        else float('nan')
    )

    (out_dir/'summary_metrics.json').write_text(json.dumps(metrics, indent=2))

    def write_rank_csv(path: Path, rows, cols):
        pd.DataFrame(rows, columns=cols).to_csv(path, index=False)

    write_rank_csv(out_dir/'top_provider_types.csv', [(k, v, provider_type_services.get(k, 0.0)) for k, v in top_from_dict(provider_type_payment, 15)], ['provider_type', 'estimated_medicare_payment', 'total_services'])
    write_rank_csv(out_dir/'top_hcpcs.csv', [(k, v, hcpcs_services.get(k, 0.0)) for k, v in top_from_dict(hcpcs_payment, 15)], ['hcpcs_label', 'estimated_medicare_payment', 'total_services'])
    write_rank_csv(out_dir/'state_standardized_payment_per_service.csv', [(k, v, state_services.get(k, 0.0)) for k, v in state_rank_desc], ['state', 'standardized_payment_per_service', 'total_services'])
    write_rank_csv(out_dir/'ct_provider_types.csv', [(k, v) for k, v in top_from_dict(ct_provider_type_payment, 15)], ['provider_type', 'estimated_medicare_payment'])

    findings_md = "# Auto-generated Key Findings\n\n"
    findings_md += (
        f"- The cleaned dataset contains **{row_count:,} records**, **{len(provider_npis):,} providers**, "
        f"**{len(states):,} states**, and **{len(hcpcs):,} HCPCS codes**, representing about "
        f"**{money(total_payment)}** in estimated Medicare payment and **{money(total_std_payment)}** "
        f"in estimated standardized payment.\n"
    )
    if not pd.isna(ct_std_per_service):
        findings_md += (
            f"- Connecticut's standardized payment per service is **${ct_std_per_service:,.2f}**, compared with a national benchmark of "
            f"**${national_std_per_service:,.2f}**, a difference of **{pct(metrics['ct_vs_national_pct_diff'])}**.\n"
        )
    else:
        findings_md += "- Connecticut benchmark metrics were not available from the filtered dataset.\n"
    if ct_rank is not None:
        findings_md += f"- Connecticut ranks **#{ct_rank}** nationally on standardized payment per service.\n"
    findings_md += f"- The top provider specialty by estimated Medicare payment is **{top_provider_type[0]}**.\n"
    findings_md += f"- The top HCPCS procedure by estimated Medicare payment is **{top_hcpcs[0]}**.\n"
    findings_md += f"- **{top_drug_group[0]}** services account for the larger share of estimated Medicare payment.\n"
    findings_md += f"- The higher standardized-payment setting is **{higher_pos}**.\n"
    findings_md += f"- In Connecticut, the top provider specialty by estimated Medicare payment is **{ct_top_provider_type[0]}**.\n"
    findings_md += f"- The highest-volume above-baseline provider-type and HCPCS combination is **{best_combo[0][0]} / {best_combo[0][1]}**.\n"
    (out_dir/'key_findings.md').write_text(findings_md)

    summary_md = f"""# Executive Summary

This project analyzed the official 2023 CMS Medicare physician and other practitioners provider-service file using a cleaned, weighted workflow designed for SQL and Power BI. The filtered analytical dataset retained {row_count:,} high-usable rows spanning {len(provider_npis):,} providers and {len(hcpcs):,} HCPCS codes.

Estimated Medicare payment across the cleaned analytical dataset totals {money(total_payment)}, while estimated standardized payment totals {money(total_std_payment)}. The largest payment specialty is **{top_provider_type[0]}**, and the largest payment procedure is **{top_hcpcs[0]}**.

For Connecticut benchmarking, standardized payment per service is {('$' + format(ct_std_per_service, ',.2f')) if not pd.isna(ct_std_per_service) else 'not available'}, versus a national benchmark of ${national_std_per_service:,.2f}. Connecticut ranks #{ct_rank if ct_rank is not None else 'N/A'} nationally on standardized payment per service.

The outputs in this folder can be pasted directly into the README and used as source tables for a one-page Power BI dashboard.
"""
    (out_dir/'executive_summary.md').write_text(summary_md)

    # Charts
    top_provider_df = pd.DataFrame([(k, v) for k, v in top_from_dict(provider_type_payment, 10)], columns=['provider_type', 'estimated_medicare_payment'])
    top_hcpcs_df = pd.DataFrame([(k, v) for k, v in top_from_dict(hcpcs_payment, 10)], columns=['hcpcs_label', 'estimated_medicare_payment'])
    state_df = pd.DataFrame(state_rank_desc[:15], columns=['state', 'standardized_payment_per_service'])

    def save_barh(df, label_col, value_col, title, path):
        if df.empty:
            return
        fig, ax = plt.subplots(figsize=(11, 6))
        df = df.sort_values(value_col, ascending=True)
        ax.barh(df[label_col], df[value_col])
        ax.set_title(title)
        ax.set_xlabel(value_col.replace('_', ' ').title())
        plt.tight_layout()
        fig.savefig(path, dpi=200, bbox_inches='tight')
        plt.close(fig)

    save_barh(top_provider_df, 'provider_type', 'estimated_medicare_payment', 'Top Provider Types by Estimated Medicare Payment', out_dir/'top_provider_types.png')
    save_barh(top_hcpcs_df, 'hcpcs_label', 'estimated_medicare_payment', 'Top HCPCS Procedures by Estimated Medicare Payment', out_dir/'top_hcpcs.png')
    save_barh(state_df, 'state', 'standardized_payment_per_service', 'Top States by Standardized Payment per Service', out_dir/'state_rankings.png')

    return metrics


def main() -> None:
    parser = argparse.ArgumentParser(description='Generate recruiter-ready outputs from the CMS 2023 provider-service CSV.')
    parser.add_argument('--csv', required=True, help='Path to the CMS CSV file')
    parser.add_argument('--out', default='outputs', help='Output directory for generated files')
    args = parser.parse_args()

    csv_path = Path(args.csv)
    out_dir = Path(args.out)
    if not csv_path.exists():
        raise SystemExit(f'CSV not found: {csv_path}')

    metrics = build_outputs(csv_path, out_dir)
    print('Generated outputs in', out_dir)
    print(json.dumps(metrics, indent=2))


if __name__ == '__main__':
    main()
