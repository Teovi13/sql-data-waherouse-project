# SQL Data Warehouse Project

Data warehouse construido en **SQL Server (T-SQL)** siguiendo la arquitectura
**Medallion (Bronze → Silver → Gold)**. Integra datos de dos sistemas fuente
(CRM y ERP) en un modelo dimensional en estrella, listo para consultas
analíticas y BI.

Proyecto de portafolio realizado como parte de mi camino hacia **Data
Engineering**, aplicando ETL, modelado dimensional y buenas prácticas de
calidad de datos sobre SQL Server.

---

## Arquitectura

![Data Architecture](docs/data_architecture.png)

El proyecto sigue el patrón **Medallion Architecture**, con tres capas que
van refinando los datos progresivamente:

| Capa | Propósito | Tipo de objeto | Transformaciones |
|---|---|---|---|
| **Bronze** | Datos crudos, tal como llegan de las fuentes (CRM/ERP) | Tablas | Ninguna (carga cruda vía `BULK INSERT`) |
| **Silver** | Datos limpios y estandarizados | Tablas | Limpieza, estandarización, normalización, columnas derivadas |
| **Gold** | Datos listos para negocio, modelados en estrella | Vistas | Integración, agregaciones, lógica de negocio |

**Flujo completo:** Fuentes (CSV) → Bronze → Silver → Gold → Consultas SQL / BI

Más diagramas disponibles en [`docs/`](docs/):
- [`data_flow.png`](docs/data_flow.png) — flujo de datos entre tablas por capa
- [`data_integration.png`](docs/data_integration.png) — cómo se integran CRM y ERP
- [`star_schema.png`](docs/star_schema.png) — modelo dimensional de la capa Gold

---

## Estructura del repositorio

```
sql-data-waherouse-project/
│
├── datasets/                  # Datos fuente (no incluidos, ver nota abajo)
│   ├── source_crm/
│   └── source_erp/
│
├── scripts/                   # Todo el código SQL del pipeline
│   ├── init_database.sql      # Crea la base DataWarehouse y los schemas
│   ├── bronze/
│   │   ├── ddl_bronze.sql     # Definición de tablas Bronze
│   │   └── proc_load_bronze.sql   # Carga Bronze (BULK INSERT + logging)
│   ├── silver/
│   │   ├── ddl_silver.sql     # Definición de tablas Silver
│   │   └── proc_load_silver.sql   # ETL Bronze → Silver (limpieza/transformación)
│   └── gold/
│       └── ddl_gold.sql       # Vistas Gold (star schema: dims + fact)
│
├── tests/                     # Checks de calidad de datos
│   ├── quality_checks_silver.sql
│   └── quality_checks_gold.sql
│
├── docs/                      # Documentación y diagramas
│   ├── data_catalog.md        # Diccionario de datos de la capa Gold
│   ├── naming_conventions.md  # Convenciones de nombres usadas en el proyecto
│   ├── data_architecture.drawio / .png
│   ├── data_flow.drawio / .png
│   ├── data_integration.drawio / .png
│   └── star_schema.drawio / .png
│
├── LICENSE
└── README.md
```

---

## Cómo ejecutar el proyecto

> Requiere SQL Server (SSMS o Azure Data Studio).

1. **Crear la base y los schemas**
   ```sql
   -- scripts/init_database.sql
   ```
   Crea la base `DataWarehouse` y los tres schemas: `bronze`, `silver`, `gold`.

2. **Crear las tablas y cargar la capa Bronze**
   ```sql
   -- scripts/bronze/ddl_bronze.sql
   -- scripts/bronze/proc_load_bronze.sql
   EXEC bronze.load_bronze;
   ```

3. **Crear las tablas y cargar la capa Silver**
   ```sql
   -- scripts/silver/ddl_silver.sql
   -- scripts/silver/proc_load_silver.sql
   EXEC silver.load_silver;
   ```

4. **Crear las vistas de la capa Gold**
   ```sql
   -- scripts/gold/ddl_gold.sql
   ```

5. **Validar la calidad de los datos**
   ```sql
   -- tests/quality_checks_silver.sql
   -- tests/quality_checks_gold.sql
   ```
   Cada check debería devolver **0 filas**. Si devuelve algo, indica un
   problema de calidad a investigar en la capa correspondiente.

6. **Consultar la capa Gold**
   ```sql
   SELECT * FROM gold.dim_customers;
   SELECT * FROM gold.dim_products;
   SELECT * FROM gold.fact_sales;
   ```

### Sobre los datasets

Los archivos CSV originales (`datasets/source_crm/`, `datasets/source_erp/`)
son material del curso de SQL Server que estoy siguiendo y **no se incluyen
en este repositorio** por derechos de contenido del curso. Las carpetas
mantienen su estructura para que el pipeline sea reproducible: si tenés
acceso al mismo curso, o preparás archivos CSV con la misma estructura de
columnas (ver [`docs/data_catalog.md`](docs/data_catalog.md) y los scripts
DDL en `scripts/bronze/`), el proyecto corre igual.

---

## Modelo de datos (Gold Layer)

La capa Gold expone un **esquema en estrella** simple: dos dimensiones y
una tabla de hechos.

![Star Schema](docs/star_schema.png)

- **`gold.dim_customers`** — dimensión de clientes (CRM + ERP combinados)
- **`gold.dim_products`** — dimensión de productos (solo versiones activas)
- **`gold.fact_sales`** — hechos de ventas, un registro por línea de producto vendido

Diccionario de datos completo, columna por columna: [`docs/data_catalog.md`](docs/data_catalog.md)

Convenciones de nombres usadas en todo el proyecto: [`docs/naming_conventions.md`](docs/naming_conventions.md)

---

## Highlights técnicos

- **Separación estricta en capas**, cada una con su propio schema y responsabilidad única
- **Stored procedures con logging y manejo de errores** (`TRY/CATCH`, `PRINT` de duración por tabla) en las cargas Bronze y Silver
- **Reconciliación de datos en Silver**: limpieza de fechas almacenadas como `INT`, recálculo de precio/ventas cuando los datos fuente son inconsistentes, respetando el orden de dependencia entre columnas calculadas
- **Slowly Changing Dimension** en productos: `silver.crm_prd_info` conserva el historial de versiones de un producto (`prd_start_dt`/`prd_end_dt` calculado con `LEAD`), y `gold.dim_products` filtra solo la versión vigente
- **Surrogate keys** generadas con `ROW_NUMBER()` en las dimensiones Gold, desacoplando las claves de negocio de las claves de warehouse
- **Quality checks automatizados** para unicidad de claves, integridad referencial entre fact y dimensiones, y consistencia de datos (`sales = quantity × price`)

---

## Créditos

Dataset y estructura del curso basados en el curso de SQL Server de
**Data with Baraa**. La implementación, documentación y decisiones de
diseño de este repositorio son propias.

---

## Licencia

Este proyecto está bajo licencia [MIT](LICENSE).
