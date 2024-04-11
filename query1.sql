CREATE TABLE Product (
                         PID varchar(100) PRIMARY KEY,
                         Pname varchar(100) NOT NULL,
                         Brand varchar(100),
                         SupplierID int,
                         CostPrice decimal(5,2),
                         UnitPrice decimal(5,2),
                         MinimumStockLevel int,
                         FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

CREATE TABLE Warehouse (
                           WID int PRIMARY KEY,
                           WName varchar(100) NOT NULL,
                           WAddress varchar(255) NOT NULL
);

-- Create Supplier table (optional)
CREATE TABLE Supplier (
                          SupplierID int PRIMARY KEY NOT NULL,
                          SupplierName varchar(100) NOT NULL,
                          SupplierContact varchar(255),
                          SupplierAddress varchar(255)
);




-- Improved Inventory table (separated from Warehouse)
CREATE TABLE Product_Warehouse (
                                   WID int ,
                                   PID varchar(100) ,
                                   Quantity int NOT NULL,
                                   LastUpdatedDate VARCHAR(200),
                                   LastUpdatedTime VARCHAR(200),
                                   Status varchar(100) ,
                                   FOREIGN KEY(WID) REFERENCES Warehouse(WID),
                                   FOREIGN KEY(PID) REFERENCES Product(PID),
                                   PRIMARY KEY (WID, PID)
);



-- Create Order table
CREATE TABLE Product_Order (
                               OrderID int ,
                               WID int ,
                               PID varchar(100) ,
                               SupplierID int ,
                               Order_Detail_ID int, -- THIS IS THE Order_ID in the Table Order_Detail
                               FOREIGN KEY(WID) REFERENCES Warehouse(WID),
                               FOREIGN KEY(PID) REFERENCES Product(PID),
                               FOREIGN KEY(SupplierID) REFERENCES Supplier(SupplierID) ,
                               FOREIGN KEY (Order_Detail_ID) REFERENCES Order_Detail(Order_ID),
                               OrderDate varchar(200),
                               OrderQuantity int
);

CREATE OR REPLACE FUNCTION auto_increment_order_id() RETURNS TRIGGER AS $$
DECLARE
    current_id INT;
BEGIN
    SELECT COALESCE(MAX(OrderID), 0) + 1 INTO current_id
    FROM Product_Order;

    IF current_id IS NULL THEN  -- Handle first record case
        NEW.OrderID := 1;
    ELSE
        NEW.OrderID := current_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_increment_order_id
    BEFORE INSERT ON Product_Order
    FOR EACH ROW EXECUTE PROCEDURE auto_increment_order_id();

drop trigger auto_increment_order_id ON Product_Order

drop table Product_Order;

CREATE TABLE Order_Detail(
    Order_ID  int,
    SupplierName varchar(200),
    Order_Detail_Date varchar(200),
    PRIMARY KEY (Order_ID)
);

INSERT INTO Order_Detail(SupplierName,Order_Detail_Date) VALUES ('A','2024/04/11');
select * from Order_Detail;

INSERT INTO Product_Order ( WID, PID, SupplierID,Order_Detail_ID, OrderQuantity)
VALUES ( 2, 'PRD002', 103,1, 12);
INSERT INTO Product_Order ( WID, PID, SupplierID,Order_Detail_ID, OrderQuantity)
VALUES ( 2, 'PRD003', 103,1, 12);
INSERT INTO Product_Order ( WID, PID, SupplierID,Order_Detail_ID, OrderQuantity)
VALUES ( 2, 'PRD003', 103,2, 12);
SELECT * FROM Product_Order WHERE ;
truncate table Order_Detail;
truncate table Product_Order;
----------
CREATE OR REPLACE FUNCTION auto_increment_order_id() RETURNS TRIGGER AS $$
DECLARE
    current_id INT;
BEGIN
    SELECT COALESCE(MAX(Order_ID), 0) + 1 INTO current_id
    FROM Order_Detail;

    IF current_id IS NULL THEN  -- Handle first record case
        NEW.Order_ID := 1;
    ELSE
        NEW.Order_ID := current_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_increment_order_id
    BEFORE INSERT ON Order_Detail
    FOR EACH ROW EXECUTE PROCEDURE auto_increment_order_id();

--------------------------------------

CREATE OR REPLACE FUNCTION update_order_date() RETURNS TRIGGER AS $$
BEGIN
    NEW.OrderDate := TO_CHAR(NOW(), 'DD/MM/YYYY');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_date_after_insert
    BEFORE INSERT ON Product_Order
    FOR EACH ROW EXECUTE PROCEDURE update_order_date();




SELECT to_char(Order_Detail_Date , 'DD/MM/YYYY') , Order_Detail.Order_ID , Order_Detail.SupplierName FROM Order_Detail;

SELECT*FROM Order_Detail;

INSERT INTO Order_Detail (Order_Detail_ID, SupplierName, Order_Detail_Date)
VALUES (1, 'Supplier A', '2024-04-12'),
       (2, 'Supplier B', '2024-04-10');

select * from Order_Detail


--------------------------- create table Order_Infor

 drop table Order_Infor;
 drop trigger auto_increment_order_id;

CREATE OR REPLACE FUNCTION auto_increment_order_id() RETURNS TRIGGER AS $$
DECLARE
    next_id VARCHAR(10);
BEGIN
    SELECT INTO next_id CONCAT('ORD  ', COALESCE(MAX(SUBSTRING(SpecificOrderIdForEachOrder, 5)), 0) + 1)
    FROM Order_Infor;

    NEW.SpecificOrderIdForEachOrder := next_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_increment_order_id
    BEFORE INSERT ON Order_Infor
    FOR EACH ROW EXECUTE PROCEDURE auto_increment_order_id();
---------------------------------------------------------------------------------------------------
-- CREATE TRIGGER AUTO CREATE THE Order_Infor table after finish order all of Product in specific OrderID from Product_Order
CREATE OR REPLACE FUNCTION update_order_infor() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Order_Infor
    SET OrderIDOfEachGeneralOrder = NEW.OrderID
    WHERE SpecificOrderIdForEachOrder = (SELECT SpecificOrderIdForEachOrder FROM order_infor);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_infor_after_insert
    AFTER INSERT ON Product_Order
    FOR EACH ROW EXECUTE PROCEDURE update_order_infor();


---------------------

CREATE TABLE Type (
                      TID int,
                      TName varchar (100),
                      PRIMARY KEY (TID)
);





-- Improved Product_category table (reduced redundancy)
CREATE TABLE Product_Category (
                                  PID varchar(100) ,
                                  TID int ,
                                  FOREIGN KEY(PID) REFERENCES Product(PID),
                                  FOREIGN KEY (TID) REFERENCES Type(TID),
                                  PRIMARY KEY (PID, TID)
);

-- Improved In_transition table (renamed, uses separate source and destination)
CREATE TABLE Product_Transfer (  -- Renamed for clarity
                                  SourceWID int,
                                  DestinationWID int ,
                                  PID varchar(100) ,
                                  TransferDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  TransferQuantity int NOT NULL,
                                  FOREIGN KEY(SourceWID) REFERENCES Warehouse(WID),
                                  FOREIGN KEY(DestinationWID) REFERENCES Warehouse(WID),
                                  FOREIGN KEY(PID) REFERENCES Product(PID),
                                  PRIMARY KEY (SourceWID, DestinationWID, PID, TransferDate)  -- Composite key
);

CREATE TABLE Export(
                       WID int,
                       PID varchar(100),
                       EID varchar(100),
                       ExportQuantity int,
                       ExportDate varchar(200),
                       PRIMARY KEY(EID),
                       FOREIGN KEY(PID) REFERENCES Product(PID),
                       FOREIGN KEY (WID) REFERENCES Warehouse(WID)
);


drop table Export
-- CREATE TRIGGER TO UPDATE THE CurrentQuantity in table Product_Warehouse
CREATE OR REPLACE FUNCTION update_product_warehouse_quantity_when_re_order()
    RETURNS trigger AS $$
DECLARE Old_Quantity int;
    DECLARE Sold_Quantity int;
BEGIN
    IF tg_op = 'UPDATE' THEN
        BEGIN
            SELECT quantity INTO Old_Quantity FROM Product_Warehouse WHERE PID = NEW.PID AND WID = NEW.WID;
        EXCEPTION WHEN NO_DATA_FOUND THEN   RAISE EXCEPTION 'Product not found in warehouse. Update or insert required.';
        END;
        UPDATE Product_Warehouse
        SET LastUpdated = current_timestamp,
            Quantity = Old_Quantity + NEW.Quantity
        WHERE PID = NEW.PID AND WID = NEW.WID;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_warehouse_quantity
    AFTER UPDATE ON Product_Warehouse
    FOR EACH ROW
EXECUTE PROCEDURE update_product_warehouse_quantity_when_re_order();


-- CREATE TRIGGER TO UPDATE THE STATUS AND  THE LAST DATE TO UPDATE TO Product_Warehouse table
CREATE OR REPLACE FUNCTION update_product_warehouse_status()
    RETURNS trigger AS $$
    DECLARE CurrentTime varchar(100);
BEGIN
        SELECT LastUpdatedDate INTO CurrentTime FROM Product_Warehouse WHERE WID = NEW.WID AND PID = NEW.PID;
        IF CurrentTime IS  NULL THEN
            IF NEW.Quantity <= 0 THEN
                UPDATE Product_Warehouse
                SET status = 'Out of Stock', LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY') ,LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
                WHERE PID = NEW.PID AND WID = NEW.WID;
            ELSEIF NEW.Quantity < (SELECT minimumStockLevel FROM Product WHERE Product.PID = NEW.PID) THEN
                UPDATE Product_Warehouse
                SET status = 'Low Stock' , LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY') ,LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
                WHERE PID = NEW.PID AND WID = NEW.WID;
            ELSE
                UPDATE Product_Warehouse
                SET status = 'In Stock', LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY') ,LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
                WHERE PID = NEW.PID AND WID = NEW.WID;
            END IF;
       ELSE
            IF NEW.Quantity <= 0 THEN
                UPDATE Product_Warehouse
                SET status = 'Out of Stock', LastUpdatedDate = CurrentTime ,LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
                WHERE PID = NEW.PID AND WID  = NEW.WID;
            ELSEIF new.Quantity < 10 THEN
                UPDATE Product_Warehouse
                SET status = 'Low Stock',  LastUpdatedDate = CurrentTime ,LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
                WHERE PID = NEW.PID AND WID  = NEW.WID;
            ELSE
                UPDATE Product_Warehouse
                SET status = 'In Stock',  LastUpdatedDate = CurrentTime ,LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
                WHERE PID = NEW.PID AND WID  = NEW.WID;
            end if;
        end if;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_warehouse_status
    AFTER INSERT ON Product_Warehouse
    FOR EACH ROW
EXECUTE PROCEDURE update_product_warehouse_status();

DROP TRIGGER trigger_update_warehouse_status ON product_warehouse

-- CREATE TRIGGER TO DELETE the corresponding the number of Product has been orderd by customer from the table Product_Warehouse.

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD001', 'T-Shirt', 'Brand X', 101, 5.99, 9.99, 20);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD002', 'Jeans', 'Brand Y', 102, 14.99, 24.99, 10);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD003', 'Laptop', 'Brand Z', 103, 499.99, 749.99, 5);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD004', 'Coffee Mug', 'Brand M', 104, 2.99, 4.99, 30);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD005', 'Book', 'Mug Inc', 104, 2.99, 4.99, 30);



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

select * from Product_Warehouse
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

INSERT INTO Product_Warehouse(WID , PID , Quantity, LastUpdatedDate)
VALUES (1,'PRD005',50, format_date(TO_DATE('2024-03-12', 'YYYY-MM-DD')));

INSERT INTO Product_Warehouse(WID , PID , Quantity, LastUpdatedDate)
VALUES (2,'PRD005',50, TO_DATE('2024-03-12', 'YYYY-MM-DD'));

truncate table Product_Warehouse
select * from Product_Warehouse

SELECT Product.PID , Product.PName , Type.TypeName


CREATE OR REPLACE FUNCTION format_date(date_input DATE)
    RETURNS VARCHAR
AS $$
BEGIN
    -- Extract day, month, year components
    RETURN (TO_CHAR(date_input, 'DD') || '/' || TO_CHAR(date_input, 'MM') || '/' || TO_CHAR(date_input, 'YYYY'));
END;
$$ LANGUAGE plpgsql;


-- Insert data assuming an order from Warehouse 2 for Laptop (PRD003) from Supplier 103, dated 2024-04-04 with a quantity of 10
INSERT INTO Product_Order (OrderID, WID, PID, SupplierID, OrderDate, OrderQuantity)
VALUES (1, 2, 'PRD003', 103, '2024-04-04', 10);

-- Insert more data following the same format, replacing values with your specific orders
INSERT INTO Product_Order (OrderID, WID, PID, SupplierID, OrderDate, OrderQuantity)
VALUES (2, 1, 'PRD001', 101, '2024-04-06', 25);
INSERT INTO Product_Order (OrderID, WID, PID, SupplierID, OrderDate, OrderQuantity)
VALUES (2, 1, 'PRD002', 101, '2024-04-06', 25);

insert into Order_Detail('Mugs INC' ,  )
INSERT INTO Product_Order ( WID, PID, SupplierID,Order_Detail_ID, OrderQuantity)
VALUES ( 2, 'PRD004', 103,1, 10);
INSERT INTO Product_Order ( WID, PID, SupplierID,Order_Detail_ID, OrderQuantity)
VALUES ( 2, 'PRD002', 103,1, 12);


SELECT * FROM Product_Order;
TRUNCATE TABLE Product_Order;

-- ... and so on

SELECT * FROM Product_Warehouse;
truncate table Product_Warehouse;
select*from Product;


                  -- TEST TIME FOR Time update Product_Warehouse table
-- SELECT NOW() AT TIME ZONE 'GMT+7'
-- SELECT LOCALTIMESTAMP(5) AT TIME ZONE 'GMT+7'
-- select date_trunc('second', LOCALTIMESTAMP(2) AT TIME ZONE 'GMT+7')
-- SELECT to_char(date_trunc('second', LOCALTIMESTAMP AT TIME ZONE 'GMT+7'), 'DD/MM/YYYY') AS truncated_datetime;
-- SELECT to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY HH24:MI:SS') AS current_datetime;


                  -- Insert data for Clothing categoryee
                  -- INSERT TO Type table
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
select * from Product_Warehouse
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
SELECT * FROM Export

SELECT
    ExportDate
FROM Export as E JOIN Product P on E.PID = P.PID

------------------------------------------------------
CREATE TABLE DimDay(
    DATE_IN_MONTH varchar(200)
);

CREATE OR REPLACE FUNCTION Update_Date_In_Month ()
LANGUAGE plpgsql
AS $$

$$;



-- Count total order of specific warehouse order by all months
    SELECT TO_CHAR(ExportDate ,'month') as Month, count(DISTINCT EID) as Total_Order FROM Export
    WHERE WID = 1
   -- GROUP BY DATE_TRUNC('month', ExportDate)
      GROUP BY TO_CHAR(ExportDate ,'month')
   -- ORDER BY DATE_TRUNC('month',ExportDate) ASC ;
       ORDER BY TO_CHAR(ExportDate,'month') desc ;


-- Count total order of all warehouse order by all  months
SELECT TO_CHAR(ExportDate ,'month') as Month, count(DISTINCT EID) as Total_Order FROM Export
GROUP BY TO_CHAR(ExportDate ,'month')
ORDER BY TO_CHAR(ExportDate ,'month') asc ;


-- Count total order of all warehouse order by each month
SELECT TO_CHAR(current_timestamp, 'Month') AS Current_Month,
       COUNT(*) AS Total_Orders_Current_Month
FROM Export
WHERE WID =1  AND  EXTRACT(MONTH FROM current_timestamp) = EXTRACT(MONTH FROM Export.ExportDate)
GROUP BY TO_CHAR(current_timestamp, 'Month');

select * from export;

-- calculate sale from all
CREATE OR REPLACE PROCEDURE Total_Order_By_Month_Of_Specific_Warehouse(NeededWID int)
    LANGUAGE plpgsql
AS $$
DECLARE
    Total_Orders_Current_Month int := 0;
BEGIN

    SELECT COUNT(*) INTO Total_Orders_Current_Month
    FROM Export
    WHERE WID = NeededWID
      AND EXTRACT(MONTH FROM ExportDate) = EXTRACT(MONTH FROM current_timestamp)
      AND EXTRACT(YEAR FROM ExportDate) = EXTRACT(YEAR FROM current_timestamp);
END;
$$;

DROP PROCEDURE Total_Order_By_Month_Of_Specific_Warehouse(NeededWID int);
CALL Total_Order_By_Month_Of_Specific_Warehouse(2);

------------------------------------------------------------
CALL Total_Order_By_Month_Of_Specific_Warehouse(1);
SELECT * FROM Total_Order_By_Month_Of_Specific_Warehouse(1);
DROP PROCEDURE IF EXISTS Total_Order_By_Month_Of_Specific_Warehouse(int);

CREATE OR REPLACE FUNCTION Total_Order_By_Month_Of_Specific_Warehouse(NeededWID int)
    RETURNS int
    LANGUAGE plpgsql
AS $$
DECLARE
    Total_Orders_Current_Month int;
BEGIN
    SELECT COUNT(*) INTO Total_Orders_Current_Month
    FROM Export
    WHERE WID = NeededWID
      AND EXTRACT(MONTH FROM ExportDate) = EXTRACT(MONTH FROM current_timestamp)
      AND EXTRACT(YEAR FROM ExportDate) = EXTRACT(YEAR FROM current_timestamp);

    RETURN Total_Orders_Current_Month;
END;
$$;

DROP PROCEDURE Total_Order_By_Month_Of_Specific_Warehouse(NeededWID int)
----------------------------------------------------------

SELECT COUNT(*) AS total_types
FROM Type;

-- COUNT ALL OF TYPE BASED ON THE PRODUCT THAT WAREHOUSE HAS
SELECT COUNT(DISTINCT T.TID) AS total_tids_in_warehouse_1
FROM Product_Warehouse PW
         INNER JOIN Product_Category PC ON PW.PID = PC.PID
         INNER JOIN Type T ON PC.TID = T.TID
WHERE PW.WID = 1;

-- Count total product of SPECIFIC WAREHOUSE
    SELECT COUNT( DISTINCT Product_Warehouse.PID) as TotalProductOfSpecificWarehouse
    FROM Product_Warehouse
    WHERE WID = 2;

--Count total product of all warehouse
    SELECT COUNT(DISTINCT Product_Warehouse.PID) AS TotalProductOfAllWarehouses
    FROM Product_Warehouse;

-- SELECT ALL THE PRODUCT WITH STATUS IS ' LOW STOCK '
SELECT PID, Quantity,Status
FROM Product_Warehouse
WHERE COALESCE(Status, '') = 'Low Stock';

SELECT * FROM Product_Warehouse


TRUNCATE TABLE Product_Warehouse;
DROP TRIGGER trigger_update_warehouse_status ON Product_Warehouse;

-- CREATE TRIGGER
CREATE OR REPLACE PROCEDURE update_status_after_update(NEWPID varchar(100) , NewWID int, NEWQuantity int)
    LANGUAGE plpgsql
as $$
DECLARE CurrentQuantity int;
BEGIN
    SELECT Product_Warehouse.Quantity INTO CurrentQuantity FROM Product_Warehouse WHERE PID = NEWPID AND Product_Warehouse.WID = NEWWID;
    IF CurrentQuantity+NEWQuantity <= 0 THEN
        UPDATE Product_Warehouse
        SET Quantity = CurrentQuantity + NEWQuantity, status = 'Out of Stock', LastUpdatedDate= LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY') ,LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
        WHERE PID = NEWPID AND WID = NEWWID;
    ELSEIF CurrentQuantity+NEWQuantity < (SELECT minimumStockLevel FROM Product WHERE Product.PID = NEWPID) THEN
        UPDATE Product_Warehouse
        SET Quantity = CurrentQuantity + NEWQuantity, status = 'Low Stock' , LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY') ,LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
        WHERE PID = NEWPID AND WID = NEWWID;
    ELSE
        UPDATE Product_Warehouse
        SET Quantity = CurrentQuantity + NEWQuantity,status = 'In Stock',LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY') ,LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
        WHERE PID = NEWPID AND WID = NEWWID;
    END IF;
    COMMIT;
END; $$;



call update_status_after_update('PRD004' , 2 , 40);




--DROP PROCEDURE insert_reorder_product(NEWWID int, NEWPID varchar(100), NEWQuantity int)

DROP PROCEDURE update_status_after_update(NEWPID varchar(100), NewWID int, NEWQuantity int)

CREATE OR REPLACE PROCEDURE insert_to_Product_Category(NewPID varchar(100) , NewTypeName varchar(100))
LANGUAGE plpgsql
as $$
    DECLARE TypeName varchar(100);
    DECLARE NewTID int;
 BEGIN
     SELECT Type.TID INTO NewTID FROM Type WHERE TName = NewTypeName;
     INSERT INTO Product_Category(PID, TID) VALUES (NewPID , NewTID);
     commit;
end;
    $$;

call insert_to_Product_Category('PRD005','Education')

-- CREATE PROCEDURE Insert_Or_Reorder produce
CREATE OR REPLACE PROCEDURE insert_reorder_product(
    InputWarehouseName varchar(100),
    InputProductName varchar(100),
    NEWQuantity int
)
    LANGUAGE plpgsql
AS $$

BEGIN
    DECLARE
        existing_record RECORD;
        NeededPID varchar(100);
        NeededWID int;
    BEGIN
        -- Check if product exists in the warehouse
        -- SELECT PID WHICH SAME WITH CORRESPONDING PNAME TO INSERT / UPDATE TO Product_Warehouse table
        SELECT Product.PID INTO NeededPID from Product WHERE InputProductName = Product.Pname;
        SELECT Warehouse.WID INTO NeededWID from Warehouse WHERE InputWarehouseName = Warehouse.WName;
        SELECT *  -- Selects all columns from Product_Warehouse
        INTO existing_record
        FROM Product_Warehouse
        WHERE pid = NeededPID AND wid = NeededWID;

        IF FOUND THEN
            -- Update quantity and status based on existing record
            IF existing_record.quantity + NEWQuantity <= 0 THEN
                UPDATE Product_Warehouse
                SET quantity = quantity + NEWQuantity,
                    lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
                    lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS'), status = 'Out of Stock'
                WHERE PID = NeededPID AND WID = NeededWID;
            ELSIF existing_record.quantity + NEWQuantity < 10 THEN
                UPDATE Product_Warehouse
                SET quantity = quantity + NEWQuantity,
                    lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
                    lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS'), status = 'Low Stock'
                WHERE PID = NeededPID AND WID = NeededWID;
            ELSE
                UPDATE Product_Warehouse
                SET quantity = quantity + NEWQuantity,
                    lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
                    lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS'), status = 'In Stock'
                WHERE PID = NeededPID AND WID = NeededWID;
        END IF;
        ELSE
            -- Insert new record if product doesn't exist
            INSERT INTO Product_Warehouse(WID, PID, Quantity)
            VALUES (NeededWID, NeededPID, NEWQuantity);
        END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        -- Handle the case where no product is found (optional)
        RAISE NOTICE 'Insert new product to warehouse';
    END;
END;
$$;

drop procedure insert_reorder_product(InputWarehouseName varchar(100), InputProductName varchar(100), NEWQuantity int);
select* from Product;
select * from Warehouse;
select * from product_warehouse;
call insert_reorder_product('West Coast Warehouse','T-Shirt',50);
call insert_reorder_product('Main Warehouse','Jeans',50);
call insert_reorder_product('West Coast Warehouse','Book',50);
select * from Product_Warehouse;

--------------------------------
SELECT Product.Pname,Product_Warehouse.PID, Type.TName , Product.UnitPrice, Product_Warehouse.Status
FROM Product
         INNER JOIN Product_Warehouse ON Product.PID = Product_Warehouse.PID
         INNER JOIN Product_Category ON Product.PID = Product_Category.PID
         INNER JOIN Type ON Product_Category.TID = Type.TID;


-- CREATE SEQUENCE supplier_id_seq;
-- CREATE OR REPLACE FUNCTION auto_increment_supplier_id() RETURNS TRIGGER AS $$
-- BEGIN
--     IF NEW.SupplierID IS NULL THEN
--         NEW.SupplierID := nextval('supplier_id_seq');
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
--
-- CREATE TRIGGER auto_increment_supplier_id
--     BEFORE INSERT ON Supplier
--     FOR EACH ROW EXECUTE PROCEDURE auto_increment_supplier_id();

CREATE OR REPLACE FUNCTION auto_increment_supplier_id() RETURNS TRIGGER AS $$
DECLARE
    current_id INT;
BEGIN
    SELECT COALESCE(MAX(SupplierID), 0) + 1 INTO current_id
    FROM Supplier;

    IF current_id IS NULL THEN  -- Handle first record case
        NEW.SupplierID := 1;
    ELSE
        NEW.SupplierID := current_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_increment_supplier_id
    BEFORE INSERT ON Supplier
    FOR EACH ROW EXECUTE PROCEDURE auto_increment_supplier_id();


truncate table Product_Warehouse;
truncate table product;
TRUNCATE TABLE Supplier;
truncate table Type;
truncate table Product_Category;
INSERT INTO Supplier ( SupplierName, SupplierContact, SupplierAddress)
VALUES ('NGHIA INC.', 'customerservice@mugsinc.com', '678 Birch St, Miami, FL 65432');
INSERT INTO Supplier ( SupplierName, SupplierContact, SupplierAddress)
VALUES ('NGHIA INC.', 'customerservice@mugsinc.com', '679 Birch St, Miami, FL 65432');
INSERT INTO Supplier ( SupplierName, SupplierContact, SupplierAddress)
VALUES ('NGHI INC.', 'customerservice@mugsinc.com', '679 Birch St, Miami, FL 65432');
SELECT * FROM Supplier;



-----------------------------


CREATE OR REPLACE PROCEDURE update_status_quantity_of_warehouse_when_export_product(NEWWID varchar(100) , NEWPID int , NEWSoldQuantity int)
    LANGUAGE plpgsql
AS $$
    BEGIN
        DECLARE CurrentQuantity int;
            BEGIN
            SELECT Product_Warehouse.Quantity INTO CurrentQuantity FROM Product_Warehouse WHERE PID = NEWPID AND WID = NEWWID;
            IF CurrentQuantity-NEWSoldQuantity <= 0 THEN
                UPDATE Product_Warehouse
                SET Quantity = CurrentQuantity - NEWSoldQuantity,Status = 'Out of Stock' ,  lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
                    lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
                WHERE PID = NEWPID AND WID = NEWWID;
            end if;
        end;
    end;
    $$;

CALL update_product_warehouse_quantity_when_re_order();
DROP PROCEDURE insert_reorder_product(NEWWID int, NEWPID varchar(100), NEWQuantity int);
call insert_reorder_product(2,'PRD001',30);
call insert_reorder_product(2,'PRD001',30);
TRUNCATE TABLE Product_Warehouse;
select * from Product_Warehouse;
DROP TABLE Product_Warehouse;


SELECT COUNT(DISTINCT EID)
FROM Export;

-- find top selling in month '
SELECT COUNT(DISTINCT PID)
FROM Export
WHERE ExportQuantity > 10
  AND TO_CHAR(TO_DATE(ExportDate, 'YYYY-MM-DD'), 'YYYY-MM') = TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM');


-----------------------------------
SELECT DISTINCT Product.Pname FROM Product INNER JOIN Product_Warehouse
ON Product.PID = Product_Warehouse.PID and Product_Warehouse.Status = 'In Stock';



CREATE TABLE DIM_DATE (
                          date_key SERIAL PRIMARY KEY,
                          date DATE NOT NULL,
                          day INTEGER NOT NULL,
                          month INTEGER NOT NULL,
                          year INTEGER NOT NULL,
                          quarter INTEGER NOT NULL,
                          day_of_week INTEGER NOT NULL,
                          week_of_year INTEGER NOT NULL,
                          month_name TEXT NOT NULL,
                          day_name TEXT NOT NULL,
                          is_weekend BOOLEAN NOT NULL,
                          UNIQUE(date)
);

COMMENT ON COLUMN DIM_DATE.date IS 'Unique date value';
COMMENT ON COLUMN DIM_DATE.day IS 'Day of the month';
COMMENT ON COLUMN DIM_DATE.month IS 'Month of the year';
COMMENT ON COLUMN DIM_DATE.year IS 'Year';
COMMENT ON COLUMN DIM_DATE.quarter IS 'Quarter of the year';
COMMENT ON COLUMN DIM_DATE.day_of_week IS 'Day of the week, where 1=Sunday, 2=Monday, etc.';
COMMENT ON COLUMN DIM_DATE.week_of_year IS 'ISO week number of the year';
COMMENT ON COLUMN DIM_DATE.month_name IS 'Full month name';
COMMENT ON COLUMN DIM_DATE.day_name IS 'Full weekday name';
COMMENT ON COLUMN DIM_DATE.is_weekend IS 'Boolean flag indicating whether the day is a weekend';



SELECT cron.schedule(
               'PopulateDatesForNextYear', -- Job name
               '0 0 1 1 *', -- At 00:00 on 1st January
               $$
    INSERT INTO DIM_DATE (date, month, year)
    SELECT
      gs::DATE,
      EXTRACT(MONTH FROM gs)::INTEGER,
      EXTRACT(YEAR FROM gs)::INTEGER
    FROM generate_series(
      DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year',
      DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' + INTERVAL '1 year' - INTERVAL '1 day',
      '1 day'
    ) AS gs
  $$
       );




CREATE OR REPLACE FUNCTION update_Inventory_show_data()
    RETURNS trigger AS $$
BEGIN
    SELECT Product.PName, Product_Warehouse.PID, Type.TName, Product.UnitPrice, Product_Warehouse.Status
    FROM Product
             INNER JOIN Product_Warehouse ON Product.PID = Product_Warehouse.PID
             INNER JOIN Product_Category ON Product.PID = Product_Category.PID
             INNER JOIN Type ON Product_Category.TID = Type.TID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_warehouse_status
    AFTER INSERT OR UPDATE ON Product_Warehouse
    FOR EACH ROW
EXECUTE PROCEDURE update_Inventory_show_data();
