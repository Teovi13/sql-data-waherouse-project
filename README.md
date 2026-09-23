# SQL Data Warehouse Project

A data warehouse built in **SQL Server (T-SQL)** following the **Medallion
Architecture (Bronze → Silver → Gold)**. It integrates data from two source
systems (CRM and ERP) into a dimensional star schema model, ready for
analytical queries and BI.

Portfolio project built as part of my path into **Data Engineering**,
applying ETL, dimensional modeling, and data quality best practices on top
of SQL Server.

---

## Architecture

![Data Architecture](docs/data_architecture.png)

The project follows the **Medallion Architecture** pattern, with three
layers that progressively refine the data:

| Layer | Purpose | Object type | Transformations |
|---|---|---|---|
| **Bronze** | Raw data, exactly as it arrives from the sources (CRM/ERP) | Tables | None (raw load via `BULK INSERT`) |
| **Silver** | Cleaned and standardized data | Tables | Cleansing, standardization, normalization, derived columns |
| **Gold** | Business-ready data, modeled as a star schema | Views | Integration, aggregations, business logic |

**End-to-end flow:** Sources (CSV) → Bronze → Silver → Gold → SQL Queries / BI

More diagrams available in [`docs/`](docs/):
- [`data_flow.png`](docs/data_flow.png) — data flow between tables across layers
- [`data_integration.png`](docs/data_integration.png) — how CRM and ERP are integrated
- [`star_schema.png`](docs/star_schema.png) — dimensional model of the Gold layer

---

## Repository structure

```
sql-data-waherouse-project/
│
├── datasets/                  # Source data (not included, see note below)
│   ├── source_crm/
│   └── source_erp/
│
├── scripts/                   # All SQL code for the pipeline
│   ├── init_database.sql      # Creates the DataWarehouse database and schemas
│   ├── bronze/
│   │   ├── ddl_bronze.sql     # Bronze table definitions
│   │   └── proc_load_bronze.sql   # Bronze load (BULK INSERT + logging)
│   ├── silver/
│   │   ├── ddl_silver.sql     # Silver table definitions
│   │   └── proc_load_silver.sql   # ETL Bronze → Silver (cleansing/transformation)
│   └── gold/
│       └── ddl_gold.sql       # Gold views (star schema: dims + fact)
│
├── tests/                     # Data quality checks
│   ├── quality_checks_silver.sql
│   └── quality_checks_gold.sql
│
├── docs/                      # Documentation and diagrams
│   ├── data_catalog.md        # Data dictionary for the Gold layer
│   ├── naming_conventions.md  # Naming conventions used throughout the project
│   ├── data_architecture.drawio / .png
│   ├── data_flow.drawio / .png
│   ├── data_integration.drawio / .png
│   └── star_schema.drawio / .png
│
├── LICENSE
└── README.md
```

---

## How to run this project

> Requires SQL Server (SSMS or Azure Data Studio).

1. **Create the database and schemas**
   ```sql
   -- scripts/init_database.sql
   ```
   Creates the `DataWarehouse` database and the three schemas: `bronze`,
   `silver`, `gold`.

2. **Create the tables and load the Bronze layer**
   ```sql
   -- scripts/bronze/ddl_bronze.sql
   -- scripts/bronze/proc_load_bronze.sql
   EXEC bronze.load_bronze;
   ```

3. **Create the tables and load the Silver layer**
   ```sql
   -- scripts/silver/ddl_silver.sql
   -- scripts/silver/proc_load_silver.sql
   EXEC silver.load_silver;
   ```

4. **Create the Gold layer views**
   ```sql
   -- scripts/gold/ddl_gold.sql
   ```

5. **Validate data quality**
   ```sql
   -- tests/quality_checks_silver.sql
   -- tests/quality_checks_gold.sql
   ```
   Each check should return **0 rows**. Any row returned points to a data
   quality issue to investigate in the corresponding layer.

6. **Query the Gold layer**
   ```sql
   SELECT * FROM gold.dim_customers;
   SELECT * FROM gold.dim_products;
   SELECT * FROM gold.fact_sales;
   ```

### About the datasets

The original CSV files (`datasets/source_crm/`, `datasets/source_erp/`) are
course material from the SQL Server course I'm following and **are not
included in this repository** due to course content rights. The folders
keep their structure so the pipeline stays reproducible: if you have access
to the same course, or you prepare CSV files with the same column structure
(see [`docs/data_catalog.md`](docs/data_catalog.md) and the DDL scripts in
`scripts/bronze/`), the project runs the same way.

---

## Data model (Gold Layer)

The Gold layer exposes a simple **star schema**: two dimensions and one
fact table.

![Star Schema](docs/star_schema.png)

- **`gold.dim_customers`** — customer dimension (CRM + ERP combined)
- **`gold.dim_products`** — product dimension (active versions only)
- **`gold.fact_sales`** — sales facts, one record per product line sold

Full column-by-column data dictionary: [`docs/data_catalog.md`](docs/data_catalog.md)

Naming conventions used throughout the project: [`docs/naming_conventions.md`](docs/naming_conventions.md)

---

## Technical highlights

- **Strict layer separation**, each with its own schema and single responsibility
- **Stored procedures with logging and error handling** (`TRY/CATCH`, per-table duration `PRINT`) in the Bronze and Silver loads
- **Data reconciliation in Silver**: cleansing of dates stored as `INT`, recalculating price/sales when the source data is inconsistent, respecting the dependency order between calculated columns
- **Slowly Changing Dimension** for products: `silver.crm_prd_info` keeps the version history of each product (`prd_start_dt`/`prd_end_dt` computed with `LEAD`), and `gold.dim_products` filters down to the current version only
- **Surrogate keys** generated with `ROW_NUMBER()` in the Gold dimensions, decoupling business keys from warehouse keys
- **Automated quality checks** for key uniqueness, referential integrity between the fact table and its dimensions, and data consistency (`sales = quantity × price`)

---

## Credits

Dataset and project structure based on the SQL Server course by
**Data with Baraa**. The implementation, documentation, and design
decisions in this repository are my own.

---

## License

This project is licensed under the [MIT License](LICENSE).
