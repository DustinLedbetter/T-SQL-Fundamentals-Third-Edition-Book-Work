----------------------
-- Chapter 5 (Table Expressions:)--
----------------------

----------------
--Chapter Work--
----------------

--Derived tables already know --

--CTE Common Table Expressions--
--   Definition:

--   WITH <CTE_NAME>[(<target_column_list>)]
--   AS
--   (
--   <inner_query_defining_CTE>
--   )
--   <outer_query_against_CTE>;



--1.)
--// Simple CTE example
WITH USACusts AS
(
	SELECT custid, companyname
	FROM Sales.Customers
	WHERE country = N'USA'
)
SELECT * FROM USACusts;


--2.)
--// Inline alias
WITH C AS
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;


--3.)
--// External alias
WITH C(orderyear, custid) AS
(
	SELECT YEAR(orderdate), custid
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;


--4.)
--// Using multiple CTE's (better way than to use nesting)
DECLARE @empid AS INT = 3;

WITH C1 AS
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
),
C2 AS
(
	SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
	FROM C1
	GROUP BY orderyear
)
SELECT orderyear, numcusts
FROM C2
WHERE numcusts > 70; 


--5.)
--// Query used to demonstrate refering to multiple instances of the same CTE
WITH YearlyCount AS
(
	SELECT YEAR(orderdate) AS orderyear, COUNT(DISTINCT custid) AS numcusts
	FROM Sales.Orders
	GROUP BY YEAR(orderdate)
)
SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM YearlyCount AS Cur
	LEFT OUTER JOIN YearlyCount AS Prv
	   ON Cur.orderyear = Prv.orderyear + 1;


--6.)
--// Query to show how recursion works. (retrieves employees under mgr 2, then emps under those two 3 and 5, then none since that's then lowest level)
WITH EmpsCTE AS
(
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 2

	UNION ALL 

	SELECT C.empid, C.mgrid, C.firstname, C.lastname
	FROM EmpsCTE AS P
		INNER JOIN HR.Employees AS C
			ON C.mgrid = P.empid
)
SELECT empid, mgrid, firstname, lastname
FROM EmpsCTE;


--7.)
--// Create a view in the database. acts like a table, but is based on another query
DROP VIEW IF EXISTS Sales.USAcusts;
GO
CREATE VIEW Sales.USACusts
AS

SELECT 
	custid, companyname, contactname, contacttitle, address, 
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO 


--8.)
--// use to show a query on view
SELECT 
	custid, companyname, region
FROM Sales.USACusts
ORDER BY region;



--9.)
--// This is how to add encryption to a view... did not do this to mine as It is not easy to undo 
--//    apart from drop and recreate
ALTER VIEW Sales.USACusts WITH ENCRYPTION
AS

SELECT 
	custid, companyname, contactname, contacttitle, address, 
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO 


--10.)
--// Used to create a inline table valued function (does a query based on a given parameter 
--//    not quite a view because not static)
USE TSQLV4;
DROP FUNCTION IF EXISTS dbo.GetCustOrders;
GO
CREATE FUNCTION dbo.GetCustOrders
	(@cid AS INT) RETURNS TABLE
AS
RETURN
	SELECT orderid, custid, empid, orderdate, requireddate,
	  shippeddate, shipperid, freight,shipname, shipaddress, shipcity,
	  shipregion, shippostalcode, shipcountry
	FROM Sales.Orders
	WHERE custid = @cid;
GO


--11.)
--// Using function to get results
SELECT orderid, custid
FROM dbo.GetCustOrders(1) AS O;


--12.)
--// use the function within a join
SELECT O.orderid, O.custid, OD.productid, OD.qty
FROM dbo.GetCustOrders(1) AS O
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;

--13.) Use of cross-apply
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.customers AS C
   CROSS APPLY 
      (SELECT orderid, empid, orderdate, requireddate
	   FROM Sales.Orders AS O
	   WHERE O.custid = C.custid
	   ORDER BY orderdate DESC, orderid DESC
	   OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY) as a;


-------------
--Exercises--
-------------

--Exercise 1:
--Written description answer --nothing needed here


--Exercise 2-1:
-- MINE (correct)- 
SELECT empid, MAX(orderdate) AS maxorderdate
FROM Sales.Orders
GROUP BY empid;


--Exercise 2-2:
-- MINE ()- 
SELECT O.empid, O.orderdate, O.orderid, O.custid
FROM Sales.Orders AS O
   INNER JOIN (SELECT empid, MAX(orderdate) AS maxorderdate
               FROM Sales.Orders
	       GROUP BY empid) AS S
ON O.empid = S.empid;


-- CORRECT -
SELECT O.empid, O.orderdate, O.orderid, O.custid
FROM Sales.Orders AS O
	INNER JOIN (SELECT empid, MAX(orderdate) AS maxorderdate
		    FROM Sales.Orders
		    GROUP BY empid) AS S
ON O.empid = S.empid
AND O.orderdate = S.maxorderdate;


--Exercise 3-1:
-- MINE (correct)- 
SELECT orderid, orderdate, custid, empid,
   ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders;


--Exercise 3-2:
-- MINE (correct)- 
WITH OrdersRN AS (
SELECT orderid, orderdate, custid, empid,
   ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders
)
SELECT * FROM OrdersRN WHERE rownum BETWEEN 11 AND 20;


-- CORRECT -
--just followed book


--Exercise 4:
--- MINE (correct, used mine example from the chapter)- 
WITH EmpsCTE AS
(
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 9

	UNION ALL 

	SELECT C.empid, C.mgrid, C.firstname, C.lastname
	FROM EmpsCTE AS P
		INNER JOIN HR.Employees AS C
			ON C.mgrid = P.empid
)
SELECT empid, mgrid, firstname, lastname
FROM EmpsCTE;


--Exercise 5-1:
-- MINE (wrong, the inner join was made wrong but had some parts on the right path before got stuck)- 
USE TSQLV4;
DROP VIEW IF EXISTS Sales.VEmpOrders;
GO
CREATE VIEW Sales.VEmpOrders
AS

SELECT empid, DATEPART( YEAR , orderdate ) AS orderyear, qty
FROM Sales.Orders 
   INNER JOIN 
      (SELECT qty 
	  FROM Sales.OrderDetails AS OD
	  WHERE empid = OD.emp;)
GO


-- Display using view
SELECT * FROM Sales.VEmporders ORDER BY empid, orderyear;


-- CORRECT -
USE TSQLV4;
DROP VIEW IF EXISTS Sales.VEmpOrders;
GO
CREATE VIEW Sales.VEmpOrders
AS

SELECT empid, YEAR(orderdate) AS orderyear, SUM(qty) AS qty
FROM Sales.Orders AS O
   INNER JOIN Sales.OrderDetails AS OD
	  ON O.orderid = OD.orderid
GROUP BY empid, YEAR(orderdate);
GO

-- Display using view
SELECT * FROM Sales.VEmporders ORDER BY empid, orderyear;


--Exercise 5-2:
-- MINE (not done. missing an extra where clause)- 
SELECT empid, orderyear, qty, 
   (SELECT SUM(qty) 
    FROM Sales.VEmpOrders AS V2
	WHERE V2.orderyear <= V1.orderyear) AS runqty
FROM Sales.VEmporders AS V1
ORDER BY empid, orderyear;



-- CORRECT -
SELECT empid, orderyear, qty, 
   (SELECT SUM(qty) 
    FROM Sales.VEmpOrders AS V2
	WHERE V2.empid = V1.empid 
	AND V2.orderyear <= V1.orderyear) AS runqty
FROM Sales.VEmporders AS V1
ORDER BY empid, orderyear;



--Exercise 6-1:
-- MINE (correct and works, but not quite the same formatting)- 
USE TSQLV4;
DROP FUNCTION IF EXISTS Production.TopProducts;
GO
CREATE FUNCTION Production.TopProducts
	(@supid AS INT, @n AS INT) RETURNS TABLE
AS
RETURN
	SELECT TOP (@n) *
	FROM Production.Products
	WHERE supplierid = @supid;
GO

-- Call Function and pass supplierid and the number of products to return
SELECT *
FROM Production.TopProducts(5,2);


-- CORRECT -
USE TSQLV4;
DROP FUNCTION IF EXISTS Production.TopProducts;
GO
CREATE FUNCTION Production.TopProducts
	(@supid AS INT, @n AS INT) RETURNS TABLE
AS
RETURN
	SELECT TOP (@n) productid, productname, unitprice
	FROM Production.Products
	WHERE supplierid = @supid
	ORDER BY unitprice DESC;
GO

-- Call Function and pass supplierid and the number of products to return
SELECT *
FROM Production.TopProducts(5,2);


--Exercise 6-2:
-- MINE (close, but not getting two most expensive only Forgot we could use the function from previous...)- 
SELECT S.supplierid, S3.companyname, S3.productid, S3.productname, S3.unitprice
FROM Production.Suppliers AS S
   CROSS APPLY 
      (SELECT companyname, productid, productname, unitprice
	   FROM Production.Products AS P
	   WHERE P.supplierid = S.supplierid
	   ORDER BY supplierid DESC, productid DESC
	   OFFSET 0 ROWS FETCH NEXT 2 ROWS ONLY) as S3;


-- CORRECT -
SELECT S.supplierid, S.companyname, P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
   CROSS APPLY 
      Production.TopProducts(S.supplierid, 2) AS P;