# Import in MySQL Workbench

## Easiest method

1. Run `sql/01_setup_mysql.sql`
2. In MySQL Workbench, right-click `provider_service_raw`
3. Choose **Table Data Import Wizard**
4. Select `MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv`
5. Keep comma delimiter and quoted strings enabled
6. Import into existing table `provider_service_raw`
7. Confirm row count
8. Run the remaining SQL files in order

## Quick sanity check

After import, run:

```sql
USE medicare_analysis;
SELECT COUNT(*) FROM provider_service_raw;
```

If the row count is zero, the import did not actually complete. An impressive little trick, but not the useful kind.
