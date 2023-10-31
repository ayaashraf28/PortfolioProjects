--Exploring the data - the Customer Table:

SELECT TABLE_NAME
FROM AdventureWorksDW2022.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- Therefore, there are 31 tables in this database.

SELECT COUNT(*) AS [Number of Columns]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DimCustomer';

SELECT COUNT(*) AS numrows
FROM DimCustomer

--So, there are 29 columns in DimCustomer table and 18484 rows. 
--We will be performing data exploration and data cleaning on the tables relevant to our future visualization.


SELECT DISTINCT(englishoccupation) As [Unique Occupations]
FROM DimCustomer
--There are 5 unique occupations.

SELECT *
FROM DimCustomer
WHERE EnglishOccupation IS NULL;
--No errors or missing values in this column.

SELECT *
FROM DimCustomer
WHERE FirstName IS NULL

SELECT *
FROM DimCustomer
WHERE LastName IS NULL
--No errors or missing values in name columns.

SELECT *
FROM DimCustomer
WHERE YearlyIncome IS NULL
--No errors or missing values in name columns.

--Removing irrelevant columns

ALTER TABLE [dbo].[DimCustomer]
DROP COLUMN [Title],[MiddleName],[NameStyle],[Suffix],[NumberChildrenAtHome],
[SpanishEducation],[FrenchEducation],[SpanishOccupation],[FrenchOccupation],[NumberCarsOwned],[AddressLine1],[AddressLine2],[Phone],[CommuteDistance]

--Correcting data under HouseOwner to be more understandable
UPDATE [dbo].[DimCustomer]
SET HouseOwnerFlag = 
		CASE WHEN [HouseOwnerFlag]=1 THEN 'Y'
		ELSE 'N'
		END 

--Renamed Column.
EXEC sp_rename '[dbo].[DimCustomer].[HouseOwnerFlag]','HomeOwner', 'COLUMN';

SELECT *
FROM DimCustomer

--Checking for duplicates:
WITH RownumCTE AS(
  SELECT *, 
	ROW_NUMBER() OVER(
	PARTITION BY [CustomerKey],
				[YearlyIncome],
				[BirthDate],
				[TotalChildren],
				[DateFirstPurchase],
				[GeographyKey]
	ORDER BY 
			CustomerKey
			) rownumber
FROM DimCustomer
)

SELECT *
FROM RowNumCTE

---
CREATE VIEW CustomerTable AS
SELECT CustomerKey,FirstName,LastName,BirthDate,MaritalStatus,Gender,EmailAddress,YearlyIncome,TotalChildren,EnglishEducation,
EnglishOccupation,HomeOwner,DateFirstPurchase,City,EnglishCountryRegionName,SalesTerritoryKey
FROM DimCustomer C
LEFT JOIN DimGeography G
ON C.GeographyKey = G.GeographyKey

SELECT *
FROM CustomerTable

SELECT *
FROM CustomerTable C
LEFT JOIN DimSalesTerritory ST
ON C.SalesTerritoryKey = ST.SalesTerritoryKey

CREATE VIEW Customer_SalesTerritory AS
SELECT CustomerKey,FirstName,LastName,YearlyIncome,EnglishEducation,
EnglishOccupation,HomeOwner,City,EnglishCountryRegionName,SalesTerritoryCountry,SalesTerritoryGroup
FROM CustomerTable C
LEFT JOIN DimSalesTerritory ST
ON C.SalesTerritoryKey = ST.SalesTerritoryKey


----- EDA on FactInternetSales and Products Tables:

SELECT COUNT(*) AS [num of columns]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'FactInternetSales';

SELECT COUNT(*) AS rownum
FROM FactInternetSales;

--So, there are 26 columns in DimCustomer table and 60398 rows. 

--Calculate total number of products:
SELECT COUNT(DISTINCT EnglishProductName) AS [Total Number of Products]
FROM DimProduct
-- # products 504

--Calculate number of products in each category:

SELECT DISTINCT englishproductcategoryname
FROM DimProductCategory
-- # main categories 4

SELECT DISTINCT [EnglishProductSubcategoryName]
FROM DimProductSubcategory
-- # subcategories 37

--Creating Products Table:
SELECT EnglishProductCategoryName [Product Category], COUNT(EnglishProductName) AS [No. of Products in Category]
FROM DimProductCategory C
INNER JOIN(SELECT EnglishProductName, ProductCategoryKey
           FROM DimProduct P
           INNER JOIN DimProductSubcategory S
           ON P.ProductSubcategoryKey = S.ProductSubcategoryKey) P
ON C.ProductCategoryKey = P.ProductCategoryKey
GROUP BY EnglishProductCategoryName
ORDER BY 1


SELECT DISTINCT Prod.EnglishProductName AS [Product Name], S.EnglishProductSubcategoryName AS Subcategory, 
C.EnglishProductCategoryName AS [Category],Prod.StandardCost,Prod.ListPrice
FROM DimProductCategory C
INNER JOIN (SELECT EnglishProductName, ProductCategoryKey
			FROM DimProduct P
			JOIN DimProductSubcategory S
			ON P.ProductSubcategoryKey = S.ProductSubcategoryKey) P
ON C.ProductCategoryKey = P.ProductCategoryKey
JOIN DimProductSubcategory S
ON S.ProductCategoryKey = C.ProductCategoryKey
JOIN DimProduct Prod
ON Prod.ProductSubcategoryKey = S.ProductSubcategoryKey
ORDER BY 1

--Checking for null values:
SELECT DISTINCT Prod.EnglishProductName AS [Product Name], S.EnglishProductSubcategoryName AS Subcategory, 
C.EnglishProductCategoryName AS [Category],Prod.StandardCost,Prod.ListPrice
FROM DimProductCategory C
INNER JOIN (SELECT EnglishProductName, ProductCategoryKey
			FROM DimProduct P
			JOIN DimProductSubcategory S
			ON P.ProductSubcategoryKey = S.ProductSubcategoryKey) P
ON C.ProductCategoryKey = P.ProductCategoryKey
JOIN DimProductSubcategory S
ON S.ProductCategoryKey = C.ProductCategoryKey
JOIN DimProduct Prod
ON Prod.ProductSubcategoryKey = S.ProductSubcategoryKey
WHERE Prod.StandardCost IS NULL OR Prod.ListPrice IS NULL
ORDER BY 1
--2 products "HL Road Frame - Black" and "HL Road Frame - Red" have null values.

SELECT DISTINCT(EnglishProductName),*
FROM DimProduct
WHERE ProductSubcategoryKey IS NULL
-- 209 products have null subcategory key, null values in cost and selling prices.

--Create ProductsTable:
CREATE VIEW ProductsTable AS
SELECT DISTINCT Prod.EnglishProductName AS [Product Name], Prod.ProductKey,S.EnglishProductSubcategoryName AS Subcategory, 
C.EnglishProductCategoryName AS [Category],Prod.StandardCost,Prod.ListPrice
FROM DimProductCategory C
INNER JOIN (SELECT EnglishProductName, ProductCategoryKey
			FROM DimProduct P
			JOIN DimProductSubcategory S
			ON P.ProductSubcategoryKey = S.ProductSubcategoryKey) P
ON C.ProductCategoryKey = P.ProductCategoryKey
JOIN DimProductSubcategory S
ON S.ProductCategoryKey = C.ProductCategoryKey
JOIN DimProduct Prod
ON Prod.ProductSubcategoryKey = S.ProductSubcategoryKey
ORDER BY 2



--Calculate total sales:
SELECT SUM(SalesAmount) AS [TotalSales]
FROM FactInternetSales;

--Calculate total sales per product:
SELECT P.ProductKey, P.EnglishProductName, SUM(S.SalesAmount) AS TotalSalesperProduct
FROM FactInternetSales S
JOIN DimProduct P
ON S.ProductKey = P.ProductKey
GROUP BY P.ProductKey, P.EnglishProductName
ORDER BY 1

--Create in a View:
CREATE VIEW SalesperProduct AS
SELECT P.ProductKey, P.EnglishProductName, SUM(S.SalesAmount) AS TotalSalesperProduct
FROM FactInternetSales S
JOIN DimProduct P
ON S.ProductKey = P.ProductKey
GROUP BY P.ProductKey, P.EnglishProductName


--Calculate total order quantity:

SELECT *
FROM FactInternetSales
ORDER BY ProductKey

SELECT SUM(orderquantity) [Total Order Quantity]
FROM AdventureWorksDW2022.[dbo].[FactInternetSales];

--Total Order by Products:
SELECT P.ProductKey, P.EnglishProductName, SUM(S.orderquantity) AS [Total Order per Product]
FROM FactInternetSales S
JOIN DimProduct P
ON S.ProductKey = P.ProductKey
GROUP BY P.ProductKey, P.EnglishProductName

CREATE VIEW OrderperProduct AS
SELECT P.ProductKey, P.EnglishProductName, SUM(S.orderquantity) AS [Total Order per Product]
FROM FactInternetSales S
JOIN DimProduct P
ON S.ProductKey = P.ProductKey
GROUP BY P.ProductKey, P.EnglishProductName


--Calculate Top 10 Customers with most sales:

SELECT TOP 10 CONCAT(FirstName,' ',LastName) AS [Customer Name], SUM(SalesAmount) AS [Total Sales]
FROM DimCustomer C
JOIN FactInternetSales S
ON C.CustomerKey = S.CustomerKey
GROUP BY CONCAT(C.Firstname,' ',C.Lastname)
ORDER BY [Total Sales] DESC

--Calculate Total Profit:

SELECT SUM(SalesAmount) - SUM(ProductStandardCost) AS [Total Profit]
FROM FactInternetSales;

--Query all years' performance according to total sales? And query the Year with highest sales:

SELECT YEAR(OrderDate) AS Year, SUM(SalesAmount) AS [Total Sales]
FROM FactInternetSales
GROUP BY YEAR(OrderDate)
Order By [Total Sales] DESC

SELECT TOP 1 YEAR(OrderDate) AS Year, SUM(SalesAmount) As [Total Sales]
FROM FactInternetSales
GROUP BY YEAR(OrderDate)
ORDER BY 2 DESC

--Query the top 5 employees with highest sales:

SELECT TOP 5 CONCAT(FirstName,' ',LastName) AS EmployeeName, SUM(SalesAmount) AS [Total Sales]
FROM FactInternetSales S
JOIN DimEmployee E
ON S.SalesTerritoryKey = E.SalesTerritoryKey
GROUP BY CONCAT(FirstName,' ',LastName)
ORDER BY 2 DESC

--Query order of Sales Territory Regions according to Total Sales, and query Region with Most Sales:

SELECT D.SalesTerritoryRegion AS [Sales Region], D.SalesTerritoryCountry AS [Sales Country], SUM(F.SalesAmount) AS [Total Sales]
FROM DimSalesTerritory D
JOIN FactInternetSales F
ON D.SalesTerritoryKey = F.SalesTerritoryKey
GROUP BY D.SalesTerritoryRegion, D.SalesTerritoryCountry
ORDER BY [Total Sales] DESC

SELECT TOP 1 D.SalesTerritoryRegion AS [Sales Region], SUM(F.SalesAmount) AS [Total Sales]
FROM DimSalesTerritory D
JOIN FactInternetSales F
ON D.SalesTerritoryKey = F.SalesTerritoryKey
GROUP BY D.SalesTerritoryRegion
ORDER BY [Total Sales] DESC

--Query Customer with highest total orders:

SELECT CONCAT(C.FirstName,' ',C.LastName) AS [Customer Name], SUM(F.OrderQuantity) AS [Total Orders]
FROM FactInternetSales F
JOIN DimCustomer C
ON F.CustomerKey = C.CustomerKey
GROUP BY CONCAT(FirstName,' ',LastName)
ORDER BY [Total Orders] DESC


--Query frequency of customer order quantity:

SELECT [Total Orders], COUNT([Total Orders]) AS [Frequency of Order Quantity]
FROM	(SELECT CONCAT(C.FirstName,' ',C.LastName) AS [Customer Name], SUM(F.OrderQuantity) AS [Total Orders]
		FROM FactInternetSales F
		JOIN DimCustomer C
		ON F.CustomerKey = C.CustomerKey
		GROUP BY CONCAT(FirstName,' ',LastName)
		) AS [TotalOrders]
GROUP BY [Total Orders]
ORDER BY [Frequency of Order Quantity] DESC


--Rank Customers according to total sales:

SELECT CONCAT(FirstName,' ',LastName) AS [Customer Name], SUM(SalesAmount) AS [Total Sales],
CASE WHEN SUM(SalesAmount) > 10000 THEN 'Diamond'
		WHEN SUM(SalesAmount) > 5000 THEN 'Gold'
		WHEN SUM(SalesAmount) > 1000 THEN 'Silver'
		ELSE 'Bronze'
		END AS 'Customer Rank'
FROM DimCustomer D
JOIN FactInternetSales F
ON D.CustomerKey = F.CustomerKey
GROUP BY CONCAT(FirstName,' ',LastName)
ORDER BY [Total Sales] DESC


--Calculate Average Sales per Customer:

SELECT CONCAT(FirstName,' ',LastName) AS [Customer Name], AVG(SalesAmount) AS [Average Sales]
FROM DimCustomer D
JOIN FactInternetSales F
ON D.CustomerKey = F.CustomerKey
GROUP BY CONCAT(FirstName,' ',LastName)
ORDER BY 1


--Create Sales Table for last 4 years:
--2020 Sales Table:
SELECT OrderDate,ProductKey,CustomerKey,OrderQuantity,UnitPrice,SalesAmount,TotalProductCost,SalesTerritoryKey
FROM FactInternetSales
WHERE YEAR(orderdate) = 2020
ORDER BY 1

CREATE VIEW SalesData20 AS
SELECT S.OrderDate,S.ProductKey,P.EnglishProductName,S.CustomerKey,CONCAT(C.FirstName,' ',C.LastName) AS FullName,
OrderQuantity,UnitPrice,SalesAmount,TotalProductCost,S.SalesTerritoryKey,T.SalesTerritoryCountry
FROM FactInternetSales S
JOIN DimProduct P
ON S.ProductKey=P.ProductKey
JOIN DimCustomer C
ON S.CustomerKey=C.CustomerKey
JOIN DimSalesTerritory T
ON S.SalesTerritoryKey=T.SalesTerritoryKey
WHERE YEAR(orderdate) = 2020

SELECT *
FROM SalesData20


--2021 Sales Table:
CREATE VIEW SalesData21 AS
SELECT S.OrderDate,S.ProductKey,P.EnglishProductName,S.CustomerKey,CONCAT(C.FirstName,' ',C.LastName) AS FullName,
OrderQuantity,UnitPrice,SalesAmount,TotalProductCost,S.SalesTerritoryKey,T.SalesTerritoryCountry
FROM FactInternetSales S
JOIN DimProduct P
ON S.ProductKey=P.ProductKey
JOIN DimCustomer C
ON S.CustomerKey=C.CustomerKey
JOIN DimSalesTerritory T
ON S.SalesTerritoryKey=T.SalesTerritoryKey
WHERE YEAR(orderdate) = 2021
--ORDER BY 1


--2022 Sales Table:
CREATE VIEW SalesData22 AS
SELECT S.OrderDate,S.ProductKey,P.EnglishProductName,S.CustomerKey,CONCAT(C.FirstName,' ',C.LastName) AS FullName,
OrderQuantity,UnitPrice,SalesAmount,TotalProductCost,S.SalesTerritoryKey,T.SalesTerritoryCountry
FROM FactInternetSales S
JOIN DimProduct P
ON S.ProductKey=P.ProductKey
JOIN DimCustomer C
ON S.CustomerKey=C.CustomerKey
JOIN DimSalesTerritory T
ON S.SalesTerritoryKey=T.SalesTerritoryKey
WHERE YEAR(orderdate) = 2022
--ORDER BY 1


--2023 Sales Table:
CREATE VIEW SalesData23 AS
SELECT S.OrderDate,S.ProductKey,P.EnglishProductName,S.CustomerKey,CONCAT(C.FirstName,' ',C.LastName) AS FullName,
OrderQuantity,UnitPrice,SalesAmount,TotalProductCost,S.SalesTerritoryKey,T.SalesTerritoryCountry
FROM FactInternetSales S
JOIN DimProduct P
ON S.ProductKey=P.ProductKey
JOIN DimCustomer C
ON S.CustomerKey=C.CustomerKey
JOIN DimSalesTerritory T
ON S.SalesTerritoryKey=T.SalesTerritoryKey
WHERE YEAR(orderdate) = 2023
--ORDER BY 1 