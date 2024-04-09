
INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD001', 'T-Shirt', 'Brand X', 101, 5.99, 9.99, 20);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD002', 'Jeans', 'Brand Y', 102, 14.99, 24.99, 10);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD003', 'Laptop', 'Brand Z', 103, 499.99, 749.99, 5);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD004', 'Coffee Mug', 'Brand M', 104, 2.99, 4.99, 30);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD005', 'Book', 'Kim Dong', 105, 2.99, 4.99, 30);



-- insert warehosue
INSERT INTO Warehouse (WID, WName, WAddress)
VALUES (1, 'Main Warehouse', '123 Main St, Anytown, CA 12345');

INSERT INTO Warehouse (WID, WName, WAddress)
VALUES (2, 'West Coast Warehouse', '456 Elm St, Los Angeles, CA 54321');


-- insert supplier
INSERT INTO Supplier (SupplierID, SupplierName, SupplierContact, SupplierAddress)
VALUES (101, 'Clothing Company', 'sales@clothingcompany.com', '789 Maple St, New York, NY 98765');

INSERT INTO Supplier (SupplierID, SupplierName, SupplierContact, SupplierAddress)
VALUES (102, 'Jeans Manufacturer', 'info@jeansmanufacturer.com', '012 Oak St, Chicago, IL 87654');

INSERT INTO Supplier (SupplierID, SupplierName, SupplierContact, SupplierAddress)
VALUES (103, 'Electronics Wholesaler', 'orders@electronicswholesaler.com', '345 Pine St, Houston, TX 76543');

INSERT INTO Supplier (SupplierID, SupplierName, SupplierContact, SupplierAddress)
VALUES (104, 'Mugs Inc.', 'customerservice@mugsinc.com', '678 Birch St, Miami, FL 65432');


-- insert product_warehouse
INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (1, 'PRD001', 100 );

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (1, 'PRD002', 50);

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (1, 'PRD004', 200);

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (2, 'PRD003', 15);

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (2, 'PRD004', 15);

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (2, 'PRD002', 0);

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (1, 'PRD003', 50);


-- Insert data assuming an order from Warehouse 2 for Laptop (PRD003) from Supplier 103, dated 2024-04-04 with a quantity of 10
INSERT INTO Product_Order (OrderID, WID, PID, SupplierID, OrderDate, OrderQuantity)
VALUES (1, 2, 'PRD003', 103, '2024-04-04', 10);

-- Insert more data following the same format, replacing values with your specific orders
INSERT INTO Product_Order (OrderID, WID, PID, SupplierID, OrderDate, OrderQuantity)
VALUES (2, 1, 'PRD001', 101, '2024-04-06', 25);


INSERT INTO Type (TID, TName)
VALUES (1, 'Clothing');

-- Insert data for Electronics category
INSERT INTO Type (TID, TName)
VALUES (2, 'Electronics');

-- Insert more data for other product categories as needed
INSERT INTO Type (TID, TName)
VALUES (3, 'Kitchenware');

INSERT INTO Type(TID, TName)
VALUES (4,'Education');
-- ... and so on

-- INSERT INTO Product_Category table
-- Link T-Shirt (PRD001) to Clothing category (TID 1)
INSERT INTO Product_Category (PID, TID)
VALUES ('PRD001', 1);

-- Link Jeans (PRD002) to Clothing category (TID 1)
INSERT INTO Product_Category (PID, TID)
VALUES ('PRD002', 4);

-- Link Laptop (PRD003) to Electronics category (TID 2)
INSERT INTO Product_Category (PID, TID)
VALUES ('PRD003', 2);

-- Link Coffee Mug (PRD004) to Kitchenware category (assuming TID 3 exists)
INSERT INTO Product_Category (PID, TID)
VALUES ('PRD004', 3);

-- INSERT INTO Export table
-- Insert data assuming an export of 20 T-Shirts (PRD001) from Warehouse 1 (WID 1) with a unique export ID (EID) and current date
INSERT INTO Export (EID, WID, PID, ExportQuantity, ExportDate)
VALUES ('EXP001', 1, 'PRD001', 20, current_date);

-- Insert data for another export of 5 Laptops (PRD003) from Warehouse 2 (WID 2) with a different EID and date
INSERT INTO Export (EID, WID, PID, ExportQuantity, ExportDate)
VALUES ('EXP002', 2, 'PRD003', 5, '2024-04-02');

INSERT INTO Export (EID, WID, PID, ExportQuantity, ExportDate)
VALUES ('EXP003', 2, 'PRD003', 12, '2024-05-02');

INSERT INTO Export (EID, WID, PID, ExportQuantity, ExportDate)
VALUES ('EXP004', 2, 'PRD001', 10, '2024-05-10');

INSERT INTO Export (EID, WID, PID, ExportQuantity, ExportDate)
VALUES ('EXP005', 1, 'PRD002', 5, '2024-05-09');

INSERT INTO Export (EID, WID, PID, ExportQuantity, ExportDate)
VALUES ('EXP006', 1, 'PRD003', 5, '2024-04-02');

INSERT INTO Export (EID, WID, PID, ExportQuantity, ExportDate)
VALUES ('EXP007', 1, 'PRD004', 5, '2024-04-09');