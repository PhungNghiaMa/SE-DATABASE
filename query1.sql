CREATE TABLE Product (
                         PID varchar(100) PRIMARY KEY, -- sku
                         Pname varchar(100) NOT NULL, -- product name
                         SupplierName varchar(100), --
                         CostPrice decimal(5,2),
                         UnitPrice decimal(5,2),
                         FOREIGN KEY (SupplierName) REFERENCES Supplier(SupplierName)
);
---------------------------------------------------------------
CREATE TABLE Warehouse (
                           WName varchar(100) NOT NULL,
                           WAddress varchar(255) NOT NULL,
                           PRIMARY KEY(WName)
);
--------------------------------------------------------------
-- Create Supplier table (optional)
CREATE TABLE Supplier (
                          SupplierName  varchar(100) NOT NULL,
                          SupplierContact varchar(255),
                          SupplierAddress varchar(255),
                         PRIMARY KEY (SupplierName)
);

--------------------------------------------------------------------

-- Improved Inventory table (separated from Warehouse)
CREATE TABLE Product_Warehouse (
                                   WName varchar(200) ,
                                   PID varchar(100) ,
                                   Quantity int NOT NULL,
                                   LastUpdatedDate VARCHAR(200),
                                   LastUpdatedTime VARCHAR(200),
                                   Status varchar(100) ,
                                   FOREIGN KEY(WName) REFERENCES Warehouse(WName),
                                   FOREIGN KEY(PID) REFERENCES Product(PID),
                                   PRIMARY KEY (WName, PID)
);

------------------------------------------------------------------------------
-- Create Order table
CREATE TABLE Product_Order (
                               OrderID serial ,
                               PID varchar(100),
                               ProductName varchar(100),
                               SupplierName varchar(100),
                               WarehouseName varchar(100),
                               Order_Detail_ID int, -- THIS IS THE Order_ID in the Table Order_Detail
                               OrderDate varchar(200),
                               OrderQuantity int,
                               FOREIGN KEY(WarehouseName) REFERENCES Warehouse(WName),
                               FOREIGN KEY(PID) REFERENCES Product(PID),
                               FOREIGN KEY(SupplierName) REFERENCES Supplier(SupplierName) ,
                               FOREIGN KEY (Order_Detail_ID) REFERENCES Order_Detail(CodeOrder),
                              
);

--------------------------------
CREATE TABLE Type (
                      TID int,
                      TName varchar (100),
                      PRIMARY KEY (TID)
);

---------------------------------

CREATE TABLE Product_Category (
                                  PID varchar(100) ,
                                  TID int ,
                                  FOREIGN KEY(PID) REFERENCES Product(PID),
                                  FOREIGN KEY (TID) REFERENCES Type(TID),
                                  PRIMARY KEY (PID, TID)
);
--------------------------------------

CREATE TABLE Order_Detail(
    CodeOrder  serial,
    SupplierName varchar(200),
    Order_Detail_Date varchar(200),
    PRIMARY KEY (CodeOrder)
);

---------------------------------------------------------------------------------------------------

-- Improved In_transition table (renamed, uses separate source and destination)
-- CREATE TABLE Product_Transfer (  -- Renamed for clarity
--                                   SourceWID int,
--                                   DestinationWID int ,
--                                   PID varchar(100) ,
--                                   TransferDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
--                                   TransferQuantity int NOT NULL,
--                                   FOREIGN KEY(SourceWID) REFERENCES Warehouse(WID),
--                                   FOREIGN KEY(DestinationWID) REFERENCES Warehouse(WID),
--                                   FOREIGN KEY(PID) REFERENCES Product(PID),
--                                   PRIMARY KEY (SourceWID, DestinationWID, PID, TransferDate)  -- Composite key
-- );
-----------------------------------------------------------------------------------------------------------------

-- CREATE TABLE Export(
--                        WName int,
--                        PID varchar(100),
--                        EID varchar(100),
--                        ExportQuantity int,
--                        ExportDate varchar(200),
--                        PRIMARY KEY(EID),
--                        FOREIGN KEY(PID) REFERENCES Product(PID),
--                        FOREIGN KEY (WName) REFERENCES Warehouse(WName)
-- );
---------------------------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------------------------------------------

-- CREATE OR REPLACE FUNCTION format_date(date_input DATE)
--     RETURNS VARCHAR
-- AS $$
-- BEGIN
--     -- Extract day, month, year components
--     RETURN (TO_CHAR(date_input, 'DD') || '/' || TO_CHAR(date_input, 'MM') || '/' || TO_CHAR(date_input, 'YYYY'));
-- END;
-- $$ LANGUAGE plpgsql;




------------------------------------------------------
-- CREATE OR REPLACE FUNCTION Update_Date_In_Month ()
-- LANGUAGE plpgsql
-- AS $$

-- $$;



-- -- Count total order of specific warehouse order by all months
--     SELECT TO_CHAR(ExportDate ,'month') as Month, count(DISTINCT EID) as Total_Order FROM Export
--     WHERE WID = 1
--    -- GROUP BY DATE_TRUNC('month', ExportDate)
--       GROUP BY TO_CHAR(ExportDate ,'month')
--    -- ORDER BY DATE_TRUNC('month',ExportDate) ASC ;
--        ORDER BY TO_CHAR(ExportDate,'month') desc ;


-- -- Count total order of all warehouse order by all  months
-- SELECT TO_CHAR(ExportDate ,'month') as Month, count(DISTINCT EID) as Total_Order FROM Export
-- GROUP BY TO_CHAR(ExportDate ,'month')
-- ORDER BY TO_CHAR(ExportDate ,'month') asc ;


-- -- Count total order of all warehouse order by each month
-- SELECT TO_CHAR(current_timestamp, 'Month') AS Current_Month,
--        COUNT(*) AS Total_Orders_Current_Month
-- FROM Export
-- WHERE WID =1  AND  EXTRACT(MONTH FROM current_timestamp) = EXTRACT(MONTH FROM Export.ExportDate)
-- GROUP BY TO_CHAR(current_timestamp, 'Month');

-- select * from export;

-- -- calculate sale from all
-- CREATE OR REPLACE PROCEDURE Total_Order_By_Month_Of_Specific_Warehouse(NeededWID int)
--     LANGUAGE plpgsql
-- AS $$
-- DECLARE
--     Total_Orders_Current_Month int := 0;
-- BEGIN

--     SELECT COUNT(*) INTO Total_Orders_Current_Month
--     FROM Export
--     WHERE WID = NeededWID
--       AND EXTRACT(MONTH FROM ExportDate) = EXTRACT(MONTH FROM current_timestamp)
--       AND EXTRACT(YEAR FROM ExportDate) = EXTRACT(YEAR FROM current_timestamp);
-- END;
-- $$;

------------------------------------------------------------

-- CREATE OR REPLACE FUNCTION Total_Order_By_Month_Of_Specific_Warehouse(NeededWID int)
--     RETURNS int
--     LANGUAGE plpgsql
-- AS $$
-- DECLARE
--     Total_Orders_Current_Month int;
-- BEGIN
--     SELECT COUNT(*) INTO Total_Orders_Current_Month
--     FROM Export
--     WHERE WID = NeededWID
--       AND EXTRACT(MONTH FROM ExportDate) = EXTRACT(MONTH FROM current_timestamp)
--       AND EXTRACT(YEAR FROM ExportDate) = EXTRACT(YEAR FROM current_timestamp);

--     RETURN Total_Orders_Current_Month;
-- END;
-- $$;

----------------------------------------------------------
-- COUNT ALL OF PRODUCT_CATEGORY IN ALL WAREHOUSEE
SELECT COUNT(*) AS total_types
FROM Type;
------------------------------------------------------------
-- COUNT ALL OF TYPE BASED ON THE PRODUCT THAT WAREHOUSE HAS
SELECT COUNT(DISTINCT T.TID) AS total_tids_in_warehouse_1
FROM Product_Warehouse PW
         INNER JOIN Product_Category PC ON PW.PID = PC.PID
         INNER JOIN Type T ON PC.TID = T.TID
WHERE PW.WID = 1;
----------------------------------------------------------------
-- Count total product of SPECIFIC WAREHOUSE
    SELECT COUNT( DISTINCT Product_Warehouse.PID) as TotalProductOfSpecificWarehouse
    FROM Product_Warehouse
    WHERE WID = 2;
-------------------------------------------------------------------------
--Count total product of all warehouse
    SELECT COUNT(DISTINCT Product_Warehouse.PID) AS TotalProductOfAllWarehouses
    FROM Product_Warehouse;
-----------------------------------------------------------
-- SELECT ALL THE PRODUCT WITH STATUS IS ' LOW STOCK '
SELECT PID, Quantity,Status
FROM Product_Warehouse
WHERE COALESCE(Status, '') = 'Low Stock';



-----------------------------------------------------
SELECT Type.TID INTO NewTID FROM Type WHERE TName = NewTypeName;
INSERT INTO Product_Category(PID, TID) VALUES ((SELECT PID FROM Product WHERE ProductName = <<INPUT_PRODUCT_NAME>> AND Product.SupplierName = <<INPUT_SUPPLIER_NAME>>),(SELECT Type.TID FROM Type WHERE TName = <<INPUT_TYPE_NAME>>));

--------------------------------
SELECT Product.Pname,Product_Warehouse.PID, Type.TName , Product.UnitPrice, Product_Warehouse.Status
FROM Product
         INNER JOIN Product_Warehouse ON Product.PID = Product_Warehouse.PID
         INNER JOIN Product_Category ON Product.PID = Product_Category.PID
         INNER JOIN Type ON Product_Category.TID = Type.TID;

-----------------------------


-- CREATE OR REPLACE PROCEDURE update_status_quantity_of_warehouse_when_export_product(NEWWID varchar(100) , NEWPID int , NEWSoldQuantity int)
--     LANGUAGE plpgsql
-- AS $$
--     BEGIN
--         DECLARE CurrentQuantity int;
--             BEGIN
--             SELECT Product_Warehouse.Quantity INTO CurrentQuantity FROM Product_Warehouse WHERE PID = NEWPID AND WID = NEWWID;
--             IF CurrentQuantity-NEWSoldQuantity <= 0 THEN
--                 UPDATE Product_Warehouse
--                 SET Quantity = CurrentQuantity - NEWSoldQuantity,Status = 'Out of Stock' ,  lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
--                     lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
--                 WHERE PID = NEWPID AND WID = NEWWID;
--             end if;
--         end;
--     end;
--     $$;


---------------
-- COUNT TOTAL ORDER 
SELECT COUNT(DISTINCT EID)
FROM Export;

-- find top selling in month '
SELECT COUNT(DISTINCT PID)
FROM Export
WHERE ExportQuantity > 10
  AND TO_CHAR(TO_DATE(ExportDate, 'YYYY-MM-DD'), 'YYYY-MM') = TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM');

