
--Q1. List top 5 customers by total order amount.
--Retrieve the top 5 customers who have spent the most across all sales orders. Show CustomerID, CustomerName, and TotalSpent.
SELECT TOP 5
    C.CustomerID,
    C.Name AS CustomerName,
    SUM(SO.TotalAmount) AS TotalSpent
FROM Customer C
JOIN SalesOrder SO
    ON C.CustomerID = SO.CustomerID
GROUP BY
    C.CustomerID,
    C.Name
ORDER BY TotalSpent DESC;


 --Q2. Number of Products Supplied by Each Supplier,
 --Since there is no direct Supplier → Product relationship, we count products purchased through Purchase Orders.

SELECT
    S.SupplierID,
    S.Name AS SupplierName,
    COUNT(DISTINCT POD.ProductID) AS ProductCount 
FROM Supplier S
JOIN PurchaseOrder PO
    ON S.SupplierID = PO.SupplierID
JOIN PurchaseOrderDetail POD
    ON PO.OrderID = POD.OrderID
GROUP BY
    S.SupplierID,
    S.Name
HAVING COUNT(DISTINCT POD.ProductID) > 10;

--Q3. Identify products that have been ordered but never returned.
--Show ProductID, ProductName, and total order quantity.
SELECT
    P.ProductID,
    P.Name AS ProductName,
    SUM(SOD.Quantity) AS TotalOrderQuantity
FROM Product P
JOIN SalesOrderDetail SOD
    ON P.ProductID = SOD.ProductID
WHERE P.ProductID NOT IN
(
    SELECT ProductID
    FROM ReturnDetail
)
GROUP BY
    P.ProductID,
    P.Name;


  --Q4. For each category, find the most expensive product.
--Display CategoryID, CategoryName, ProductName, and Price. Use a subquery to get the max price per category.


SELECT
    C.CategoryID,
    C.Name AS CategoryName,
    P.Name AS ProductName,
    P.Price
FROM Product P
JOIN Category C
    ON P.CategoryID = C.CategoryID
WHERE P.Price =
(
    SELECT MAX(P2.Price)
    FROM Product P2
    WHERE P2.CategoryID = P.CategoryID
);


--Q5. List all sales orders with customer name, product name, category, and supplier.For each sales order, display:
--OrderID, CustomerName, ProductName, CategoryName, SupplierName, and Quantity.

SELECT
    SO.OrderID,
    C.Name AS CustomerName,
    P.Name AS ProductName,
    CAT.Name AS CategoryName,
    S.Name AS SupplierName,
    SOD.Quantity
FROM SalesOrder SO
JOIN Customer C
    ON SO.CustomerID = C.CustomerID
JOIN SalesOrderDetail SOD
    ON SO.OrderID = SOD.OrderID
JOIN Product P
    ON SOD.ProductID = P.ProductID
JOIN Category CAT
    ON P.CategoryID = CAT.CategoryID
JOIN PurchaseOrderDetail POD
    ON P.ProductID = POD.ProductID
JOIN PurchaseOrder PO
    ON POD.OrderID = PO.OrderID
JOIN Supplier S
    ON PO.SupplierID = S.SupplierID;



--Q6. Find all shipments with details of warehouse, manager, and products shipped.Display:
--ShipmentID, WarehouseName, ManagerName, ProductName, QuantityShipped, and TrackingNumber.
SELECT
    SH.ShipmentID,
    L.Name AS WarehouseName,
    E.Name AS ManagerName,
    P.Name AS ProductName,
    SD.Quantity AS QuantityShipped,
    SH.TrackingNumber
FROM Shipment SH
JOIN Warehouse W
    ON SH.WarehouseID = W.WarehouseID
LEFT JOIN Employee E
    ON W.ManagerID = E.EmployeeID
LEFT JOIN Location L
    ON W.LocationID = L.LocationID
JOIN ShipmentDetail SD
    ON SH.ShipmentID = SD.ShipmentID
JOIN Product P
    ON SD.ProductID = P.ProductID;

--Q7. Find the top 3 highest-value orders per customer using RANK(). Display CustomerID, CustomerName, OrderID, and TotalAmount.
WITH CustomerOrderRank AS
(SELECT
        C.CustomerID,
        C.Name AS CustomerName,
        SO.OrderID,
        SO.TotalAmount,
        RANK() OVER
        (
            PARTITION BY C.CustomerID
            ORDER BY SO.TotalAmount DESC
        ) AS OrderRank
    FROM Customer C
    JOIN SalesOrder SO
        ON C.CustomerID = SO.CustomerID)
SELECT
    CustomerID,
    CustomerName,
    OrderID,
    TotalAmount
FROM CustomerOrderRank
WHERE OrderRank <= 3
ORDER BY CustomerID, TotalAmount DESC;



--Q8. For each product, show its sales history with the previous and next sales quantities (based on order date). Display ProductID, ProductName, OrderID, OrderDate, Quantity, PrevQuantity, and NextQuantity.
SELECT
    P.ProductID,
    P.Name AS ProductName,
    SO.OrderID,
    SO.OrderDate,
    SOD.Quantity,

    LAG(SOD.Quantity)
        OVER (
            PARTITION BY P.ProductID
            ORDER BY SO.OrderDate
        ) AS PrevQuantity,

    LEAD(SOD.Quantity)
        OVER (
            PARTITION BY P.ProductID
            ORDER BY SO.OrderDate
        ) AS NextQuantity

FROM Product P
JOIN SalesOrderDetail SOD
    ON P.ProductID = SOD.ProductID
JOIN SalesOrder SO
    ON SOD.OrderID = SO.OrderID
ORDER BY
    P.ProductID,
    SO.OrderDate;




  --  Q9. Create a view named vw_CustomerOrderSummary that shows for each customer:
--CustomerID, CustomerName, TotalOrders, TotalAmountSpent, and LastOrderDate.

CREATE VIEW vw_CustomerOrderSummary
AS
SELECT
    C.CustomerID,
    C.Name AS CustomerName,
    COUNT(SO.OrderID) AS TotalOrders,
    SUM(SO.TotalAmount) AS TotalAmountSpent,
    MAX(SO.OrderDate) AS LastOrderDate
FROM Customer C
LEFT JOIN SalesOrder SO
    ON C.CustomerID = SO.CustomerID
GROUP BY
    C.CustomerID,
    C.Name;
GO


SELECT * FROM vw_CustomerOrderSummary;



 --Q10. Stored Procedure sp_GetSupplierSales
--Calculates total sales of products supplied by a supplier.

CREATE PROCEDURE sp_GetSupplierSales
    @SupplierID INT
AS
BEGIN

    SELECT
        @SupplierID AS SupplierID,
        S.Name AS SupplierName,
        SUM(SOD.TotalAmount) AS TotalSalesAmount

    FROM Supplier S

    JOIN PurchaseOrder PO
        ON S.SupplierID = PO.SupplierID

    JOIN PurchaseOrderDetail POD
        ON PO.OrderID = POD.OrderID

    JOIN SalesOrderDetail SOD
        ON POD.ProductID = SOD.ProductID

    WHERE S.SupplierID = @SupplierID

    GROUP BY
        S.Name;

END
GO


EXEC sp_GetSupplierSales @SupplierID = 1;