/*
====================
Crear BD y esquemas
====================
Proposito Script:
El codigo crea una nueva base de datos llamada "DataWarehouse" despues de checkear si ya existe.
Si ya existe, se borra y recrea
Por ultimo sae crean los tres esquemas de la base de datos "bronze" "silver" "gold".
*/

USE master;
GO

--Borrar y recrear la base de datos "DataWarehouse" asegurandose hipoteticamente que nadie la estuviera usando
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN 
	ALTER DATABASE DataWarehouse SET SINGLE_USER ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

--Crear la base de datos
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;

--Crear los esquemas bronze-silver-gold
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
