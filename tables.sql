CREATE TABLE Product (
                         PID varchar(100) PRIMARY KEY,
                         Pname varchar(100) NOT NULL,
                         Brand varchar(100),
                         SupplierID int,
                         CostPrice decimal(5,2),
                         UnitPrice decimal(5,2),
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
                               OrderID int PRIMARY KEY,
                               WID int ,
                               PID varchar(100) ,
                               SupplierID int ,
                               FOREIGN KEY(WID) REFERENCES Warehouse(WID),
                               FOREIGN KEY(PID) REFERENCES Product(PID),
                               FOREIGN KEY(SupplierID) REFERENCES Supplier(SupplierID) ,
                               OrderDate date NOT NULL,
                               OrderQuantity int
);

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

-- Có thể có hoặc không
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

CREATE TABLE Export(
                       WID int,
                       PID varchar(100),
                       EID varchar(100),
                       ExportQuantity int,
                       ExportDate date,
                       PRIMARY KEY(EID),
                       FOREIGN KEY(PID) REFERENCES Product(PID),
                       FOREIGN KEY (WID) REFERENCES Warehouse(WID)
);