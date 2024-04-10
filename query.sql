-- CREATE TRIGGER TO UPDATE THE STATUS AND  THE LAST DATE TO UPDATE TO Product_Warehouse table
-- USE TRIGGER TO UPDATE to table Prodcut_Warehouse. In the Order , after click to Add Order , The system will automatically set the Status base on the logic set by dev , the LastUpdatedDate and LastUpdatedTime are also updated
--     automatically by the time and date the user pressed the Add Order button. UPDATE in CRUD
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


-- format date ( RETURN THE VALUE OF INPUT IN TYPE OF VARCHAR ) (READ in CRUD) ( this is just use if the user want to set the Date for the Product inserted to the Product_Warehouse in another but not the current date when the user
-- press the button Add Order)
CREATE OR REPLACE FUNCTION format_date(date_input DATE)
    RETURNS VARCHAR
AS $$
BEGIN
    RETURN (TO_CHAR(date_input, 'DD') || '/' || TO_CHAR(date_input, 'MM') || '/' || TO_CHAR(date_input, 'YYYY'));
END;
$$ LANGUAGE plpgsql;


-- CREATE PROCEDURE TO FIND TOTAL ORDER OF SPECIFIC WAREHOUSE in current  MONTH ( RETURN THE VALUE OF TOTAL ORDER BY current MONTH OF SPECIFIC WAREHOUSE ) ( CREATE and READ in CRUD ) --> 
CREATE OR REPLACE PROCEDURE Total_Order_By_Month(NEWWID int)
LANGUAGE plpgsql
AS $$
    DECLARE CurrentExportDate TIMESTAMP;
BEGIN
SELECT  COUNT(*) AS Total_Orders_Current_Month  -- CREATE DATA TO TAKE THE Number of Orders 
FROM Export
WHERE EXTRACT(MONTH FROM current_timestamp) = EXTRACT(MONTH FROM Export.ExportDate) AND WID = NEWWID
GROUP BY TO_CHAR(current_timestamp, 'Month');
end;
$$;


-- Count total order of all warehouse order by each month. This is CREATE and READ in CRUD. USE this to get the Total of all warehouse and then return the value of total order to show in Dashboard
SELECT TO_CHAR(current_timestamp, 'Month') AS Current_Month,
       COUNT(*) AS Total_Orders_Current_Month
FROM Export
WHERE EXTRACT(MONTH FROM current_timestamp) = EXTRACT(MONTH FROM Export.ExportDate)
GROUP BY TO_CHAR(current_timestamp, 'Month');

-- count all of typeus4e CREATE and READ in CRUD. This is use to select all of type and return the value to update on Types in 
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

-- SELECT ALL THE PRODUCT WITH STATUS IS ' LOW STOCK ' IN ALL OF WAREHOUSES
SELECT PID, Quantity,Status
FROM Product_Warehouse
WHERE COALESCE(Status, '') = 'Low Stock';

-- SELECT ALL THE PRODUCT WITH STATUS IS ' LOW STOCK ' IN SPECIFIC WAREHOUSE
SELECT PID, Quantity,Status
FROM Product_Warehouse
WHERE COALESCE(Status, '') = 'Low Stock' AND WID = 1;




-- CREATE PROCEDURE TO INSERT TO PRODUCT CATEGORY AUTOMATICALLY
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



CREATE OR REPLACE PROCEDURE insert_reorder_product(
    NEWWID int,
    NEWPID varchar(100),
    NEWQuantity int
)
    LANGUAGE plpgsql
AS $$
BEGIN
    DECLARE
existing_record RECORD;
BEGIN
        -- Check if product exists in the warehouse
SELECT *  -- Selects all columns from Product_Warehouse
INTO existing_record
FROM Product_Warehouse
WHERE pid = NEWPID AND wid = NEWWID;

IF FOUND THEN
            -- Update quantity and status based on existing record
            IF existing_record.quantity + NEWQuantity <= 0 THEN
UPDATE Product_Warehouse
SET quantity = quantity + NEWQuantity,
    lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
    lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS'), status = 'Out of Stock'
WHERE PID = NEWPID AND WID = NEWWID;
ELSIF existing_record.quantity + NEWQuantity < 10 THEN
UPDATE Product_Warehouse
SET quantity = quantity + NEWQuantity,
    lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
    lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS'), status = 'Low Stock'
WHERE PID = NEWPID AND WID = NEWWID;
ELSE
UPDATE Product_Warehouse
SET quantity = quantity + NEWQuantity,
    lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
    lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS'), status = 'In Stock'
WHERE PID = NEWPID AND WID = NEWWID;
END IF;
ELSE
            -- Insert new record if product doesn't exist
            INSERT INTO Product_Warehouse(WID, PID, Quantity)
            VALUES (NEWWID, NEWPID, NEWQuantity);
END IF;
EXCEPTION WHEN NO_DATA_FOUND THEN
        -- Handle the case where no product is found (optional)
        RAISE NOTICE 'Insert new product to warehouse';
END;
END;
$$;

-- CREATE PROCEDURE TO UPDATE STATUS AND QUANTITY OF PRODUCT IN PRODUCT_WAREHOUSE AFTER EXPORT
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
ELSEIF CurrentQuantity-NEWSoldQuantity < 10  THEN
UPDATE Product_Warehouse
SET Quantity = CurrentQuantity - NEWSoldQuantity,Status = 'Low Stock' ,  lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
    lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
WHERE PID = NEWPID AND WID = NEWWID;
ELSE
UPDATE Product_Warehouse
SET Quantity = CurrentQuantity - NEWSoldQuantity,Status = 'In Stock' ,  lastupdateddate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
    lastupdatedtime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS')
WHERE PID = NEWPID AND WID = NEWWID;
end if;
end;
end;
$$;


-- Count total order of SPECIFIC warehouse order by each month
SELECT TO_CHAR(current_timestamp, 'Month') AS Current_Month,
       COUNT(*) AS Total_Orders_Current_Month
FROM Export
WHERE WID = 1 AND  EXTRACT(MONTH FROM current_timestamp) = EXTRACT(MONTH FROM Export.ExportDate)
GROUP BY TO_CHAR(current_timestamp, 'Month');


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


CREATE OR REPLACE FUNCTION fetch_records_from_past_months(months_ago INT)
    RETURNS TABLE(LastUpdatedDate VARCHAR, revenue NUMERIC) AS
$$
BEGIN
RETURN QUERY
SELECT PW.LastUpdatedDate,
       (SUM(P.unitprice * PW.Quantity) - SUM(P.costprice * PW.Quantity)) AS revenue
FROM Product AS P
         INNER JOIN Product_Warehouse AS PW ON P.PID = PW.PID
WHERE TO_DATE(PW.LastUpdatedDate, 'DD-MM-YYYY') >= (CURRENT_DATE - INTERVAL '1 month' * months_ago)
GROUP BY PW.LastUpdatedDate;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fetch_records_from_past_months(1);

-- FIND REVENUE OF CURRENT
select PW.LastUpdatedDate,
       (sum(P.unitprice * PW.Quantity) - sum(P.costprice * PW.Quantity)) AS revenue
from Product AS P
         INNER JOIN Product_Warehouse AS PW ON P.PID = PW.PID
group by PW.LastUpdatedDate;
