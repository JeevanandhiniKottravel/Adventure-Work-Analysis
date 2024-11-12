create schema adventure;
use adventure;

#0. Union of Fact Internet sales and Fact internet sales new
CREATE TABLE Sales AS
SELECT * FROM factinternetsales;

INSERT INTO Sales (ProductKey,OrderDateKey,DueDateKey,ShipDateKey,CustomerKey,SalesTerritoryKey, 
SalesOrderNumber, OrderQuantity, UnitPrice, DiscountAmount,TotalProductCost,SalesAmount,TaxAmt,Freight)
SELECT ProductKey,OrderDateKey,DueDateKey,ShipDateKey,CustomerKey,SalesTerritoryKey, 
SalesOrderNumber, OrderQuantity, UnitPrice, DiscountAmount,TotalProductCost,SalesAmount,TaxAmt,Freight FROM factinternetsalesnew;

select * from sales;

#1.Lookup the productname from the Product sheet to Sales sheet.
SELECT s.*, DP.ProductName
FROM Sales S
JOIN dimProduct DP ON S.ProductKey = DP.ProductKey;

#2.Lookup the Customerfullname from the Customer and Unit Price from Product sheet to Sales sheet.

SELECT S.*, DP.UnitPrice, DC.CustomerName
FROM Sales S
JOIN dimProduct DP ON S.ProductKey = DP.ProductKey
JOIN DimCustomer DC ON S.CustomerKey = DC.CustomerKey
order by dc.customername;

#3.calcuate the following fields from the Orderdatekey field...
ALTER TABLE Sales
ADD COLUMN OrderDate VARCHAR(10);
UPDATE Sales
SET OrderDate = DATE_FORMAT(STR_TO_DATE(Orderdatekey, '%Y%m%d'), '%d-%m-%Y');

SELECT
  year ,Month,MonthName,Quarter,DATE_FORMAT(STR_TO_DATE(OrderDate, '%d-%m-%Y'), '%Y-%b') AS YearMonth,
  `Day of Week`,`Day Name`,dd.FinancialMonth,dd.FinancialQuater
  FROM Sales S JOIN DimDate dd ON S.OrderDate = dd.Date;
  
#4.Calculate the Sales amount uning the columns(unit price,order quantity,unit discount)
SELECT 
    dp.ProductName, 
    s.UnitPrice, 
    round(SUM(s.OrderQuantity),0) AS OrderQuantity,
    round(SUM(s.DiscountAmount),0) AS Discount,
    round(SUM((s.UnitPrice * s.OrderQuantity) - s.DiscountAmount),0) AS SalesAmount
FROM Sales s
JOIN DimProduct dp ON s.ProductKey = dp.ProductKey
GROUP BY dp.ProductName,s.unitprice
order by SalesAmount desc;
 
#5.Calculate the Productioncost using the columns(unit cost ,order quantity)

SELECT 
    dp.ProductName, 
    s.UnitPrice, 
    round(SUM(s.OrderQuantity),0) AS TotalOrderQuantity,
    round(SUM(s.TotalProductCost * s.OrderQuantity),0) AS ProductionCost
FROM Sales s
JOIN DimProduct dp ON s.ProductKey = dp.ProductKey
GROUP BY dp.ProductName, s.UnitPrice
ORDER BY ProductionCost DESC;

#6.Calculate the profit.
SELECT 
    dp.ProductName,
    round(sum(SalesAmount),0) as SalesAmount,
    round(SUM(totalproductcost),0)  AS TotalProductCost,
    round((sum(SalesAmount)- sum(TotalProductCost)),0) AS Profit
FROM Sales s
JOIN DimProduct dp ON s.ProductKey = dp.ProductKey
GROUP BY dp.ProductName
ORDER BY Profit DESC;

#7,9.a table for month and sales 

SELECT 
    DimDate.Year,
    DimDate.MonthName,
    round(SUM(Sales.SalesAmount),0) AS TotalSales
FROM Sales
JOIN DimDate ON Sales.OrderDate = DimDate.Date
GROUP BY DimDate.Year, DimDate.MonthName,dimdate.Month
ORDER BY DimDate.Year, DimDate.Month ;

#8.yearwise sales
SELECT 
    DimDate.Year,
    round(SUM(Sales.SalesAmount),0) AS TotalSales
FROM Sales
JOIN DimDate ON Sales.OrderDate = DimDate.Date
GROUP BY DimDate.Year
ORDER BY totalsales desc;

#10.to show Quarterwise sales(yearwise-quarterwise)
SELECT 
    dimdate.year,
    DimDate.Quarter,
    round(SUM(Sales.SalesAmount),0) AS TotalSales
FROM Sales
JOIN DimDate ON Sales.OrderDate = DimDate.Date
GROUP BY dimdate.year, DimDate.Quarter
ORDER BY dimdate.year,dimdate.Quarter;

#11.a chart to show Salesamount and Productioncost together

SELECT 
    dp.ProductName,
    round(SUM(TotalProductCost),0) AS ProductionCost,
    round(SUM(SalesAmount),0) AS SalesAmount
FROM Sales s
JOIN DimProduct dp ON s.ProductKey = dp.ProductKey
GROUP BY dp.ProductName
ORDER BY SalesAmount DESC;

#12.build additional KPIs

#1 total products
SELECT COUNT(DISTINCT ProductKey) AS TotalProducts
FROM DimProduct;

#2 Total revenue, production cost,profit
select Round(SUM(totalproductcost * OrderQuantity),0) AS ProductionCost,
	   round(SUM((sales.UnitPrice * OrderQuantity) - DiscountAmount),0) AS Revenue,
       round((sum(SalesAmount)- sum(TotalProductCost)),0) AS Profit
       FROM sales;

#3 sales amount, production cost, profit by country 
SELECT 
    st.SalesTerritoryCountry as Country,
    ROUND(SUM(salesamount), 0) AS SalesAmount,
    ROUND(SUM(totalproductcost), 0) AS ProductionCost,
    ROUND(SUM(salesamount) - SUM(totalproductcost), 0) AS Profit
FROM Sales s
JOIN dimsalesterritory st ON s.SalesTerritoryKey = st.SalesTerritoryKey
GROUP BY st.SalesTerritoryCountry
ORDER BY Profit DESC;

#4 Top 10 customers by sales
select distinct count(customerKey) as Customers from dimcustomer;

SELECT 
    c.CustomerName,
    ROUND(SUM(salesAmount)) AS SalesAmount
FROM Sales s
JOIN dimcustomer c ON s.CustomerKey = c.CustomerKey
GROUP BY c.CustomerName
ORDER BY SalesAmount DESC
LIMIT 10;

#5 merging 3 product tables into 1
CREATE TABLE Products AS 
SELECT * FROM DimProduct;

ALTER TABLE Products
ADD ProductSubCategoryName VARCHAR(50),
ADD ProductCategoryName VARCHAR(50);

UPDATE Products P
JOIN DimProductSubCategory SC ON P.ProductSubCategoryKey = SC.ProductSubCategoryKey
JOIN DimProductCategory C ON SC.ProductCategoryKey = C.ProductCategoryKey
SET P.ProductSubCategoryName = SC.ProductSubCategoryName,
    P.ProductCategoryName = C.ProductCategoryName;
    
select * from products;
    
#6 sales by category
SELECT 
    p.productcategoryname,
    round(SUM(s.SalesAmount),0) AS TotalSales
FROM Products p
JOIN Sales s ON p.ProductKey = s.ProductKey
GROUP BY productcategoryname
ORDER BY TotalSales DESC;







