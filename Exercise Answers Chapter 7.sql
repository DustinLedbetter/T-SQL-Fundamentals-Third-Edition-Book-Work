----------------------
-- Chapter 7 (Beyond the fundamentals of querying:)--
----------------------

----------------
--Chapter Work--
----------------

--Window Functions--


--1.)
--// Simple window function use
USE TSQLV4;

SELECT empid, ordermonth, val, 
	SUM(val) OVER (PARTITION BY empid
				   ORDER BY ordermonth
				   ROWS BETWEEN UNBOUNDED PRECEDING
								AND CURRENT ROW) AS runval
FROM Sales.EmpOrders


--2.)
--// Used to show the rownumber, rank, dense_rank, and ntile functions

--ex.1)
SELECT orderid, custid, val, 
	ROW_NUMBER()  OVER (ORDER BY val) AS rownum,
	RANK()		  OVER (ORDER BY val) AS rank,
	DENSE_RANK()  OVER (ORDER BY val) AS dense_rank,
	NTILE(100)    OVER (ORDER BY val) AS ntile
FROM Sales.OrderValues
ORDER BY val;

--ex.2)
--// Use an extra orderby (tie-breaker) to make a row number calculation deterministic
SELECT orderid, custid, val, 
	ROW_NUMBER()  OVER (ORDER BY val, orderid) AS rownum,
	RANK()		  OVER (ORDER BY val, orderid) AS rank,
	DENSE_RANK()  OVER (ORDER BY val, orderid) AS dense_rank,
	NTILE(100)    OVER (ORDER BY val, orderid) AS ntile
FROM Sales.OrderValues
ORDER BY val;


--3.)
--// Used to show how the function assigns row numbers individually for each customer
SELECT orderid, custid, val, 
	ROW_NUMBER()  OVER (PARTITION BY custid
						ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;


--4.)
--// Used to show how we must use group by if we want to use distinct on a window function

--ex1.)
--// row_number is processed before distinct so the rows will be assigned numbers before removing duplicates
SELECT DISTINCT val, ROW_NUMBER()  OVER (ORDER BY val) AS rownum
FROM Sales.OrderValues

--ex2.)
--// Group by is processed before rownumber in select. it groups and the row_number then assigns numbers 
--// this will make the row nums distinct)
SELECT DISTINCT val, ROW_NUMBER()  OVER (ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;


--5.)
--// Used to show the last field before current and next field after current
--// (normally use the returned values to compute something ie... [val-LAG(val) OVER...])
SELECT custid, orderid, val,
	LAG(val) OVER (PARTITION BY custid
					ORDER BY orderdate, orderid) AS preval,
	LEAD(val) OVER (PARTITION BY custid
					ORDER BY orderdate, orderid) AS nextval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;


--6.)
--// used to show customers first order and last order with rows
--// (normally use the returned values to compute something ie... [val-FIRST_VALUE(val) OVER...])
SELECT custid, orderid, val,
	FIRST_VALUE(val) OVER (PARTITION BY custid
					ORDER BY orderdate, orderid
					ROWS BETWEEN UNBOUNDED PRECEDING
								 AND CURRENT ROW) AS firstval,
	LAST_VALUE(val) OVER (PARTITION BY custid
					ORDER BY orderdate, orderid
					ROWS BETWEEN CURRENT ROW
					AND UNBOUNDED FOLLOWING) AS lastval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;


--7.)
--// used to show the grand total and customers total alongside each other
SELECT orderid, custid, val,
	SUM(val) OVER() AS totalvalue,
	SUM(val) OVER(PARTITION BY custid) AS custtotalvalue
FROM Sales.OrderValues;


--8.)
--// Mixes details and aggregates 
--// (calculates for each row the % of current value out of grand total as well as customer total)
SELECT orderid, custid, val,
	100. * val / SUM(val) OVER() AS percenttotal,
	100. * val / SUM(val) OVER(PARTITION BY custid) AS percentcusttotal
FROM Sales.OrderValues;


--Pivoting Data--


--1.)
--// Setting up a new table to test out with pivoting
USE TSQLV4;

DROP TABLE IF EXISTS dbo.Orders;

CREATE TABLE dbo.Orders
(
 orderid	INT			NOT NULL,
 orderdate	DATE		NOT NULL,
 empid		INT			NOT NULL,
 custid		VARCHAR(5)	NOT NULL,
 qty		INT			NOT NULL,
 CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid, qty)
VALUES
	(30001, '20140802', 3, 'A', 10),
	(10001, '20141224', 2, 'A', 12),
	(10005, '20141224', 1, 'B', 20),
	(40001, '20150109', 2, 'A', 40),
	(10006, '20150118', 1, 'C', 14),
	(20001, '20150212', 2, 'B', 12),
	(40005, '20160212', 3, 'A', 10),
	(20002, '20160216', 1, 'C', 20),
	(30003, '20160418', 2, 'B', 15),
	(30004, '20140418', 3, 'C', 22),
	(30007, '20160907', 3, 'D', 30);

SELECT * FROM dbo.Orders;



--2.)
--// Returns total qty for employees and customers
SELECT	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid; 


--3.)
--// Pivoting with a grouped query
SELECT	empid,
SUM(CASE WHEN custid ='A' THEN qty END) AS A,
SUM(CASE WHEN custid ='B' THEN qty END) AS B,
SUM(CASE WHEN custid ='C' THEN qty END) AS C,
SUM(CASE WHEN custid ='D' THEN qty END) AS D
FROM dbo.Orders
GROUP BY empid; 


--4.)
--// Pivoting with the pivot operator (less code)
SELECT	empid, A, B, C, D
FROM (SELECT empid, custid, qty
	  FROM dbo.Orders) AS D
PIVOT (SUM(qty) FOR custid IN(A, B, C, D)) AS P;


--5.)
--// Pivoting on the empid instead of custid 
--// (brackets used when odd variables like numbers [1] or if contains a dash in it [this-one]  ) 
SELECT	custid, [1], [2], [3]
FROM (SELECT empid, custid, qty
	  FROM dbo.Orders) AS D
PIVOT (SUM(qty) FOR empid IN([1], [2], [3])) AS P;


--6.)
--// Create table for use in demonstrating unpivoting
USE TSQLV4;

DROP TABLE IF EXISTS dbo.EmpCustOrders;

CREATE TABLE dbo.EmpCustOrders
(
	empid INT NOT NULL
		CONSTRAINT PK_EmpCustOrders PRIMARY KEY,
	A VARCHAR(5) NULL,
	B VARCHAR(5) NULL,
	C VARCHAR(5) NULL,
	D VARCHAR(5) NULL,
);

INSERT INTO dbo.EmpCustOrders(empid, A, B, C, D)
	SELECT empid, A, B, C, D
	FROM (SELECT empid, custid, qty
		  FROM dbo.Orders) AS D
	PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;

	SELECT * FROM dbo.EmpCustOrders;


--7.)
--// Unpivoting with the apply operator

--STEP 1
--// Create four copies for each source row (one for each customer: A,B,C, and D)
SELECT *
FROM dbo.EmpCustOrders
	CROSS JOIN (VALUES('A'),('B'),('C'),('D')) AS C(custid);

--STEP 2 
--// Extract values from one of the 4 columns of customer qty(A, B, C, and D) and return a single column called qty
SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	CROSS APPLY (VALUES('A', A),('B', B),('C', C),('D', D)) AS C(custid, qty);

--STEP 3
--// Remove nulls using WHERE clause
SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	CROSS APPLY (VALUES('A', A),('B', B),('C', C),('D', D)) AS C(custid, qty)
	WHERE qty IS NOT NULL;


--8.)
--// Unpivoting with the UNPIVOT operator
--// Single line that is much easier to write and doesn't need a where clause added for nulls
SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	UNPIVOT(qty FOR custid IN(A,B,C,D)) AS U;

--// Basically, use UNPIVOT when you don't want nulls, and CROSS APPLY when you do want to keep them



-- Grouping Sets -- 


--1.)
--// Showing the individual sets

-- empid and custid
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid;

-- empid
SELECT empid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid;

-- custid
SELECT custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY custid;

-- empty set (used to get grand total)
SELECT SUM(qty) AS sumqty
FROM dbo.Orders;


--2.)
--// getting a unified result set instead of four seperate sets 
--// Showing option one(How we achieve this currently without using the built in grouping query function)
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid

UNION ALL

SELECT empid, NULL ,SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid

UNION ALL

SELECT NULL, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY custid

UNION ALL

SELECT NULL, NULL, SUM(qty) AS sumqty
FROM dbo.Orders;

--//This gets the right results, but has long code and bad performance since uses 4 seperate queries


--3.)
--// GROUPING SETS subclause (much shorter and optimized by internal roll up aggregates)
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY 
	GROUPING SETS
	(
	 (empid, custid),
	 (empid),
	 (custid),
	 ()
	);

 
--4.)
--// CUBE subclause (abbreviated way of calling the last query) 
--produces all possible sets as such ((a,b,c),(a,b),(a,c),(b,c),(a),(b),(c),())
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);


--5.)
--// ROLLUP subclause (abbreviated way that is based on hierarchy)
--produces based on hierarchy as such: ((a,b,c),(a,b),(a),())
SELECT
	YEAR(orderdate) AS orderyear,
	MONTH(orderdate) AS ordermonth,
	DAY(orderdate) AS orderday, 
	SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));
 
 
--6.)
--// Shows GROUPING on variables to display which groups the row belongs to. 
SELECT 
	GROUPING(empid) AS grpemp,
	GROUPING(custid) AS grpcust,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

 
--7.)
--// abbreviated and better way to display the groups. creates a bitmap for them (each row has a new row number)
SELECT 
	GROUPING_ID(empid, custid) AS groupingset,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

-- '0'(binary 00) represents grouping set(empid,custid). '1'(binary 01) represents grouping set(empid).
-- '2'(binary 10) represents grouping set(custid).       '3'(binary 11) represents grouping empty set().



-------------
--Exercises--
-------------

--Exercise 1:
-- MINE (correct)- 
SELECT custid, orderid, qty, 
	RANK() OVER(PARTITION BY custid
						ORDER BY qty) AS rank,
	DENSE_RANK()  OVER (PARTITION BY custid
						ORDER BY qty) AS dense_rank
FROM dbo.Orders
ORDER BY custid, qty;


--Exercise 2:
-- MINE (correct, but had to use help from book)- 
WITH V AS
(
SELECT DISTINCT val
FROM Sales.OrderValues
)
SELECT DISTINCT val, ROW_NUMBER()  OVER (ORDER BY val) AS rownum
FROM V;


--Exercise 3:
-- MINE (wrong, was using first value and not lag or lead.)- 
SELECT custid, orderid, qty,
	qty - FIRST_VALUE(qty) OVER (PARTITION BY custid
					ORDER BY orderdate, orderid
					ROWS BETWEEN UNBOUNDED PRECEDING
								 AND CURRENT ROW) AS firstval,
	qty - LAST_VALUE(qty) OVER (PARTITION BY custid
					ORDER BY orderdate, orderid
					ROWS BETWEEN CURRENT ROW
					AND UNBOUNDED FOLLOWING) AS lastval
FROM dbo.Orders
ORDER BY custid, orderdate, orderid;


-- CORRECT -
SELECT custid, orderid, qty,
	qty - lag(qty) OVER (PARTITION BY custid
					ORDER BY orderdate, orderid) AS firstval,
	qty - lead(qty) OVER (PARTITION BY custid
					ORDER BY orderdate, orderid) AS lastval
FROM dbo.Orders
ORDER BY custid, orderdate, orderid;



--Exercise 4:
-- MINE (tried with pivot operator and failed(FORGOT TO USE BRACKETS). case works though)- 
SELECT	empid, cnt2014, cnt2015, cnt2016
FROM (SELECT empid, YEAR(orderdate) AS orderyear
	  FROM dbo.Orders) AS D
PIVOT (COUNT(orderyear) FOR orderyear IN(cnt2014, cnt2015, cnt2016)) AS P;


SELECT	empid,
COUNT(CASE WHEN YEAR(orderdate) = '2014' THEN orderdate END) AS cnt2014,
COUNT(CASE WHEN YEAR(orderdate) = '2015' THEN orderdate END) AS cnt2015,
COUNT(CASE WHEN YEAR(orderdate) = '2016' THEN orderdate END) AS cnt2016
FROM dbo.Orders
GROUP BY empid; 


-- CORRECT -
SELECT	empid, [2014] AS cnt2014, [2015] AS cnt2015, [2016] AS cnt2016
FROM (SELECT empid, YEAR(orderdate) AS orderyear
	  FROM dbo.Orders) AS D
PIVOT (COUNT(orderyear) FOR orderyear IN([2014], [2015], [2016])) AS P;

--Exercise 5:
-- MINE ()- 

--Part 1 (create table that is pivoted for use in part 2 to unpivot)
USE TSQLV4;

DROP TABLE IF EXISTS dbo.EmpYearOrders;

CREATE TABLE dbo.EmpYearOrders
(
 empid INT NOT NULL CONSTRAINT PK_EmpYearOrders PRIMARY KEY,
 cnt2014 INT NULL,
 cnt2015 INT NULL,
 cnt2016 INT NULL,
);

INSERT INTO dbo.EmpYearOrders(empid, cnt2014, cnt2015, cnt2016)
	SELECT empid, [2014] AS cnt2014, [2015] AS cnt2015, [2016] AS cnt2016
	FROM (SELECT empid, YEAR(orderdate) AS orderyear
		  FROM dbo.Orders) AS D
		PIVOT(COUNT(orderyear)
			  FOR orderyear IN ([2014], [2015], [2016])) AS P; 

SELECT * FROM dbo.EmpYearOrders;

--Part 2 (unpivoting the table)
--//unsolved couldn't get the dates to work correctly in unpivot  
--//but after seeing solution I was on the right track apparently


-- CORRECT (followed through both solutions)-

--unpivot
SELECT empid, CAST(RIGHT(orderyear, 4) AS INT) AS orderyear, numorders
FROM dbo.EmpYearOrders
	UNPIVOT(numorders FOR orderyear IN(cnt2014, cnt2015, cnt2016)) AS U
	WHERE numorders <> 0;

--cross apply
SELECT empid, orderyear, numorders
FROM dbo.EmpYearOrders
	CROSS APPLY (VALUES(2014, cnt2014),
					   (2015, cnt2015),
					   (2016, cnt2016)) AS A (orderyear, numorders)
WHERE numorders <> 0;


--Exercise 6:
-- MINE ()- 

--trying with cube. too many return
SELECT 
	GROUPING_ID(empid, custid, YEAR(orderdate)) AS groupingset,
	empid, custid, YEAR(orderdate), SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid, YEAR(orderdate));

--trying with grouping sets (correct results)
SELECT 
	GROUPING_ID(empid, custid, YEAR(orderdate)) AS groupingset,
	empid, custid, YEAR(orderdate), SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY 
	GROUPING SETS
	(
	 (empid, custid, YEAR(orderdate)),
	 (empid, YEAR(orderdate)),
	 (custid, YEAR(orderdate)),
	 ()
	);
	
	
-- CORRECT -
SELECT 
	GROUPING_ID(empid, custid, YEAR(orderdate)) AS groupingset,
	empid, custid, YEAR(orderdate), SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY 
	GROUPING SETS
	(
	 (empid, custid, YEAR(orderdate)),
	 (empid, YEAR(orderdate)),
	 (custid, YEAR(orderdate)),
	);
	





