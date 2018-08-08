-------------------------------------------------------------------------
--File for excercise answers to chapters in the T-SQL Fundamentals Book--
-------------------------------------------------------------------------


---------------
-- CHAPTER 1 --
---------------

--NONE

---------------
-- CHAPTER 2 --
---------------

--Exercise 1:
-- MINE (correct)
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE YEAR(orderdate) = 2015 AND MONTH(orderdate) = 6;

--Exercise 2:
-- MINE (correct)
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);

--Exercise 3:
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname Like '%e%e%';

--Exercise 4:
-- MINE (fail)-
SELECT orderid
FROM Sales.OrderDetails
WHERE (qty * unitprice)

-- CORRECT -
SELECT orderid, SUM(qty * unitprice) AS totalvalue
FROM Sales.OrderDetails
GROUP BY orderid
Having SUM(qty * unitprice) > 10000
ORDER BY totalvalue DESC

--Exercise 5: 
-- MINE (works, but quite not sure why)- 
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'a-z%';

-- CORRECT -
SELECT empid, lastname
FROM HR.Employees
WHERE lastname COLLATE Latin1_General_CS_AS LIKE N'[abcdefghijklmnopqrstuvwxyz]%';

--Exercise 6:
--Difference shown between two querys question. no answer needed

--Exercise 7:
-- MINE (partial)-
SELECT shipcountry, AVG(freight) AS avgfreight 
FROM Sales.Orders
WHERE orderdate >= '20150101' and orderdate < '20160101'
GROUP BY shipcountry
ORDER BY avgfreight DESC;

-- CORRECT -
SELECT TOP(3) shipcountry, AVG(freight) AS avgfreight 
FROM Sales.Orders
WHERE orderdate >= '20150101' and orderdate < '20160101'
GROUP BY shipcountry
ORDER BY avgfreight DESC;


--Exercise 8:
-- MINE (works but not quite right(same results))-
SELECT custid, orderdate, orderid, 
   ROW_NUMBER() OVER(PARTITION BY orderdate ORDER BY orderid ) AS rownum
FROM Sales.Orders
ORDER BY custid;

-- CORRECT - 	
SELECT custid, orderdate, orderid, 
   ROW_NUMBER() OVER(PARTITION BY custid ORDER BY orderdate, orderid ) AS rownum
FROM Sales.Orders
ORDER BY custid;

--Exercise 9:
-- MINE (correct)- 
SELECT empid, firstname, lastname, titleofcourtesy,
   CASE titleofcourtesy
      WHEN 'Mr.' THEN ' Male'
	  WHEN 'Mrs.' THEN 'Female'
	  WHEN 'Ms.' THEN 'Female'
	  ELSE 'Unknown'
   END AS gender
FROM HR.Employees;

--Exercise 10:
-- MINE (fail)- 
SELECT custid, region
FROM Sales.Customers
WHERE region <> N'' OR region IS NULL;

-- CORRECT -
SELECT custid, region
FROM Sales.Customers
ORDER BY
   CASE WHEN region IS NULL THEN 1 ELSE 0 END, region;

