----------------------
-- Chapter 6 (Set Operators:)--
----------------------

----------------
--Chapter Work--
----------------

--1.)
--// Union all example (combines tables and shows all lines from each into one table)
USE TSQLV4;

SELECT country, region, city 
FROM HR.Employees
   UNION ALL
SELECT country, region, city 
FROM Sales.Customers;



--2.)
--// Union distinct example (Just leave off the ALL keyword and distinct is assumed) (combines tables and only shows one of each item)
USE TSQLV4;

SELECT country, region, city 
FROM HR.Employees
   UNION
SELECT country, region, city 
FROM Sales.Customers;


--3.)
--// Intersect example (shows only those that both tables have one of)
USE TSQLV4;

SELECT country, region, city 
FROM HR.Employees
   INTERSECT
SELECT country, region, city 
FROM Sales.Customers;


--4.)
--// Intersect all example (T-SQL does not have this built in like SQL so we must make our own here)
USE TSQLV4;

SELECT 
   ROW_NUMBER()
      OVER(PARTITION BY country, region, city
	       ORDER     BY (SELECT 0)) AS rownum,
   country, region, city 
FROM HR.Employees

   INTERSECT

SELECT 
   ROW_NUMBER()
      OVER(PARTITION BY country, region, city
	       ORDER     BY (SELECT 0)) AS rownum,
   country, region, city 
FROM Sales.Customers;



--5.)
--// Intersect all (standard [has no rownumbers included])
USE TSQLV4;

WITH INTERSECT_ALL
AS
(
   SELECT 
      ROW_NUMBER()
         OVER(PARTITION BY country, region, city
	          ORDER     BY (SELECT 0)) AS rownum,
      country, region, city 
   FROM HR.Employees

   INTERSECT

   SELECT 
      ROW_NUMBER()
         OVER(PARTITION BY country, region, city
	          ORDER     BY (SELECT 0)) AS rownum,
      country, region, city 
   FROM Sales.Customers
)

SELECT country, region, city
FROM INTERSECT_ALL;


--6.)
--// except example (returns lines that are in table one but not in table two) table order matters here!
SELECT country, region, city
FROM HR.Employees

EXCEPT

SELECT country, region, city 
FROM Sales.Customers;



--//reversed tables has very different result
SELECT country, region, city
FROM Sales.Customers

EXCEPT

SELECT country, region, city 
FROM HR.Employees;


--7.)
--// EXCEPT ALL (returns occurences from the first table of a multiset who do not have a corresponding occurence in the second table)
USE TSQLV4;

WITH EXCEPT_ALL
AS
(
   SELECT 
      ROW_NUMBER()
         OVER(PARTITION BY country, region, city
	          ORDER     BY (SELECT 0)) AS rownum,
      country, region, city 
   FROM HR.Employees

   EXCEPT

   SELECT 
      ROW_NUMBER()
         OVER(PARTITION BY country, region, city
	          ORDER     BY (SELECT 0)) AS rownum,
      country, region, city 
   FROM Sales.Customers
)

SELECT country, region, city
FROM EXCEPT_ALL;


--8.)
--// precedence of operations:
--   first INTERSECT
--   UNION and EXCEPT are ased on which appears first. 

--ex.1
--   UNION...
--   EXCEPT...
--   INTERCEPT...
--   evaluates to INTERCEPT, UNION, and then EXCEPT

--ex.2
--   EXCEPT...
--   INTERCEPT...
--   UNION...
--   evaluates to INTERCEPT, EXCEPT, and then UNION


--9.)
--// precedence of operations:  (using parenthesis)
--use of parenthesis to change order

--ex.1
--   (UNION)...
--   EXCEPT...
--   INTERCEPT...
--   evaluates to UNION, INTERCEPT, and then EXCEPT

--ex.2
--   EXCEPT...
--   INTERCEPT...
--   (UNION)...
--evaluates to UNION, INTERCEPT, and then EXCEPT


--------------------------------------------
--// circumventing unsuported logical phases//--
--------------------------------------------
--1.)
--// using group by example
SELECT country, COUNT(*) AS numlocations
FROM (SELECT country, region, city
      FROM HR.Employees
	  
      UNION
	  
      SELECT country, region, city
      FROM Sales.Customers
      ) AS U 
GROUP BY country;


--2.)
--// Using order by inside the query by using inner query example (order by is not allowed with joins normally)
SELECT empid, orderid, orderdate
FROM (SELECT TOP(2) empid, orderid, orderdate
      FROM Sales.Orders
	  WHERE empid = 3
	  ORDER BY orderdate DESC, orderid DESC) AS D1
	  
	  UNION ALL
	  
SELECT empid, orderid, orderdate
FROM (SELECT TOP(2) empid, orderid, orderdate
      FROM Sales.Orders
	  WHERE empid = 5
	  ORDER BY orderdate DESC, orderid DESC) AS D2
	  


-------------
--Exercises--
-------------

--Exercise 1:
--explain the difference question. answer not needed here


--Exercise 2:
-- MINE (used later in book)- 
SELECT n
FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS Nums(n);

-- CORRECT -
SELECT 1 AS n
UNION ALL select 2
UNION ALL select 3
UNION ALL select 4
UNION ALL select 5
UNION ALL select 6
UNION ALL select 7
UNION ALL select 8
UNION ALL select 9
UNION ALL select 10;


--Exercise 3:
-- MINE (not quite right. I approached by year not by month)- 
SELECT custid, empid
FROM Sales.Orders
WHERE YEAR(orderdate) = '2016'

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE YEAR(orderdate) = '2017';

-- CORRECT -
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301';


--Exercise 4:
-- MINE (CORRECT)- 
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

INTERSECT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301';


--Exercise 5:
-- MINE (CORRECT)- 
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

INTERSECT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301'

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE YEAR(orderdate) = '2015';


-- CORRECT - (BOOK SUGGESTS FOR EXTRA CLARITY TO ADD PARENTHESIS ON THE FIRST ONE YOU WANT AT ALL TIMES)
(SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

INTERSECT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301')

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE YEAR(orderdate) = '2015';


--Exercise 6:
-- MINE (knew it needed orderby but wasn't sure of sortcol would be setup)- 
SELECT country, region, city
FROM (SELECT country, region, city
      FROM HR.Employees

      UNION ALL
	  
       SELECT country, region, city
       FROM Production.Suppliers) AS D
       ORDER BY country, region, city;


-- CORRECT -
SELECT country, region, city
FROM (SELECT 1 AS sortcol, country, region, city
      FROM HR.Employees

      UNION ALL
	  
      SELECT 2, country, region, city
      FROM Production.Suppliers) AS D
      ORDER BY sortcol, country, region, city;

