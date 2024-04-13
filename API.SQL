-- INSERT INTO PRODUCT_ORDER

WITH Needed_PID as (
    SELECT Product.PID AS NeededPID FROM Product WHERE  Product.Pname = <<INPUT_PRODUCT_NAME>>  and Product.SupplierName = <<INPUT_SUPPLIER_NAME>>
)
INSERT INTO Product_Order(PID,ProductName,SupplierName,WarehouseName,Order_Detail_ID,OrderDate,OrderQuantity) VALUES (Needed_PID.NeededPID , <<INPUT_PRODUCT_NAME>>,<<INPUT_SUPPLIER_NAME>>,<<INPUT_WAREHOUSE_NAME>>,(    SELECT Order_Detail.CodeOrder FROM Order_Detail ORDER BY CodeOrder DESC LIMIT 1),(current_timestamp , 'DD/MM/YYYY'), <<INPUT_ORDER_QUANTITY>> );



--------------------------------------------------------------------------------------------------------------------------------------
-- INSERT INTO PRODUCT_WAREHOUSE
WITH
    NeededPID as(
        SELECT Product.PID AS NeededPID FROM Product where Product.Pname = <<INPUT_PRODUCT_NAME>>  and Product.SupplierName = <<INPUT_SUPPLIER_NAME>>
    ),
     Existing_Record AS (
         SELECT *
         FROM Product_Warehouse
         WHERE PID = NeededPID.NeededPID and WName = <<INPUT_WAREHOUSE_NAME>>
     )

-- Insert or update the record
INSERT INTO Product_Warehouse (WName, PID, Quantity) VALUES (<<INPUT_WAREHOUSE_NAME>> ,(SELECT NeededPID FROM NeededPID), <<INPUT_QUANTITY>> )
ON CONFLICT (PID, WName) DO UPDATE
    SET
        Quantity = Product_Warehouse.Quantity + EXCLUDED.Quantity,
        LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY'),
        LastUpdatedTime = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7','HH24:MI:SS'),
        Status = CASE
                     WHEN Product_Warehouse.Quantity + EXCLUDED.Quantity <= 0 THEN 'Out of Stock'
                     WHEN Product_Warehouse.Quantity + EXCLUDED.Quantity < 10 THEN 'Low Stock'
                     ELSE 'In Stock'
            END;
