----------------------
-- Chapter 3 (JOINS)--
----------------------

----------------
--Chapter Work--
----------------

--Create a table of numbers to test joins on
USE TSQLV4;

DROP TABLE IF EXISTS dbo.Digits;

CREATE TABLE dbo.Digits(digit INT NOT NULL PRIMARY KEY);

INSERT INTO dbo.Digits(digit)
   VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

SELECT digit FROM dbo.Digits;


-------------
--Exercises--
-------------

--Exercise 1-1:
-- MINE (close)- 
SELECT H.empid, H.firstname, H.lastname, N.n
FROM HR.Employees as H 
   CROSS JOIN DBO.Nums as N 
WHERE N.n <= 5;

-- CORRECT - 
SELECT H.empid, H.firstname, H.lastname, N.n
FROM HR.Employees as H 
   CROSS JOIN DBO.Nums as N 
WHERE N.n <= 5
ORDER BY n, empid;

--Exercise 1-2:
-- MINE - 
--Couldn't solve

-- CORRECT - 
SELECT E.empid,
   DATEADD(day, D.n - 1, CAST('20160612' AS DATE)) AS dt 
FROM HR.Employees as E
   CROSS JOIN DBO.Nums as D 
WHERE D.n <= DATEDIFF(DAY, '20160612', '20160616') + 1
ORDER BY empid, dt;

--Exercise 2:
--Difference shown between two querys question. no answer needed

--Exercise 3:
-- MINE (sorted by customer name not id(looks better), and used "sum" on orders not ""count" "distinct"" (overcounting on my part))- 
SELECT SC.contactname, SUM(SO.orderid) as totalorders, sum(SOD.qty) as qty
FROM Sales.Customers as SC
   INNER JOIN Sales.Orders as SO
      ON SC.custid = SO.custid
   INNER JOIN Sales.OrderDetails as SOD
      ON SOD.orderid = SO.orderid
WHERE SC.country = 'USA'
GROUP BY SC.contactname;


-- CORRECT - 
SELECT SC.custid, COUNT(DISTINCT SO.orderid) as totalorders, sum(SOD.qty) as qty
FROM Sales.Customers as SC
   INNER JOIN Sales.Orders as SO
      ON SC.custid = SO.custid
   INNER JOIN Sales.OrderDetails as SOD
      ON SOD.orderid = SO.orderid
WHERE SC.country = 'USA'
GROUP BY SC.custid;


--Exercise 4:
-- MINE (only difference is I added a orderby to put nulls at top)-
SELECT SC.custid, SC.companyname, SO.orderid, SO.orderdate
FROM Sales.Customers as SC
   Left Outer Join Sales.Orders as SO
      ON SC.custid = SO.custid
ORDER BY SO.orderdate;


-- CORRECT - 
SELECT SC.custid, SC.companyname, SO.orderid, SO.orderdate
FROM Sales.Customers as SC
   Left Outer Join Sales.Orders as SO
      ON SC.custid = SO.custid;

--Exercise 5:
-- MINE (only difference is I added a orderby to put nulls at top if any)-
SELECT SC.custid, SC.companyname, SO.orderid, SO.orderdate
FROM Sales.Customers as SC
   Left Outer Join Sales.Orders as SO
      ON SC.custid = SO.custid
WHERE SO.orderid IS NOT NULL
ORDER BY SO.orderdate;


-- CORRECT -
SELECT SC.custid, SC.companyname, SO.orderid, SO.orderdate
FROM Sales.Customers as SC
   Left Outer Join Sales.Orders as SO
      ON SC.custid = SO.custid
WHERE SO.orderid IS NOT NULL;


--Exercise 6:
-- MINE (correct no issues)-
SELECT SC.custid, SC.companyname, SO.orderid, SO.orderdate
FROM Sales.Customers as SC
   Left Outer Join Sales.Orders as SO
      ON SC.custid = SO.custid
WHERE SO.orderdate = '2016-02-12';


-- CORRECT -
SELECT SC.custid, SC.companyname, SO.orderid, SO.orderdate
FROM Sales.Customers as SC
   Left Outer Join Sales.Orders as SO
      ON SC.custid = SO.custid
WHERE SO.orderdate = '2016-02-12';



--Exercise 7:
-- MINE (failed, forot the AND option for on as well)-
SELECT SC.custid, SC.companyname, SO.orderid, SO.orderdate
FROM Sales.Customers as SC
   Left Outer Join Sales.Orders as SO
      ON SO.orderdate = '2016-02-12';

-- CORRECT -
SELECT SC.custid, SC.companyname, SO.orderid, SO.orderdate
FROM Sales.Customers as SC
   Left Outer Join Sales.Orders as SO
      ON SC.custid = SO.custid AND  SO.orderdate = '2016-02-12';

--Exercise 8:
--explain your choice question. no answer needed here

--Exercise 9:
-- CORRECT (Extra)-
SELECT DISTINCT SC.custid, SC.companyname, 
CASE WHEN SO.orderid IS NOT NULL THEN 'YES' ELSE 'NO' END AS hasorderon20160212 
FROM Sales.Customers as SC
   Left Outer Join Sales.Orders as SO
      ON SC.custid = SO.custid AND  SO.orderdate = '2016-02-12';