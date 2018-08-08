----------------------
-- Chapter 4 (SubQueries)--
----------------------

----------------
--Chapter Work--
----------------

--1.)
--// Storing a query into a variable and calling it in another query
DECLARE @maxid AS INT = (SELECT MAX(ORDERID) 
                         FROM Sales.Orders)

SELECT orderid, orderdate, empid, custid
	FROM Sales.Orders
	WHERE orderid = @maxid;



--2.)
--// Calling a subquery directly from within a query
--(Sub Query must return for one result.  the below query works because only person has name starting with 'C'. 
-- It will fail if two people had the same starting letter like 'd' // Will also return empty if null is answer as it is seen as unknown)
SELECT orderid
FROM Sales.Orders
WHERE empid = 
	(SELECT E.empid
	 FROM HR.Employees AS E
	 WHERE E.lastname LIKE N'C%');

--3.)
--// This subquery returns from multiple people but does not fail due to using the IN keyword after the WHERE keyword
SELECT orderid
FROM Sales.Orders
WHERE empid IN
	(SELECT E.empid
	 FROM HR.Employees AS E
	 WHERE E.lastname LIKE N'D%');


--4.)
--// Showing the use of a subquery to get customers who made orders within the USA
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders
WHERE custid IN
	(SELECT C.custid
	 FROM Sales.Customers AS C
	 WHERE C.country = N'USA');


--5.)
--// Used to create a new table that is populated by all of the even numbered orderids from Sales.Orders
USE TSQLV4;
DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.Orders(orderid INT NOT NULL CONSTRAINT PK_Orders PRIMARY KEY);

INSERT INTO dbo.Orders(orderid)
	SELECT orderid
	FROM Sales.Orders
	WHERE orderid % 2 = 0;


--6.)
--// Used to find all orders missing from the table we created above. the answer will be all the odd rows. 
--// This requires several subqueries to get min order number, max order number, and then to ensure it only gets the ones missing
SELECT n
FROM dbo.Nums
WHERE n BETWEEN (SELECT MIN(O.orderid) FROM dbo.Orders AS O)
	    AND (SELECT MAX(O.orderid) FROM dbo.Orders AS O)
   AND n NOT IN (SELECT O.orderid FROM dbo.Orders AS O);

--// Call this to clean up the database when done with the table
DROP TABLE IF EXISTS dbo.Orders;


--7.)
--// This is a correlated subquery. The inner sub query is dependant on the the outer query.
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders AS O1
WHERE orderid =
   (SELECT MAX(O2.orderid)
   FROM Sales.Orders AS O2
   WHERE O2.custid = O1.custid);


--8.)
--// This query returns the order percentage of the current order value out of the customer total
SELECT custid, orderid, val, 
	CAST(100. * val / (SELECT SUM(O2.val)
	FROM Sales.OrderValues AS O2
	WHERE O2.custid = O1.custid)
	AS NUMERIC(5,2)) AS pct
FROM Sales.OrderValues AS O1
ORDER BY custid, orderid;


--9.)
--// Demonstrates the EXISTS predicate
SELECT custid,companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
AND EXISTS
	(SELECT * FROM Sales.Orders AS O
	 WHERE O.custid = C.custid);


--10.)
--// Used to return information about current order and previous orders 
--// This is an illusion as there is no "order" in a database table, but can get close for display purposes
SELECT orderid, orderdate, empid, custid,
   (SELECT MAX(O2.orderid)
    FROM Sales.Orders AS O2
	WHERE O2.orderid < O1.orderid) AS prevorderid
FROM Sales.Orders AS O1;


--11.)
--// Used to return information about current order and next orders 
SELECT orderid, orderdate, empid, custid,
   (SELECT MIN(O2.orderid)
    FROM Sales.Orders AS O2
	WHERE O2.orderid > O1.orderid) AS nextorderid
FROM Sales.Orders AS O1;

--*There are functions LEAD and LAG that can do the above to quicker and will be learned in a later lesson Chapter 7*


--12.)
--// Shows the quantity of orders by year
SELECT orderyear, qty
FROM Sales.OrderTotalsByYear;

--// Shows the quantity of orders by year AND also the running total for all years
SELECT orderyear, qty,
   (SELECT SUM(O2.qty)
    FROM Sales.OrderTotalsByYear AS O2
	WHERE O2.orderyear <= O1.orderyear) AS runqty
FROM Sales.OrderTotalsByYear AS O1
ORDER BY orderyear;


-------------
--Exercises--
-------------

--Exercise 1:
-- MINE (overcomplicated the solution and it does not work, but on right path logically)- 
SELECT S2.orderid, S2.custid, S2.empid, 
 (SELECT S1.orderdate
  FROM Sales.Orders AS S1
  WHERE S1.orderdate < MAX(S1.orderdate))
FROM Sales.Orders AS S2


-- CORRECT - 
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = 
	(SELECT MAX(O.orderdate)
	 FROM Sales.Orders AS O);


--Exercise 2:
-- MINE (correct without ties option I hadn't been taught yet)- 
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders
WHERE custid IN 
	(SELECT TOP (1) O.custid
	FROM Sales.Orders AS O
	GROUP BY O.custid
	ORDER BY COUNT(*) DESC);

-- CORRECT -
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders
WHERE custid IN 
	(SELECT TOP (1) WITH TIES O.custid
	FROM Sales.Orders AS O
	GROUP BY O.custid
	ORDER BY COUNT(*) DESC); 


--Exercise 3:
-- MINE (Must use the NOT IN instead what I tried as everyone has orders placed before may 1 ao all are returned,
	but not all have orders placed after so by using the not after it only returns those who did not place them after date)- 
SELECT E.empid, E.firstname, E.lastname
FROM HR.Employees AS E
WHERE E.empid IN (SELECT O.empid
	FROM Sales.Orders AS O
	WHERE O.orderdate < '20160501');


-- CORRECT -
SELECT E.empid, E.firstname, E.lastname
FROM HR.Employees AS E
WHERE E.empid NOT IN (SELECT O.empid
	FROM Sales.Orders AS O
	WHERE O.orderdate >= '20160501');

--Exercise 4:
-- MINE (correct)- 
SELECT DISTINCT C.country
FROM Sales.Customers AS C
WHERE C.country NOT IN 
	(SELECT E.country
	FROM HR.Employees AS E);


-- CORRECT -
SELECT DISTINCT country
FROM Sales.Customers
WHERE country NOT IN 
	(SELECT E.country
	FROM HR.Employees AS E);


--Exercise 5:
-- MINE (Was on right track but got stuck on where needing to be cust from both)- 
SELECT C.orderid, C.orderdate, C.custid, C.empid
FROM Sales.Orders AS C
WHERE C.orderdate = 
	(SELECT MAX(O.orderdate)
	 FROM Sales.Orders AS O
	 WHERE C.custid = O.custid);


-- CORRECT -
SELECT C.orderid, C.orderdate, C.custid, C.empid
FROM Sales.Orders AS C
WHERE C.orderdate = 
	(SELECT MAX(O.orderdate)
	 FROM Sales.Orders AS O
	 WHERE C.custid = O.custid)
ORDER BY C.custid;


--Exercise 6:
-- MINE (I got orders that were not from 2016, but it still includes some from 2014 as well)- 
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN
	(SELECT O.custid
	 FROM Sales.Orders AS O
	 WHERE O.orderdate > '20151231')
ORDER BY custid;


-- CORRECT -
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
	(SELECT *
	 FROM Sales.Orders AS O
	 WHERE C.custid = O.custid 
	 AND O.orderdate >= '20150101'
	 AND O.orderdate < '20160101')
AND NOT EXISTS
	(SELECT *
	 FROM Sales.Orders AS O
	 WHERE C.custid = O.custid 
	 AND O.orderdate >= '20160101'
	 AND O.orderdate < '20170101');


--Exercise 7:
-- MINE (correct)- 
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
	(SELECT *
	 FROM Sales.Orders AS O
	 WHERE C.custid = O.custid 
AND EXISTS
	(SELECT *
	 FROM Sales.OrderDetails AS OD
	 WHERE OD.orderid = O.orderid 
	 AND OD.productid = 12));


-- CORRECT -
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
	(SELECT *
	 FROM Sales.Orders AS O
	 WHERE C.custid = O.custid 
AND EXISTS
	(SELECT *
	 FROM Sales.OrderDetails AS OD
	 WHERE OD.orderid = O.orderid 
	 AND OD.productid = 12));


--Exercise 8:
-- MINE (I was close, but forgot to also use custid as filter)- 
SELECT custid, ordermonth, qty,
   (SELECT SUM(O2.qty)
    FROM Sales.CustOrders AS O2
	WHERE O2.ordermonth <= O1.ordermonth) AS runqty
FROM Sales.CustOrders AS O1
ORDER BY custid, ordermonth;



-- CORRECT -
SELECT custid, ordermonth, qty,
   (SELECT SUM(O2.qty)
    FROM Sales.CustOrders AS O2
	WHERE  O2.custid = O1.custid 
	AND O2.ordermonth <= O1.ordermonth) AS runqty
FROM Sales.CustOrders AS O1
ORDER BY custid, ordermonth;


--Exercise 9:
--Discuss the difference between question. no answer needed here


--Exercise 10:
-- EXTRA -
--Step 1 computes the date of customers previous order
SELECT custid, orderdate, orderid,
	(SELECT TOP (1) O2.orderdate 
	 FROM Sales.Orders AS O2
	 WHERE O2.custid = O1.custid
		AND ( O2.orderdate = O1.orderdate 
		AND O2.orderid < O1.orderid 
		OR O2.orderdate < O1.orderdate)
	ORDER BY O2.orderdate DESC, O2.orderid DESC) AS prevdate
FROM Sales.Orders AS O1
ORDER BY custid, orderdate, orderid;

--Step 2 computes the difference of date found in first part and the current order date 
SELECT custid, orderdate, orderid,
	DATEDIFF(day,
	   (SELECT TOP (1) O2.orderdate 
	    FROM Sales.Orders AS O2
	    WHERE O2.custid = O1.custid
		   AND ( O2.orderdate = O1.orderdate AND O2.orderid < O1.orderid 
		   OR O2.orderdate < O1.orderdate)
	    ORDER BY O2.orderdate DESC, O2.orderid DESC),
	orderdate) AS diff
FROM Sales.Orders AS O1
ORDER BY custid, orderdate, orderid;


