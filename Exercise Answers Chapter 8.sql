----------------------
-- Chapter 8 (Data Modification:)--
----------------------

----------------
--Chapter Work--
----------------

-- INSERT Statement --


--1.)
--// First create a table to use for book work 
USE TSQLV4;

DROP TABLE IF EXISTS dbo.orders;

CREATE TABLE dbo.Orders
(
 orderid   INT           NOT NULL 
	CONSTRAINT PK_Orders PRIMARY KEY,
 orderdate DATE          NOT NULL
	CONSTRAINT DFT_orderdate DEFAULT(SYSDATETIME()),
 empid     INT           NOT NULL,
 custid    VARCHAR(10)   NOT NULL
);


--2.)
--// simple insert row query
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	VALUES(10001, '20160212', 3, 'A'); 

	
--3.)
--// Insert missing a variable(will have sysdate since not specified)
INSERT INTO dbo.Orders(orderid, empid, custid)
	VALUES(10002, 5, 'B'); 

	
--4.)
--// Inserting multiple rows at once
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	VALUES
		(10003, '20160213', 4, 'B'),
		(10004, '20160214', 1, 'A'),
		(10005, '20160213', 1, 'C'),
		(10006, '20160215', 3, 'C');

		
--5.)
--// using enhanced values clause as a table constructor to construct a derived table
SELECT *
FROM ( VALUES
		(10003, '20160213', 4, 'B'),
		(10004, '20160214', 1, 'A'),
		(10005, '20160213', 1, 'C'),
		(10006, '20160215', 3, 'C'))
		AS O(orderid, orderdate, empid, custid);


		
-- INSERT SELECT statement --

--1.)
--// inserting into a table the results from a select query
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	SELECT orderid, orderdate, empid, custid
	FROM Sales.Orders
	WHERE shipcountry = N'UK'; 



-- INSERT EXEC statement --

--1.)
--// inserting into a table the results from an exec query (stored procedure, batches, and dynamic sql batches)
--first create a procedure
DROP PROC IF EXISTS Sales.GetOrders;
GO

CREATE PROC Sales.GetOrders
	@country AS NVARCHAR(40)
AS

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE shipcountry = @country;
GO

--test procedure
EXEC Sales.GetOrders @country = N'France';


--2.)
--// insert into dbo.Orders the results of exec statement 
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	EXEC Sales.GetOrders @country = N'France';

	

-- SELECT INTO statement --

--1.)
--// nonstandard statement that creates a table and populates it with results from query
--cannot be used to insert data into an already existing table
--also does not copy keys, constraints, properties, etc... just data
DROP TABLE IF EXISTS dbo.Orders;

SELECT orderid, orderdate, empid, custid
INTO dbo.Orders
FROM Sales.Orders;

--2.)
--// Can use with other operations as well. INTO must be put before the first from clause
DROP TABLE IF EXISTS dbo.Locations;

SELECT country, region, city
INTO dbo.Locations
FROM Sales.Customers

EXCEPT

SELECT country, region, city
FROM HR.Employees;	

	
	
-- BULK INSERT --

--1.)
--// can insert data from a txt file into a database as long as path specified is correct
-- to get the txt file. Go to website and download from source code
BULK INSERT dbo.Orders FROM 'c:\temp\orders.txt'
   WITH
      (
		DATAFILETYPE       = 'char',
		FIELDTERMINATOR    = ',',
		ROWTERMINATOR      = '\n'
	  );



-- IDENTITY PROPERTY --
	  
--1.)
--// create table with identity set (1,1) = (first value, increment)
DROP TABLE IF EXISTS dbo.T1;

CREATE TABLE dbo.T1
(
 keycol INT NOT NULL IDENTITY(1,1)
	CONSTRAINT PK_T1 PRIMARY KEY,
 datacol VARCHAR(10) NOT NULL
	CONSTRAINT CHK_T1_datacol CHECK(datacol LIKE '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]%')
);


--2.)
--// Insert some data into the table. Only specify datacol as identity will auto fill the keycol
INSERT INTO dbo.T1(datacol) VALUES('AAAAA'), ('BBBBB'), ('CCCCC');


--3.)
--// query to see the effects of our creation
SELECT * FROM dbo.T1;


--4.)
--// can call on the identity like a variable
SELECT $identity FROM dbo.T1;


--5.)
--// used to get new identiy value, save into variable, and query the variable

-- Create a variable
DECLARE @new_key AS INT;

-- Inserts a row into table obtains the newly generated key
INSERT INTO dbo.T1(datacol) VALUES('AAAAA');

-- Obtains the newly generated key and place it into a variable
SET @new_key = SCOPE_IDENTITY();

-- Queries the variable
SELECT @new_key AS new_key;


--6.)
--NOTE: IDENTITY AND SCOPE_IDENTITY return the last identity value produced during CURRENT session only
--They will be null if it wasn't created during current session.
--If want to use the last identity value that is highest you must call IDENT_CURRENT function and 
--give table name as input


--ex1.)
--// Ran during current session gives these results
SELECT 
	SCOPE_IDENTITY() AS [SCOPE_IDENTITY],
	@@identity AS [@@identity],
	IDENT_CURRENT(N'dbo.T1') AS [IDENT_CURRENT];
	
--RESULTS:
--_________________________________________
--|SCOPE_IDENTITY|@@identity|IDENT_CURRENT|
--|4_____________| 4________|4____________|	


--ex2.)
--// Ran during new session gives these results
SELECT 
	SCOPE_IDENTITY() AS [SCOPE_IDENTITY],
	@@identity AS [@@identity],
	IDENT_CURRENT(N'dbo.T1') AS [IDENT_CURRENT];
	
--RESULTS:
--_________________________________________
--|SCOPE_IDENTITY|@@identity|IDENT_CURRENT|
--|0_____________| 0________|4____________|	


--7.)
--// It needs to be noted that if an insert fails the identity value will go up. It does not rollback when insert failure does

--This insert will fail because the constraint on datacol says only letters
INSERT INTO dbo.T1(datacol) VALUES('12345');

--Insert another row into the table
INSERT INTO dbo.T1(datacol) VALUES('EEEEE');

--Now query the table and you will see a gap now exists where 5 should be
Select * FROM dbo.T1;


--8.)
--// We can add in our own key value as well. 
--NOTE: the IDENTITY rule does not enforce uniqueness as we can also add our own values. 
--You need to also add a primary key/unique constraint on the actual column to do so

--Turn on the option to manually insert values
SET IDENTITY_INSERT dbo.T1 ON;

--Insert values
INSERT INTO dbo.T1(keycol, datacol) VALUES(5, 'DDDDD');

--Turn off the option to manually insert values
SET IDENTITY_INSERT dbo.T1 OFF;


--9.)
--// This does not reset key value back down to 5. it will remain whatever the higfhest value in table is
INSERT INTO dbo.T1(datacol) VALUES('FFFFF');

--Check results
SELECT * FROM dbo.T1;



-- SEQUENCE PROPERTY  -- 


--NOTE: SEQUENCE HAS MANY MORE OTPIONS TIED TO IT THAT CAN BE CHANGED OR LEFT ALONE
--CREATE SEQUENCE  is accepted and reverts everything to default //not suggested

--1.)
--// A simple sequence
CREATE SEQUENCE dbo.SeqOrderIDs AS INT
	MINVALUE 1
	CYCLE;
	
--You can change any property using ALTER SEQUENCE except the data type
--2.)
--// simple alteration to sequence
ALTER SEQUENCE dbo.SeqOrderIDs
	NO CYCLE;

	
--3.)
--// Invoking the function to get the next sequence value
SELECT NEXT VALUE FOR dbo.SeqOrderIDs;

-- You don't need to insert a row into a table in order to generate a new value like IDENTITY
-- SEQUENCE allows you to store the results of the function into a variable to use later in the code


--4.)
--// Create a table to demonstrate
DROP TABLE IF EXISTS dbo.T1;

CREATE TABLE dbo.T1
(
 keycol INT NOT NULL
	CONSTRAINT PK_T1 PRIMARY KEY,
 datacol VARCHAR(10) NOT NULL
);


--5.)
--// using a variable with a stored key value we will insert a new row into the table
DECLARE @neworderid AS INT = NEXT VALUE FOR dbo.SeqOrderIDs;
INSERT INTO dbo.T1(keycol, datacol) VALUES(@neworderid, 'a');

SELECT * FROM dbo.t1;
 
 
--6.)
--// If you don't need to generate the next value before using it you can directly call in in the INSERT STATEMENT
INSERT INTO dbo.T1(keycol, datacol)
	VALUES(NEXT VALUE FOR dbo.SeqOrderIDs, 'b');
	
SELECT * FROM dbo.T1;
 
 
--7.)
--// unlike with identity you can generate new sequence values in an update statement
UPDATE dbo.T1
	SET keycol = NEXT VALUE FOR dbo.SeqOrderIDs;
	
SELECT * FROM dbo.T1;


--8.)
--// getting information about our current sequences.
SELECT current_value
FROM sys.sequences
WHERE OBJECT_ID = OBJECT_ID(N'dbo.SeqOrderIDs');


-- SQL SERVER extends its support for sequence beyond what its competitors and the standard currently support
--9.)
--// one extension is controlling the order of the assigned sequence values in a multirow insert by 
--using an OVER clause 
INSERT INTO dbo.T1(keycol, datacol)
	SELECT
		NEXT VALUE FOR dbo.SeqOrderIDs OVER(ORDER BY hiredate),
		LEFT(firstname, 1) + LEFT(lastname, 1)
	FROM HR.Employees;

	
SELECT * FROM dbo.T1;


--10.)
--// Another extension that allows next value for in a default constraint
-- shows adding to an existing column (can't do this with identity)
ALTER TABLE dbo.T1
  ADD CONSTRAINT DFT_T1_keycol
    DEFAULT (NEXT VALUE FOR dbo.SeqOrderIDs)
	FOR keycol;

--11.)
--// now when we add a row we no longer have to specify a value for keycol
INSERT INTO dbo.T1(datacol) VALUES('c');

SELECT * FROM dbo.T1;


--12.)
--//can use an extension to allocate a whole range of sequence values at once by using
-- a stored procedure called sp_sequence_get_range
DECLARE @first AS SQL_VARIANT;

EXEC sys.sp_sequence_get_range
	@sequence_name     = N'dbo.SeqOrderIDs',
	@range_size        = 1000000,
	@range_first_value = @first OUTPUT;

SELECT @first;

--The same issue with identity in which the sequence change is not undone when a rollback or fail occurs 
--is still present with sequence gaps can also occur when a power failure occurs before a cache happens



-- DELETING DATA  -- 

--1.)
--// Create two dbo tables based on Sales tables to test deleting data on
DROP TABLE IF EXISTS dbo.Orders, dbo.Customers;

CREATE TABLE dbo.Customers
(
  custid       INT          NOT NULL,
  companyname  NVARCHAR(40) NOT NULL,
  contactname  NVARCHAR(30) NOT NULL,
  contacttitle NVARCHAR(30) NOT NULL,
  address      NVARCHAR(60) NOT NULL,
  city         NVARCHAR(15) NOT NULL,
  region       NVARCHAR(15) NULL,
  postalcode   NVARCHAR(10) NULL,
  country      NVARCHAR(15) NOT NULL,
  phone        NVARCHAR(24) NOT NULL,
  fax          NVARCHAR(24) NULL,
	CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATE         NOT NULL,
  requireddate   DATE         NOT NULL,
  shippeddate    DATE         NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid),
	CONSTRAINT FK_Orders_Customers FOREIGN KEY(custid)
    REFERENCES dbo.Customers(custid)
);
GO

INSERT INTO dbo.Customers SELECT * FROM Sales.Customers;
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;



-- DELETE STATEMENT --

--1.)
--// Using a simple delete statement [fully logged]
DELETE FROM dbo.Orders
WHERE orderdate < '20150101';


--2.)
--// simple truncate statement  (no filter for truncate) [minimally logged]
TRUNCATE TABLE dbo.T1;


--3.)
--// truncating a table that has been sepereated into partitions
TRUNCATE TABLE dbo.T1 WITH (PARTITIONS(1, 3, 5, 7 TO 10) );


--4.)
--// nonstandard delete based on a join
--allows extra filtering: delete orders placed by customers from the United States
DELETE FROM O
FROM dbo.Orders AS O
	INNER JOIN dbo.Customers AS C
		ON O.custid = C.custid
WHERE C.country = N'USA';


--5.)
--// standard delete based on using subqueries 
DELETE FROM dbo.Orders
WHERE EXISTS
	(SELECT * 
	 FROM dbo.Customers AS C
	 WHERE Orders.custid = C.custid
		AND C.country = N'USA');
		
		

-- UPDATING DATA --	

--1.)
--// create tables to work on
DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATE         NOT NULL,
  requireddate   DATE         NOT NULL,
  shippeddate    DATE         NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

CREATE TABLE dbo.OrderDetails
(
  orderid   INT           NOT NULL,
  productid INT           NOT NULL,
  unitprice MONEY         NOT NULL
    CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
  qty       SMALLINT      NOT NULL
    CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
  discount  NUMERIC(4, 3) NOT NULL
    CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
	CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
	CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY(orderid)
    REFERENCES dbo.Orders(orderid),
	CONSTRAINT CHK_discount  CHECK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty  CHECK (qty > 0),
	CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;



-- UPDATE STATEMENT --

--1.)
--// simple update statement
UPDATE dbo.OrderDetails	
	SET discount = discount + 0.05
WHERE productid = 51;

--same but at once operator 
--(book instills at once concept. all code happens at the same time, not left to right)
UPDATE dbo.OrderDetails	
	SET discount += 0.05
WHERE productid = 51;

--view results
SELECT productid, discount 
FROM dbo.OrderDetails	
WHERE productid = 51;


--2.)
--//non standard update based on a join
UPDATE OD
	SET discount += 0.05
FROM dbo.OrderDetails AS OD
	INNER JOIN dbo.Orders AS 0
		ON OD.orderid = 0.orderid
WHERE O.custid = 1;


--3.)
--// standard update using subqueries
UPDATE dbo.OrderDetails
	SET discount += 0.05
WHERE EXISTS
	(SELECT * FROM dbo.Orders AS O
	 WHERE O.orderid = OrderDetails.orderid
		AND O.custid = 1);

		
--4.)
--//non standard update based on a join
--Has the advantage through single join over using multiple subqueries
UPDATE T1
	SET col1 = T2.col1,
		col2 = T2.col2,
		col3 = T2.col3
FROM dbo.T1 JOIN dbo.T2
	ON T2.keycol = T1.keycol
WHERE T2.col4 = 'ABC';


--using the subqueries that are lengthy and slower
UPDATE T1
	SET col1 = (SELECT col1
				FROM dbo.T2
				WHERE T2.keycol = T1.keycol),
		col2 = (SELECT col2
				FROM dbo.T2
				WHERE T2.keycol = T1.keycol),
		col3 = (SELECT col3
				FROM dbo.T2
				WHERE T2.keycol = T1.keycol)
WHERE EXISTS
	(SELECT * 
	 FROM dbo.T1 JOIN dbo.T2
	 WHERE T2.keycol = T1.keycol
	 AND T2.col4 = 'ABC');

--NOTE: T-SQL has partial support(as of sql 2016) for row constructors aka.(vector expressions) 
--but this version would still be more complicated than the join version 		
		
	
	
--	ASSIGNMENT UPDATE --

--NOTE: This syntax saves on need to use seperate UPDATE and SELECT statements to achieve the same task
--A common case is maintaining a custom sequence/autonumbering mechanism when the identity column property
--and sequence object won't work. Like, when you need to gaurantee no gaps

--1.)
--//first we create a table to use to hold our values. We will use it to both increment the value in the table 
--and assign it to a variable 
DROP TABLE IF EXISTS dbo.MySequences;

CREATE TABLE dbo.MySequences
(
 id VARCHAR(10) NOT NULL
	CONSTRAINT PK_MySequences PRIMARY KEY(ID),
val INT NOT NULL
);

INSERT INTO dbo.MySequences VALUES('SEQ1', 0);

--2.)
--// whenever we need a new sequence value we use the following code
DECLARE @nextval AS INT;

UPDATE dbo.MySequences
	SET @nextval = val += 1
WHERE id = 'SEQ1';

SELECT @nextval;

--ran as transaction, but is not transactional



-- MERGING DATA --

--1.)
--// first we create tables to work with
DROP TABLE IF EXISTS dbo.Customers, dbo.CustomersStage;
GO

CREATE TABLE dbo.Customers
(
  custid      INT         NOT NULL,
  companyname VARCHAR(25) NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  address     VARCHAR(50) NOT NULL,
  CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

INSERT INTO dbo.Customers(custid, companyname, phone, address)
VALUES
  (1, 'cust 1', '(111) 111-1111', 'address 1'),
  (2, 'cust 2', '(222) 222-2222', 'address 2'),
  (3, 'cust 3', '(333) 333-3333', 'address 3'),
  (4, 'cust 4', '(444) 444-4444', 'address 4'),
  (5, 'cust 5', '(555) 555-5555', 'address 5');

CREATE TABLE dbo.CustomersStage
(
  custid      INT         NOT NULL,
  companyname VARCHAR(25) NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  address     VARCHAR(50) NOT NULL,
  CONSTRAINT PK_CustomersStage PRIMARY KEY(custid)
);

INSERT INTO dbo.CustomersStage(custid, companyname, phone, address)
VALUES
  (2, 'AAAAA', '(222) 222-2222', 'address 2'),
  (3, 'cust 3', '(333) 333-3333', 'address 3'),
  (5, 'BBBBB', 'CCCCC', 'DDDDD'),
  (6, 'cust 6 (new)', '(666) 666-6666', 'address 6'),
  (7, 'cust 7 (new)', '(777) 777-7777', 'address 7');

--view results
SELECT * FROM dbo.customers;
SELECT * FROM dbo.CustomersStage;


--2.)
--// merging the two tables to ensure the customers table has all customers in it
-- Uses 'when matched' clause and 'when not matched' clause
MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT(custid, companyname, phone, address)
	VALUES(SRC.custid, SRC.companyname, SRC.phone, SRC.address);
-- ; is required for merges (best practice to end all statements anyway

--view results
SELECT * FROM dbo.Customers;


--3.)
--// adding the third clause for when row doesn't match source
MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT(custid, companyname, phone, address)
	VALUES(SRC.custid, SRC.companyname, SRC.phone, SRC.address)
WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

--view results
SELECT * FROM dbo.Customers;


--4.)
--// add checks to not change target if source and it are the same. 
MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED AND
	(
	 TGT.companyname <> SRC.companyname
	 OR
	 TGT.phone       <> SRC.phone
	 OR
	 TGT.address     <> SRC.address
	) THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT(custid, companyname, phone, address)
	VALUES(SRC.custid, SRC.companyname, SRC.phone, SRC.address);


	
-- MODIFYING THROUGH TABLE EXPRESSIONS --

--This is very good for debugging and troubleshooting

--1.)
--// if you want to see the results of an update bfore actually running it you can do this through a table expressions

--ex1.
--As a CTE
WITH C AS
(
	SELECT custid, OD.orderid, productid, discount, discount + 0.05 AS newdiscount
	FROM dbo.OrderDetails AS OD	
		INNER JOIN dbo.Orders AS O
			ON OD.orderid = O.orderid
	WHERE O.custid = 1
)
UPDATE C
	SET discount = newdiscount;

--ex2. 
--As a derived table
UPDATE D
	SET discount = newdiscount
FROM(
	 SELECT custid, OD.orderid, productid, discount, discount + 0.05 AS newdiscount
	 FROM dbo.OrderDetails AS OD	
		INNER JOIN dbo.Orders AS O
			ON OD.orderid = O.orderid
	 WHERE O.custid = 1
)
AS D;


--2.)
--// usually modifying through table expression is for convienience, but in some cases it is the only way

--ex1.
--create a table to work with
DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(id INT NOT NULL IDENTITY PRIMARY KEY, col1 INT, col2 INT);
GO

INSERT INTO dbo.T1(col1) VALUES(20),(10),(30);

--view result
SELECT * FROM dbo.T1;


--ex2.
--if we try to just update the data dirrectly we get an error
UPDATE dbo.T1
  SET col2 = ROW_NUMBER() OVER(ORDER BY col1);

--ex3.
--to bypass this we edit through the table expression using CTE
WITH C AS 
(
SELECT col1, col2, ROW_NUMBER() OVER(ORDER BY col1) AS rownum
FROM dbo.T1
)
UPDATE C
	SET col2 = rownum;
	
--view result
SELECT * FROM dbo.T1;



-- MODIFYING WITH TOP AND OFFSET-FETCH --

--1.)
--// create a table to work with
DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATE         NOT NULL,
  requireddate   DATE         NOT NULL,
  shippeddate    DATE         NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

--insert data into table
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;


--2.)
--// delete the top 50 rows from dbo.Orders (there is no order here. just first 50 server finds)
DELETE TOP(50) FROM dbo.Orders;


--3.)
--// update the top 50 rows (there is no order here. just first 50 server finds)
UPDATE TOP(50) dbo.Orders
	SET freight += 10.00;

	
--4.)
--// to add order and only change the rows we want we have to use a CTE 
--deletes the top 50 with lowest orderids

--ex.1 DELETE
WITH C AS 
(
 SELECT TOP(50) *
 FROM dbo.Orders
 ORDER BY orderid
)
DELETE FROM C;

--ex2. UPDATE
WITH C AS 
(
 SELECT TOP(50) *
 FROM dbo.Orders
 ORDER BY orderid DESC
)
UPDATE C
	SET freight += 10.00;


--5.)
--// The process above can also be accomplished using the OFFSET-FETCH method instead of TOP 
		
--ex.1 DELETE
WITH C AS 
(
 SELECT *
 FROM dbo.Orders
 ORDER BY orderid
 OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
)
DELETE FROM C


--ex2. UPDATE
WITH C AS 
(
 SELECT *
 FROM dbo.Orders
 ORDER BY orderid
 OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
)
UPDATE C
	SET freight += 10.00;	


	
-- THE OUTPUT CLAUSE --

--Used to show results after completing statements like UPDATE, DELETE, and INSERT
--1.)
--// INSERT with OUTPUT

--ex1.
--create table to work with
DROP TABLE IF EXISTS dbo.T1;

CREATE TABLE dbo.T1
(
  keycol  INT          NOT NULL IDENTITY(1, 1) CONSTRAINT PK_T1 PRIMARY KEY,
  datacol NVARCHAR(40) NOT NULL
);

--ex2.
-- use insert with output clause
INSERT INTO dbo.T1(datacol)
	OUTPUT inserted.keycol, inserted.datacol
		SELECT lastname
		FROM HR.Employees
		WHERE country = N'USA';


--2.)
--// directing the results of INSERT with OUTPUT into a table

--create new variable table
DECLARE @NewRows TABLE(keycol INT, datacol NVARCHAR(40));

--call the insert and output statement
INSERT INTO dbo.T1(datacol)
	OUTPUT inserted.keycol, inserted.datacol
	INTO @NewRows(keycol, datacol)
		SELECT lastname
		FROM HR.Employees
		WHERE country = N'UK';

--view the results
SELECT * FROM @NewRows;


--3.)
--// DELETE with OUTPUT

--ex1.
--create a table first
DROP TABLE IF EXISTS dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATE         NOT NULL,
  requireddate   DATE         NOT NULL,
  shippeddate    DATE         NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;


--ex2.
-- call DELETE with OUTPUT
DELETE FROM dbo.Orders
	OUTPUT
		deleted.orderid,
		deleted.orderdate,
		deleted.empid,
		deleted.custid
	WHERE orderdate < '20160101';
--can also add into to direct results into a table 


--4.)
--// UPDATE with OUTPUT
--can refer to both the deleted row and the new row created with this clause

--ex1.
-- create a table to work on
DROP TABLE IF EXISTS dbo.OrderDetails;

CREATE TABLE dbo.OrderDetails
(
  orderid   INT           NOT NULL,
  productid INT           NOT NULL,
  unitprice MONEY         NOT NULL
    CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
  qty       SMALLINT      NOT NULL
    CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
  discount  NUMERIC(4, 3) NOT NULL
    CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
	CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
	CONSTRAINT CHK_discount  CHECK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty  CHECK (qty > 0),
	CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);

INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

--ex2.
--call the UPDATE with OUTPUT
UPDATE dbo.OrderDetails	
	SET discount += 0.05
OUTPUT
	inserted.orderid,
	inserted.productid,
	deleted.discount AS olddiscount,
	inserted.discount AS newdiscount
WHERE productid = 51;


--5.)
--// MERGE with OUTPUT
--merge can be doing multiple DML actions so you need to call $action in the output to see which 
--effect is caused by which DML

--ex1.
-- recreate table to use again 
DROP TABLE IF EXISTS dbo.Customers, dbo.CustomersStage;
GO

CREATE TABLE dbo.Customers
(
  custid      INT         NOT NULL,
  companyname VARCHAR(25) NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  address     VARCHAR(50) NOT NULL,
	CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

INSERT INTO dbo.Customers(custid, companyname, phone, address)
VALUES
  (1, 'cust 1', '(111) 111-1111', 'address 1'),
  (2, 'cust 2', '(222) 222-2222', 'address 2'),
  (3, 'cust 3', '(333) 333-3333', 'address 3'),
  (4, 'cust 4', '(444) 444-4444', 'address 4'),
  (5, 'cust 5', '(555) 555-5555', 'address 5');

CREATE TABLE dbo.CustomersStage
(
  custid      INT         NOT NULL,
  companyname VARCHAR(25) NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  address     VARCHAR(50) NOT NULL,
	CONSTRAINT PK_CustomersStage PRIMARY KEY(custid)
);

INSERT INTO dbo.CustomersStage(custid, companyname, phone, address)
VALUES
  (2, 'AAAAA', '(222) 222-2222', 'address 2'),
  (3, 'cust 3', '(333) 333-3333', 'address 3'),
  (5, 'BBBBB', 'CCCCC', 'DDDDD'),
  (6, 'cust 6 (new)', '(666) 666-6666', 'address 6'),
  (7, 'cust 7 (new)', '(777) 777-7777', 'address 7');

  
--ex2.
--calling the MERGE with OUTPUT		
MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT(custid, companyname, phone, address)
	VALUES(SRC.custid, SRC.companyname, SRC.phone, SRC.address)
OUTPUT $action AS theaction, 
	   inserted.custid,
	   deleted.companyname AS oldcompanyname,
	   inserted.companyname AS newcompanyname,
	   deleted.phone AS oldphone,
	   inserted.phone AS newphone,
	   deleted.address AS oldaddress,
	   inserted.address AS newaddress; 


--6.)
--// nested DML
--used to direct a subset of modified rows to a new table

--ex1.
-- create table to work on
DROP TABLE IF EXISTS dbo.ProductsAudit, dbo.Products;

CREATE TABLE dbo.Products
(
  productid    INT          NOT NULL,
  productname  NVARCHAR(40) NOT NULL,
  supplierid   INT          NOT NULL,
  categoryid   INT          NOT NULL,
  unitprice    MONEY        NOT NULL
    CONSTRAINT DFT_Products_unitprice DEFAULT(0),
  discontinued BIT          NOT NULL 
    CONSTRAINT DFT_Products_discontinued DEFAULT(0),
	CONSTRAINT PK_Products PRIMARY KEY(productid),
	CONSTRAINT CHK_Products_unitprice CHECK(unitprice >= 0)
);

INSERT INTO dbo.Products SELECT * FROM Production.Products;

CREATE TABLE dbo.ProductsAudit
(
  LSN INT NOT NULL IDENTITY PRIMARY KEY,
  TS DATETIME2 NOT NULL DEFAULT(SYSDATETIME()),
  productid INT NOT NULL,
  colname SYSNAME NOT NULL,
  oldval SQL_VARIANT NOT NULL,
  newval SQL_VARIANT NOT NULL
);

--ex2.
-- call the nested DML
INSERT INTO dbo.ProductsAudit(productid, colname, oldval, newval)
	SELECT productid, N'unitprice', oldval, newval
	FROM (UPDATE dbo.Products
			SET unitprice *= 1.15
		 OUTPUT
			inserted.productid,
			deleted.unitprice AS oldval,
			inserted.unitprice AS newval
		WHERE supplierid = 1) AS D
WHERE oldval < 20.0 AND newval >= 20.0;

--view results
SELECT * FROM dbo.ProductsAudit;



-------------
--Exercises--
-------------

--Exercise 1:

--// Create a table to work on
USE TSQLV4;

DROP TABLE IF EXISTS dbo.Customers;

CREATE TABLE dbo.Customers
(
  custid      INT          NOT NULL PRIMARY KEY,
  companyname NVARCHAR(40) NOT NULL,
  country     NVARCHAR(15) NOT NULL,
  region      NVARCHAR(15) NULL,
  city        NVARCHAR(15) NOT NULL  
);


--Exercise 1-1:
-- MINE (close, but forgot to make NVARCHARS)- 
INSERT INTO dbo.Customers(custid, companyname, country, region, city)
		VALUES(100, 'Coho Winery', 'USA', 'WA', 'Redmond');
	

-- CORRECT -
INSERT INTO dbo.Customers(custid, companyname, country, region, city)
		VALUES(100, N'Coho Winery', N'USA', N'WA', N'Redmond');


--Exercise 1-2:
-- MINE (correct)- 
INSERT INTO dbo.Customers(custid, companyname, country, region, city)
	SELECT custid, companyname, country, region, city
	FROM Sales.Customers AS C
	WHERE EXISTS
		(SELECT * FROM Sales.Orders AS O
		WHERE O.custid = C.custid);


--Exercise 1-3:
-- MINE (correct)- 
DROP TABLE IF EXISTS dbo.Orders;

SELECT * INTO dbo.Orders
FROM Sales.Orders
WHERE orderdate >= '20140101'
	AND orderdate < '20170101';


--Exercise 2:
-- MINE (correct)- 
DELETE FROM dbo.Orders
OUTPUT deleted.orderid, deleted.orderdate
WHERE orderdate < '20140801';


--Exercise 3:
-- MINE (correct, ex.2)- 
DELETE FROM O
FROM dbo.Orders AS O
  INNER JOIN dbo.Customers AS C
    ON O.custid = C.custid
WHERE country = N'Brazil';

-- CORRECT --
--ex1.
DELETE FROM dbo.Orders
WHERE EXISTS
  (SELECT *
   FROM dbo.Customers AS C
   WHERE dbo.Orders.custid = C.custid
     AND C.country = N'Brazil');

--ex2.
DELETE FROM O
FROM dbo.Orders AS O
  INNER JOIN dbo.Customers AS C
    ON O.custid = C.custid
WHERE country = N'Brazil';

--ex3.
MERGE INTO dbo.Orders AS O
USING (SELECT * FROM dbo.Customers WHERE country = N'Brazil') AS C
  ON O.custid = C.custid
WHEN MATCHED THEN DELETE;


--Exercise 4:
-- MINE (CORRECT)- 
UPDATE dbo.Customers
	SET region = '<NONE>'
OUTPUT
	deleted.custid,
	deleted.region AS oldregion,
	inserted.region AS newregion
WHERE region IS NULL;


--Exercise 5:
-- MINE (correct with added output for viewing. like ex3)- 
MERGE INTO dbo.Orders AS O
USING (SELECT * FROM dbo.Customers WHERE country = N'UK') AS C
	ON O.custid = C.custid
WHEN MATCHED THEN
	UPDATE SET 
	shipcountry = C.country,
	shipregion = C.region,
	shipcity = C.city
OUTPUT $action AS theaction, 
	   deleted.shipcountry AS shipcountry,
	   inserted.shipcountry AS shipcountry,
	   deleted.shipregion AS shipregion,
	   inserted.shipregion AS shipregion,
	   deleted.shipcity AS shipcity,
	   inserted.shipcity AS shipcity;


-- CORRECT-
--ex1.
UPDATE O
  SET shipcountry = C.country,
      shipregion = C.region,
      shipcity = C.city
FROM dbo.Orders AS O
  INNER JOIN dbo.Customers AS C
    ON O.custid = C.custid
WHERE C.country = N'UK';

--ex2.
WITH CTE_UPD AS
(
  SELECT
    O.shipcountry AS ocountry, C.country AS ccountry,
    O.shipregion  AS oregion,  C.region  AS cregion,
    O.shipcity    AS ocity,    C.city    AS ccity
  FROM dbo.Orders AS O
    INNER JOIN dbo.Customers AS C
      ON O.custid = C.custid
  WHERE C.country = N'UK'
)
UPDATE CTE_UPD
  SET ocountry = ccountry, oregion = cregion, ocity = ccity;

--ex3.
MERGE INTO dbo.Orders AS O
USING (SELECT * FROM dbo.Customers WHERE country = N'UK') AS C
  ON O.custid = C.custid
WHEN MATCHED THEN
  UPDATE SET shipcountry = C.country,
             shipregion = C.region,
             shipcity = C.city;


--Exercise 6:

--create tables to work on
USE TSQLV4;

DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATE         NOT NULL,
  requireddate   DATE         NOT NULL,
  shippeddate    DATE         NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

CREATE TABLE dbo.OrderDetails
(
  orderid   INT           NOT NULL,
  productid INT           NOT NULL,
  unitprice MONEY         NOT NULL
    CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
  qty       SMALLINT      NOT NULL
    CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
  discount  NUMERIC(4, 3) NOT NULL
    CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
	CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
	CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY(orderid)
    REFERENCES dbo.Orders(orderid),
	CONSTRAINT CHK_discount  CHECK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty  CHECK (qty > 0),
	CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;


-- MINE (had to work through with book, but correct)- 
ALTER TABLE dbo.OrderDetails DROP CONSTRAINT FK_OrderDetails_Orders;

TRUNCATE TABLE dbo.OrderDetails;
TRUNCATE TABLE dbo.Orders;

ALTER TABLE dbo.OrderDetails ADD CONSTRAINT FK_OrderDetails_Orders
  FOREIGN KEY(orderid) REFERENCES dbo.Orders(orderid);	



	
	
	
	
	
	
	
	
