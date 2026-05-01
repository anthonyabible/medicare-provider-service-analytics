#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
metrics_path = ROOT / 'outputs' / 'summary_metrics.json'
out_path = ROOT / 'assets' / 'recruiter_snapshot.png'

W, H = 1400, 800
img = Image.new('RGB', (W, H), '#08111f')
d = ImageDraw.Draw(img)

def font(size, bold=False):
    for p in [
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    ]:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()

if metrics_path.exists():
    metrics = json.loads(metrics_path.read_text())
else:
    metrics = {}

# Header
d.rounded_rectangle((40, 40, 1360, 180), radius=28, fill='#10213e')
d.text((70, 70), 'Medicare Payment Intelligence Dashboard', fill='white', font=font(42, True))
d.text((70, 130), 'Recruiter snapshot: SQL pipeline, weighted benchmarking, and Power BI-ready outputs', fill='#c7d2e3', font=font(24))

cards = [
    ('Clean Records', f"{metrics.get('clean_record_count', '[run script]'):,}" if isinstance(metrics.get('clean_record_count'), int) else '[run script]'),
    ('Distinct Providers', f"{metrics.get('distinct_providers', '[run script]'):,}" if isinstance(metrics.get('distinct_providers'), int) else '[run script]'),
    ('Total Est Payment', (f"${metrics.get('estimated_total_medicare_payment',0)/1_000_000_000:.2f}B") if metrics.get('estimated_total_medicare_payment') else '[run script]'),
    ('CT Rank', f"#{metrics.get('ct_rank_by_standardized_payment_per_service')}" if metrics.get('ct_rank_by_standardized_payment_per_service') else '[run script]'),
]

x = 40
for title, value in cards:
    d.rounded_rectangle((x, 230, x+300, 390), radius=24, fill='#12284c')
    d.text((x+24, 255), title, fill='#c7d2e3', font=font(24, True))
    d.text((x+24, 315), value, fill='white', font=font(34, True))
    x += 330

# Narrative blocks
d.rounded_rectangle((40, 430, 680, 740), radius=24, fill='#0f7b6c')
d.text((70, 465), 'Why it reads well to recruiters', fill='white', font=font(28, True))
points = [
    'Uses a large official CMS dataset',
    'Shows raw -> clean -> views SQL workflow',
    'Uses weighted benchmarking, not weak simple averages',
    'Connecticut vs national story translates to business decisions',
    'Includes recruiter, resume, and interview docs',
]
y = 520
for p in points:
    d.text((78, y), f'• {p}', fill='white', font=font(22))
    y += 42

d.rounded_rectangle((720, 430, 1360, 740), radius=24, fill='#152746')
d.text((750, 465), 'Fast finish path', fill='white', font=font(28, True))
steps = [
    '1. Drop the official CSV into data/raw/',
    '2. Run scripts/auto_finish_from_csv.py',
    '3. Paste key findings into README',
    '4. Import output CSVs into Power BI',
    '5. Save one screenshot and publish',
]
y = 520
for s in steps:
    d.text((758, y), s, fill='#d7e3f4', font=font(22))
    y += 42

img.save(out_path)
print(f'Wrote {out_path}')
