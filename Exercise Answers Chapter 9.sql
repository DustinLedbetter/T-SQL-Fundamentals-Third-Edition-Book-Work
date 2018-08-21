----------------------
-- Chapter 9 (Temporal Tables:)--
----------------------

----------------
--Chapter Work--
----------------


-- Create temporal tables --

--
--1.)
--// create a temporal table (used to keep history of table changes)
CREATE TABLE dbo.Employees
(
  empid      INT                         NOT NULL
    CONSTRAINT PK_Employees PRIMARY KEY NONCLUSTERED,
  empname    VARCHAR(25)                 NOT NULL,
  department VARCHAR(50)                 NOT NULL,
  salary     NUMERIC(10, 2)              NOT NULL,
  sysstart   DATETIME2(0)
    GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
  sysend     DATETIME2(0)
    GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL,
	PERIOD FOR SYSTEM_TIME (sysstart, sysend),
	INDEX ix_Employees CLUSTERED(empid, sysstart, sysend)
)
WITH ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.EmployeesHistory ) );
GO


--2.)
--// Make a current non-temporal table into a temporal one
ALTER TABLE dbo.Employees ADD
  sysstart DATETIME2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL
    CONSTRAINT DFT_Employees_sysstart DEFAULT('19000101'),
  sysend DATETIME2(0) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL
    CONSTRAINT DFT_Employees_sysend DEFAULT('99991231 23:59:59'),
  PERIOD FOR SYSTEM_TIME (sysstart, sysend);

ALTER TABLE dbo.Employees
  SET ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.EmployeesHistory ) );


--3.)
--// 
--view normal will have hidden fields
SELECT * 
FROM dbo.Employees;

--to view hidden files you must be explicit
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;


--4.)
--// alter table then view current and past table
ALTER TABLE dbo.Employees
  ADD hiredate DATE NOT NULL
    CONSTRAINT DFT_Employees_hiredate DEFAULT('19000101');

--view current
SELECT *
FROM dbo.Employees;

--view past
SELECT *
FROM dbo.EmployeesHistory;


--NOTE: If you ALTER the current table; It will also happen to the history table


--5.)
--//Dropping a column form table

-- remove constraint from Employees
ALTER TABLE dbo.Employees
  DROP CONSTRAINT DFT_Employees_hiredate;
  
-- Drop column
ALTER TABLE dbo.Employees
  DROP COLUMN hiredate;

 
-- Modifying Data --
--NOTE: TRUNCATE not supported in sql 2016 with temporal table data modifying


--1.)
--// 
INSERT INTO dbo.Employees(empid, empname, department, salary)
  VALUES(1, 'Sara', 'IT'       , 50000.00),
        (2, 'Don' , 'HR'       , 45000.00),
        (3, 'Judy', 'Sales'    , 55000.00),
        (4, 'Yael', 'Marketing', 55000.00),
        (5, 'Sven', 'IT'       , 45000.00),
        (6, 'Paul', 'Sales'    , 40000.00);

--// view tables
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;


--2.)
--// a simple delete
DELETE FROM dbo.Employees
WHERE empid = 6;

--// view tables
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;


--3.)
--// a simple update
UPDATE dbo.Employees
  SET salary *= 1.05
WHERE department = 'IT';

--// view tables
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;


--4.)
--// showing how if start a transaction. It doesn't matter when you stop it. 
--	 or what you do inbetween, It will all be saved with the time you started it

--start transaction
BEGIN TRAN;

UPDATE dbo.Employees
  SET department = 'Sales'
WHERE empid = 5;
GO

--end transaction
UPDATE dbo.Employees
  SET department = 'IT'
WHERE empid = 3;

COMMIT TRAN;

--// view tables
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees;

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;



-- Querying Data --


--1.)
--// viewing history from a certain point in time 

--fails since we haven't posted before this time
SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:00:00';

--shows the fields since they existed then
SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:10:00';


--2.)
--// can query multiple intances of the same data. used for comparing them at different points in time 
--// query returns this: sysstart <= @datetime AND sysend > @datetime
SELECT T2.empid, T2.empname,
  CAST( (T2.salary / T1.salary - 1.0) * 100.0 AS NUMERIC(10, 2) ) AS pct
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:10:00' AS T1
  INNER JOIN dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:25:00' AS T2
    ON T1.empid = T2.empid
   AND T2.salary > T1.salary;


--3.)
--// query returns this: sysstart < @end AND sysend > @start
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees
  FOR SYSTEM_TIME FROM '2016-02-16 17:15:26' TO '2016-02-16 17:20:02';


--4.)
--// query returns this: sysstart <= @end AND sysend > @start
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees
  FOR SYSTEM_TIME BETWEEN '2016-02-16 17:15:26' AND '2016-02-16 17:20:02';


--5.)
--// query returns this: sysstart >= @start AND sysend <= @end
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees
  FOR SYSTEM_TIME CONTAINED IN('2016-02-16 17:00:00', '2016-02-16 18:00:00');


--6.)
--// used to return all rows from both tables
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees FOR SYSTEM_TIME ALL;


--7.)
--// set start and end times to another time zone than UTC
SELECT empid, empname, department, salary, 
  sysstart AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' AS sysstart,
  CASE
    WHEN sysend = '9999-12-31 23:59:59'
      THEN sysend AT TIME ZONE 'UTC'
    ELSE sysend AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time'
  END AS sysend
FROM dbo.Employees FOR SYSTEM_TIME ALL;


--8.)
--// run the following code for cleanup
IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL
BEGIN
  IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Employees', N'U'), N'TableTemporalType') = 2
    ALTER TABLE dbo.Employees SET ( SYSTEM_VERSIONING = OFF );
  DROP TABLE IF EXISTS dbo.EmployeesHistory, dbo.Employees;
END;



-------------
--Exercises--
-------------

--Exercise 1:

--// Creating a temporal table

--Exercise 1-1:
-- MINE (correct, followed the book on creation)-- 
USE TSQLV4;

CREATE TABLE dbo.Departments
(
  deptid    INT                          NOT NULL
    CONSTRAINT PK_Departments PRIMARY KEY,
  deptname  VARCHAR(25)                  NOT NULL,
  mgrid INT                              NOT NULL,
  validfrom DATETIME2(0)
    GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
  validto   DATETIME2(0)
    GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL,
  PERIOD FOR SYSTEM_TIME (validfrom, validto)
)
WITH ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.DepartmentsHistory ) );


--Exercise 1-2:
-- MINE (done)-- 
--Found, it is in the tree as it's supposed to be


--Exercise 2:

--// modify data in the table

--Exercise 2-1:
-- MINE (correct, followed book example)--
SELECT CAST(SYSUTCDATETIME() AS DATETIME2(0)) AS P1;

INSERT INTO dbo.Departments(deptid, deptname, mgrid)
  VALUES(1, 'HR'       , 7 ),
        (2, 'IT'       , 5 ),
        (3, 'Sales'    , 11),
        (4, 'marketing', 13);

--P1= 2018-08-21 19:25:15


--Exercise 2-2:
-- MINE (correct, followed book example)--
SELECT CAST(SYSUTCDATETIME() AS DATETIME2(0)) AS P2;

BEGIN TRAN;

UPDATE dbo.Departments
  SET deptname = 'Sales and Marketing'
WHERE deptid = 3;

DELETE FROM dbo.Departments
WHERE deptid = 4;

COMMIT TRAN;

--P2= 2018-08-21 19:37:36


--Exercise 2-3:
-- MINE (correct, followed book example)--
SELECT CAST(SYSUTCDATETIME() AS DATETIME2(0)) AS P3;

UPDATE dbo.Departments
  SET mgrid = 13
WHERE deptid = 3;

--P3= 2018-08-21 19:38:58


--Exercise 3:

--// query data from the temporal table

--Exercise 3-1:
-- MINE(correct, followed book example)-- 
SELECT *
FROM dbo.Departments;


--Exercise 3-2:
-- MINE(correct, followed book example)-- 
SELECT *
FROM dbo.Departments
  FOR SYSTEM_TIME AS OF '2018-08-21 19:38:00';

--Exercise 3-3:
-- MINE(correct, followed book example)-- 
SELECT deptid, deptname, mgrid, validfrom, validto
FROM dbo.Departments
  FOR SYSTEM_TIME BETWEEN '2018-08-21 19:37:36'  --P2
                      AND '2018-08-21 19:38:58'; --P3


--Exercise 4:
-- MINE(correct, followed book example)--
ALTER TABLE dbo.Departments SET ( SYSTEM_VERSIONING = OFF );
DROP TABLE dbo.DepartmentsHistory, dbo.Departments;






	
	
	
	
	
	
	
	