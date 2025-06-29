-- Kiểm tra và xóa cơ sở dữ liệu nếu tồn tại
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'HotelManagement')
BEGIN
    DROP DATABASE HotelManagement;
END
GO

-- Tạo cơ sở dữ liệu mới
CREATE DATABASE HotelManagement;
GO

-- Sử dụng cơ sở dữ liệu HotelManagement
USE HotelManagement;
GO

-- ===================================================================================
-- 1. TẠO BẢNG
-- ===================================================================================


-- Tạo bảng Employee
CREATE TABLE Employee (
    employeeID NVARCHAR(15) NOT NULL PRIMARY KEY,
    fullName NVARCHAR(50) NOT NULL,
    phoneNumber NVARCHAR(10) NOT NULL UNIQUE,
    email NVARCHAR(50) NOT NULL,
    address NVARCHAR(100),
    gender NVARCHAR(6) NOT NULL 
	CHECK (gender IN ('MALE', 'FEMALE')),
    idCardNumber NVARCHAR(12) NOT NULL,
    dob DATE NOT NULL,
    position NVARCHAR(15) NOT NULL 
	CHECK (position IN ('RECEPTIONIST', 'MANAGER')),
	isActivate NVARCHAR(10) NOT NULL DEFAULT 'ACTIVATE' 
	CHECK (isActivate IN ('ACTIVATE', 'DEACTIVATE')),
    --Kiểm tra tuổi >= 18
    CHECK (DATEDIFF(YEAR, dob, GETDATE()) >= 18),
);
GO


-- Tạo bảng ServiceCategory
CREATE TABLE ServiceCategory (
    serviceCategoryID NVARCHAR(15) NOT NULL PRIMARY KEY,
    serviceCategoryName NVARCHAR(50) NOT NULL,
	isActivate NVARCHAR(10) NOT NULL DEFAULT 'ACTIVATE' CHECK (isActivate IN ('ACTIVATE', 'DEACTIVATE'))
);
GO

-- Tạo bảng HotelService
CREATE TABLE HotelService (
    hotelServiceId NVARCHAR(15) NOT NULL PRIMARY KEY,
    serviceName NVARCHAR(50) NOT NULL,
    description NVARCHAR(255) NOT NULL,
    servicePrice MONEY NOT NULL,
    serviceCategoryID NVARCHAR(15) NULL,

    CONSTRAINT FK_HotelService_ServiceCategory
        FOREIGN KEY (serviceCategoryID)
        REFERENCES ServiceCategory(serviceCategoryID)
        ON DELETE SET NULL
		ON UPDATE CASCADE,

	isActivate NVARCHAR(10) NOT NULL DEFAULT 'ACTIVATE' CHECK (isActivate IN ('ACTIVATE', 'DEACTIVATE')),

    CHECK (servicePrice >= 0),
);
GO

-- Tạo bảng RoomCategory
CREATE TABLE RoomCategory (
    roomCategoryID NVARCHAR(15) NOT NULL PRIMARY KEY,
    roomCategoryName NVARCHAR(50) NOT NULL,
    numberOfBed INT NOT NULL,
	isActivate NVARCHAR(10) NOT NULL DEFAULT 'ACTIVATE' CHECK (isActivate IN ('ACTIVATE', 'DEACTIVATE')),
    CHECK (numberOfBed >= 1 AND numberOfBed <= 10),
);
GO

-- Tạo bảng Pricing
CREATE TABLE Pricing (
    pricingID NVARCHAR(15) NOT NULL PRIMARY KEY,
    priceUnit NVARCHAR(15) NOT NULL CHECK (priceUnit IN ('DAY', 'HOUR')),
    price MONEY NOT NULL,
    roomCategoryID NVARCHAR(15) NOT NULL,

    CHECK (price >= 0),

    CONSTRAINT FK_Pricing_RoomCategory FOREIGN KEY (roomCategoryID)
        REFERENCES RoomCategory(roomCategoryID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT UQ_roomCategoryID_priceUnit UNIQUE (roomCategoryID, priceUnit)
);
GO

-- Tạo bảng Room
CREATE TABLE Room (
    roomID NVARCHAR(15) NOT NULL PRIMARY KEY,
    roomStatus NVARCHAR(20) NOT NULL CHECK (roomStatus IN ('AVAILABLE', 'ON_USE', 'UNAVAILABLE', 'OVERDUE', 'RESERVED')),
    dateOfCreation DATETIME NOT NULL,
    roomCategoryID NVARCHAR(15) NOT NULL,
    FOREIGN KEY (roomCategoryID) REFERENCES RoomCategory(roomCategoryID),
	isActivate NVARCHAR(10) NOT NULL DEFAULT 'ACTIVATE' CHECK (isActivate IN ('ACTIVATE', 'DEACTIVATE'))
);
GO


-- Tạo bảng Customer
CREATE TABLE Customer (
    customerID NVARCHAR(15) NOT NULL PRIMARY KEY,
    fullName NVARCHAR(50) NOT NULL,
    phoneNumber NVARCHAR(10) NOT NULL UNIQUE,
    email NVARCHAR(50),
    address NVARCHAR(100),
    gender NVARCHAR(6) NOT NULL CHECK (gender IN ('MALE', 'FEMALE')),
    idCardNumber NVARCHAR(12) NOT NULL UNIQUE,
    dob DATE NOT NULL,
	isActivate NVARCHAR(10) NOT NULL DEFAULT 'ACTIVATE' CHECK (isActivate IN ('ACTIVATE', 'DEACTIVATE')),
    --Kiểm tra tuổi >= 18
    CHECK (DATEDIFF(YEAR, dob, GETDATE()) >= 18),
);
GO

-- Tạo bảng ReservationForm
CREATE TABLE ReservationForm (
    reservationFormID NVARCHAR(15) NOT NULL PRIMARY KEY,
    reservationDate DATETIME NOT NULL,
    checkInDate DATETIME NOT NULL,
    checkOutDate DATETIME NOT NULL,
    employeeID NVARCHAR(15),
    roomID NVARCHAR(15),
    customerID NVARCHAR(15),
	roomBookingDeposit FLOAT NOT NULL,
    FOREIGN KEY (employeeID) REFERENCES Employee(employeeID),
    FOREIGN KEY (roomID) REFERENCES Room(roomID),
    FOREIGN KEY (customerID) REFERENCES Customer(customerID),
	isActivate NVARCHAR(10) NOT NULL DEFAULT 'ACTIVATE' CHECK (isActivate IN ('ACTIVATE', 'DEACTIVATE')),
    CHECK (reservationDate <= checkInDate),
    CHECK (checkInDate <= checkOutDate), 
    CHECK (roomBookingDeposit >= 0),
);
GO

-- Tạo bảng RoomChangeHistory
CREATE TABLE RoomChangeHistory (
    roomChangeHistoryID NVARCHAR(15) NOT NULL PRIMARY KEY,
    dateChanged DATETIME NOT NULL,
    roomID NVARCHAR(15) NOT NULL,
    reservationFormID NVARCHAR(15) NOT NULL,
    employeeID NVARCHAR(15),
    FOREIGN KEY (roomID) REFERENCES Room(roomID),
    FOREIGN KEY (reservationFormID) REFERENCES ReservationForm(reservationFormID),
    FOREIGN KEY (employeeID) REFERENCES Employee(employeeID)
		ON DELETE SET NULL
        ON UPDATE CASCADE,

);
GO

-- Tạo bảng RoomUsageService
CREATE TABLE RoomUsageService (
    roomUsageServiceId NVARCHAR(15) NOT NULL PRIMARY KEY,
    quantity INT NOT NULL,
    unitPrice DECIMAL(18, 2) NOT NULL,
    totalPrice AS (quantity * unitPrice) PERSISTED,
    dateAdded DATETIME NOT NULL,
    hotelServiceId NVARCHAR(15) NOT NULL,
    reservationFormID NVARCHAR(15) NOT NULL,
    employeeID NVARCHAR(15),

    FOREIGN KEY (hotelServiceId) REFERENCES HotelService(hotelServiceId),
    FOREIGN KEY (reservationFormID) REFERENCES ReservationForm(reservationFormID),
    FOREIGN KEY (employeeID) REFERENCES Employee(employeeID)
		ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    CHECK (unitPrice >= 0),
    CHECK (quantity >= 1),
);
GO

-- Tạo bảng HistoryCheckin
CREATE TABLE HistoryCheckin (
    historyCheckInID NVARCHAR(15) NOT NULL PRIMARY KEY,
    checkInDate DATETIME NOT NULL,
    reservationFormID NVARCHAR(15) NOT NULL UNIQUE,
    employeeID NVARCHAR(15),
    FOREIGN KEY (reservationFormID) REFERENCES ReservationForm(reservationFormID),
    FOREIGN KEY (employeeID) REFERENCES Employee(employeeID)
		ON DELETE SET NULL
        ON UPDATE CASCADE
);
GO

-- Tạo bảng HistoryCheckOut
CREATE TABLE HistoryCheckOut (
    historyCheckOutID NVARCHAR(15) NOT NULL PRIMARY KEY,
    checkOutDate DATETIME NOT NULL,
    reservationFormID NVARCHAR(15) NOT NULL UNIQUE,
    employeeID NVARCHAR(15),
    FOREIGN KEY (reservationFormID) REFERENCES ReservationForm(reservationFormID),
    FOREIGN KEY (employeeID) REFERENCES Employee(employeeID)
		ON DELETE SET NULL
        ON UPDATE CASCADE
);
GO

-- Tạo bảng Invoice
CREATE TABLE Invoice (
    invoiceID NVARCHAR(15) NOT NULL PRIMARY KEY,
    invoiceDate DATETIME NOT NULL,
    roomCharge DECIMAL(18, 2) NOT NULL,
    servicesCharge DECIMAL(18, 2) NOT NULL,
    totalDue AS (roomCharge + servicesCharge) PERSISTED,
    netDue AS ((roomCharge + servicesCharge) * 1.1) PERSISTED, -- Thuế 10%
    reservationFormID NVARCHAR(15) NOT NULL,
    FOREIGN KEY (reservationFormID) REFERENCES ReservationForm(reservationFormID),
    CHECK (totalDue >= 0 AND totalDue = roomCharge + servicesCharge), 
    CHECK (netDue >= 0),
    CHECK (roomCharge >= 0),
    CHECK (servicesCharge >= 0),
);
GO


------------------
-- Thêm ràng buộc 
-----------------
-- Đảm bảo tên khách hàng và nhân viên không chứa ký tự đặc biệt
ALTER TABLE Customer
ADD CONSTRAINT CHK_Customer_FullName 
CHECK (fullName NOT LIKE '%[0-9!@#$%^&*()_+={}[\]|\\:;"<>,.?/~`]%');
GO

ALTER TABLE Employee
ADD CONSTRAINT CHK_Employee_FullName 
CHECK (fullName NOT LIKE '%[0-9!@#$%^&*()_+={}[\]|\\:;"<>,.?/~`]%');
GO

-- Thêm ràng buộc validate sdt,  email trong bảng Employee
ALTER TABLE Employee
ADD CONSTRAINT CHK_Employee_PhoneNumber 
CHECK (LEN(phoneNumber) = 10 AND ISNUMERIC(phoneNumber) = 1 AND LEFT(phoneNumber, 1) = '0');
GO

ALTER TABLE Employee
ADD CONSTRAINT CHK_Employee_Email 
CHECK (email LIKE '%@%.%' AND CHARINDEX('@', email) > 1);
GO

-- Thêm ràng buộc validate sdt, email trong bảng Customer
ALTER TABLE Customer
ADD CONSTRAINT CHK_Customer_PhoneNumber 
CHECK (LEN(phoneNumber) = 10 AND ISNUMERIC(phoneNumber) = 1 AND LEFT(phoneNumber, 1) = '0');
GO

ALTER TABLE Customer
ADD CONSTRAINT CHK_Customer_Email 
CHECK (email IS NULL OR (email LIKE '%@%.%' AND CHARINDEX('@', email) > 1));
GO

-- Thêm ràng buộc validate idCardNumber trong bảng Employee
ALTER TABLE Employee
ADD CONSTRAINT CHK_Employee_IDCardNumber 
CHECK (ISNUMERIC(idCardNumber) = 1 AND LEN(idCardNumber) = 12);
GO

-- Thêm ràng buộc validate idCardNumber trong bảng Customer
ALTER TABLE Customer
ADD CONSTRAINT CHK_Customer_IDCardNumber 
CHECK (ISNUMERIC(idCardNumber) = 1 AND LEN(idCardNumber) = 12);
GO

-- Đảm bảo dateOfCreation không vượt quá ngày hiện tại
ALTER TABLE Room
ADD CONSTRAINT CHK_Room_DateOfCreation 
CHECK (dateOfCreation <= GETDATE());
GO

-- Đảm bảo thời gian check-out không quá sớm sau check-in (ít nhất 1 giờ)
ALTER TABLE ReservationForm
ADD CONSTRAINT CHK_ReservationForm_MinStayDuration 
CHECK (DATEDIFF(HOUR, checkInDate, checkOutDate) >= 1);
GO

-- ===================================================================================
-- 2. TRIGGER - PROCEDURE - FUNCTION
-- ===================================================================================

--------------------------------
-- FUNCION TẠO ID TỰ ĐỘNG
--------------------------------
CREATE OR ALTER FUNCTION dbo.fn_GenerateID
(
    @prefix NVARCHAR(10),
    @tableName NVARCHAR(128),
    @idColumnName NVARCHAR(128),
    @padLength INT = 6
)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @result NVARCHAR(50);
    DECLARE @maxID INT;
    
    -- Sử dụng CASE để xử lý từng bảng cụ thể, lấy ID lớn nhất
    SELECT @maxID = CASE
        WHEN @tableName = 'Employee' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(employeeID, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM Employee WHERE employeeID LIKE @prefix + '%'), 0)
        WHEN @tableName = 'Customer' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(customerID, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM Customer WHERE customerID LIKE @prefix + '%'), 0)
        WHEN @tableName = 'Room' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(roomID, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM Room WHERE roomID LIKE @prefix + '%'), 0)
        WHEN @tableName = 'RoomCategory' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(roomCategoryID, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM RoomCategory WHERE roomCategoryID LIKE @prefix + '%'), 0)
        WHEN @tableName = 'ReservationForm' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(reservationFormID, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM ReservationForm WHERE reservationFormID LIKE @prefix + '%'), 0)
        WHEN @tableName = 'HistoryCheckin' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(historyCheckInID, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM HistoryCheckin WHERE historyCheckInID LIKE @prefix + '%'), 0)
        WHEN @tableName = 'HistoryCheckOut' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(historyCheckOutID, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM HistoryCheckOut WHERE historyCheckOutID LIKE @prefix + '%'), 0)
        WHEN @tableName = 'RoomChangeHistory' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(roomChangeHistoryID, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM RoomChangeHistory WHERE roomChangeHistoryID LIKE @prefix + '%'), 0)
        WHEN @tableName = 'RoomUsageService' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(roomUsageServiceId, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM RoomUsageService WHERE roomUsageServiceId LIKE @prefix + '%'), 0)
        WHEN @tableName = 'Invoice' THEN 
            ISNULL((SELECT MAX(CAST(SUBSTRING(invoiceID, LEN(@prefix) + 1, @padLength) AS INT)) 
                    FROM Invoice WHERE invoiceID LIKE @prefix + '%'), 0)
        ELSE 0
    END;
    
    -- Tạo ID mới dựa trên ID lớn nhất + 1
    SET @result = @prefix + RIGHT(REPLICATE('0', @padLength) + CAST(@maxID + 1 AS NVARCHAR(50)), @padLength);
    
    RETURN @result;
END;
GO


CREATE OR ALTER PROCEDURE sp_CreateReservation
    @checkInDate DATETIME,
    @checkOutDate DATETIME,
    @roomID NVARCHAR(15),
    @customerID NVARCHAR(15),
    @employeeID NVARCHAR(15),
    @roomBookingDeposit FLOAT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Kiểm tra các giá trị đầu vào
        IF @checkInDate IS NULL OR @checkOutDate IS NULL OR @roomID IS NULL OR @customerID IS NULL
        BEGIN
            RAISERROR('Thông tin đặt phòng không được để trống.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Kiểm tra thời gian đặt phòng hợp lệ
        IF @checkInDate <= GETDATE()
        BEGIN
            RAISERROR('Thời gian check-in phải sau thời điểm hiện tại.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        IF @checkOutDate <= @checkInDate
        BEGIN
            RAISERROR('Thời gian check-out phải sau thời gian check-in.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Kiểm tra phòng có tồn tại và sẵn sàng
        IF NOT EXISTS (SELECT 1 FROM Room WHERE roomID = @roomID AND roomStatus = 'AVAILABLE' AND isActivate = 'ACTIVATE')
        BEGIN
            RAISERROR('Phòng không tồn tại hoặc không khả dụng.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Kiểm tra khách hàng có tồn tại
        IF NOT EXISTS (SELECT 1 FROM Customer WHERE customerID = @customerID AND isActivate = 'ACTIVATE')
        BEGIN
            RAISERROR('Khách hàng không tồn tại hoặc không hoạt động.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Kiểm tra nhân viên có tồn tại
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE employeeID = @employeeID AND isActivate = 'ACTIVATE')
        BEGIN
            RAISERROR('Nhân viên không tồn tại hoặc không hoạt động.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Kiểm tra tiền đặt cọc hợp lệ
        IF @roomBookingDeposit < 0
        BEGIN
            RAISERROR('Tiền đặt cọc không thể âm.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Kiểm tra trùng lịch đặt phòng
        IF EXISTS (
            SELECT 1
            FROM ReservationForm
            WHERE roomID = @roomID
              AND isActivate = 'ACTIVATE'
              AND (
                  (@checkInDate BETWEEN checkInDate AND checkOutDate)
                  OR
                  (@checkOutDate BETWEEN checkInDate AND checkOutDate)
                  OR
                  (@checkInDate <= checkInDate AND @checkOutDate >= checkOutDate)
              )
        )
        BEGIN
            RAISERROR('Phòng đã được đặt trong khoảng thời gian này.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Tạo mã đặt phòng mới
        DECLARE @reservationFormID NVARCHAR(15) = dbo.fn_GenerateID('RF-', 'ReservationForm', 'reservationFormID', 6);
        
        -- Thêm phiếu đặt phòng mới
        INSERT INTO ReservationForm (
            reservationFormID, reservationDate, checkInDate, checkOutDate,
            employeeID, roomID, customerID, roomBookingDeposit
        )
        VALUES (
            @reservationFormID, GETDATE(), @checkInDate, @checkOutDate,
            @employeeID, @roomID, @customerID, @roomBookingDeposit
        );
        
        -- Trả về thông tin đặt phòng
        SELECT 
            rf.reservationFormID,
            rf.reservationDate,
            rf.checkInDate,
            rf.checkOutDate,
            r.roomID,
            rc.roomCategoryName,
            c.fullName AS CustomerName,
            e.fullName AS EmployeeName,
            rf.roomBookingDeposit,
            DATEDIFF(DAY, rf.checkInDate, rf.checkOutDate) AS DaysBooked
        FROM 
            ReservationForm rf
            JOIN Room r ON rf.roomID = r.roomID
            JOIN RoomCategory rc ON r.roomCategoryID = rc.roomCategoryID
            JOIN Customer c ON rf.customerID = c.customerID
            JOIN Employee e ON rf.employeeID = e.employeeID
        WHERE 
            rf.reservationFormID = @reservationFormID;
            
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Hiển thị thông tin lỗi
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH
END;
GO

-- Tạo procedure đơn giản để đặt phòng nhanh với thông tin cơ bản
CREATE OR ALTER PROCEDURE sp_QuickReservation
    @checkInDate DATETIME,
    @daysStay INT,
    @roomID NVARCHAR(15),
    @customerID NVARCHAR(15),
    @employeeID NVARCHAR(15)
AS
BEGIN
    -- Tính ngày check-out dựa trên số ngày ở
    DECLARE @checkOutDate DATETIME = DATEADD(DAY, @daysStay, @checkInDate);
    
    -- Tính tiền đặt cọc (VD: 30% giá phòng theo ngày)
    DECLARE @roomBookingDeposit FLOAT = 0;
    DECLARE @roomCategoryID NVARCHAR(15);
    
    SELECT @roomCategoryID = roomCategoryID FROM Room WHERE roomID = @roomID;
    
    SELECT @roomBookingDeposit = price * 0.3 * @daysStay
    FROM Pricing 
    WHERE roomCategoryID = @roomCategoryID AND priceUnit = 'DAY';
    
    -- Gọi procedure đặt phòng chính
    EXEC sp_CreateReservation 
        @checkInDate = @checkInDate,
        @checkOutDate = @checkOutDate,
        @roomID = @roomID,
        @customerID = @customerID,
        @employeeID = @employeeID,
        @roomBookingDeposit = @roomBookingDeposit;
END;
GO
-------------------------------------
-- trigger quản lý hóa đơn
-------------------------------------
CREATE TRIGGER TR_Invoice_ManageInsert
ON Invoice
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra điều kiện trigger TR_Check_Invoice_Date
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN ReservationForm rf ON i.reservationFormID = rf.reservationFormID
        WHERE i.invoiceDate <= rf.checkInDate
    )
    BEGIN
        RAISERROR('Ngày xuất hóa đơn phải sau hoặc bằng ngày check-in.', 16, 1);
        RETURN;
    END
    
    -- Code từ trigger trg_Invoice_Calculate_RoomCharge
    DECLARE @reservationFormID NVARCHAR(15), @checkInDate DATETIME, @checkOutDate DATETIME,
            @roomCategoryID NVARCHAR(15), @dayPrice DECIMAL(18, 2), @hourPrice DECIMAL(18, 2),
            @roomCharge DECIMAL(18, 2);
            
    SELECT @reservationFormID = i.reservationFormID,
           @checkInDate = rf.checkInDate,
           @checkOutDate = rf.checkOutDate,
           @roomCategoryID = r.roomCategoryID
    FROM inserted i
    JOIN ReservationForm rf ON i.reservationFormID = rf.reservationFormID
    JOIN Room r ON rf.roomID = r.roomID;
    
    -- Kiểm tra thời gian lưu trú hợp lệ
    IF @checkOutDate < @checkInDate
    BEGIN
        RAISERROR ('Thời gian trả phòng phải lớn hơn hoặc bằng thời gian nhận phòng.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Lấy giá theo ngày và giờ
    SELECT @dayPrice = p.price FROM Pricing p 
    WHERE p.roomCategoryID = @roomCategoryID AND p.priceUnit = 'DAY';
    
    SELECT @hourPrice = p.price FROM Pricing p 
    WHERE p.roomCategoryID = @roomCategoryID AND p.priceUnit = 'HOUR';
    
    -- Tính toán phí phòng dựa trên số ngày lưu trú
    SET @roomCharge = DATEDIFF(DAY, @checkInDate, @checkOutDate) * @dayPrice;
    IF @roomCharge < 0
        SET @roomCharge = 0;
    
    -- Thực hiện INSERT với roomCharge được tính toán
    INSERT INTO Invoice(invoiceID, invoiceDate, roomCharge, servicesCharge, reservationFormID)
    SELECT invoiceID, invoiceDate, @roomCharge, servicesCharge, reservationFormID
    FROM inserted;
END;
GO

-------------------------------------------
-- trigger riêng cho UPDATE Invoice
---------------------------------------------
CREATE TRIGGER TR_Invoice_ManageUpdate
ON Invoice
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra điều kiện từ trigger TR_Check_Invoice_Date
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN ReservationForm rf ON i.reservationFormID = rf.reservationFormID
        WHERE i.invoiceDate < rf.checkInDate
    )
    BEGIN
        RAISERROR('Ngày xuất hóa đơn phải sau hoặc bằng ngày check-in.', 16, 1);
        RETURN;
    END
    
    -- Nếu dữ liệu hợp lệ, tiến hành UPDATE
    UPDATE Invoice
    SET invoiceID = i.invoiceID,
        invoiceDate = i.invoiceDate,
        roomCharge = i.roomCharge,
        servicesCharge = i.servicesCharge,
        reservationFormID = i.reservationFormID
    FROM inserted i
    WHERE Invoice.invoiceID = i.invoiceID;
END;
GO


--------------------------------------------------------
-- Trigger để cập nhật trạng thái phòng khi có checkin
-------------------------------------------------------
CREATE TRIGGER TR_UpdateRoomStatus_OnCheckin
ON HistoryCheckin
AFTER INSERT
AS
BEGIN
    UPDATE Room
    SET roomStatus = 'ON_USE'
    FROM inserted i
    JOIN ReservationForm rf ON i.reservationFormID = rf.reservationFormID
    WHERE Room.roomID = rf.roomID;
END;
GO

--Trigger để cập nhật trạng thái phòng khi có checkout
CREATE TRIGGER TR_UpdateRoomStatus_OnCheckOut
ON HistoryCheckOut
AFTER INSERT
AS
BEGIN
    UPDATE Room
    SET roomStatus = 'AVAILABLE'
    FROM inserted i
    JOIN ReservationForm rf ON i.reservationFormID = rf.reservationFormID
    WHERE Room.roomID = rf.roomID;
END;
GO


--trigger để kiểm tra trạng thái phòng khi thêm đặt phòng trong ReservationForm
CREATE TRIGGER TR_ReservationForm_RoomStatusCheck
ON ReservationForm
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra trạng thái phòng
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Room r ON i.roomID = r.roomID
        WHERE r.roomStatus IN ('UNAVAILABLE', 'ON_USE', 'OVERDUE') 
              OR r.isActivate = 'DEACTIVATE'
    )
    BEGIN
        RAISERROR ('Phòng không khả dụng để đặt.', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra trùng lịch đặt phòng
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN ReservationForm rf ON i.roomID = rf.roomID
        WHERE rf.isActivate = 'ACTIVATE'
          AND rf.reservationFormID <> i.reservationFormID 
          AND (
              (i.checkInDate BETWEEN rf.checkInDate AND rf.checkOutDate)
              OR
              (i.checkOutDate BETWEEN rf.checkInDate AND rf.checkOutDate)
              OR
              (i.checkInDate <= rf.checkInDate AND i.checkOutDate >= rf.checkOutDate)
          )
    )
    BEGIN
        RAISERROR ('Phòng đã được đặt trong khoảng thời gian này.', 16, 1);
        RETURN;
    END
    
    -- Nếu đảm bảo điều kiện, thực hiện INSERT hoặc UPDATE
    IF EXISTS (SELECT 1 FROM deleted) -- UPDATE
    BEGIN
        UPDATE ReservationForm
        SET reservationDate = i.reservationDate,
            checkInDate = i.checkInDate,
            checkOutDate = i.checkOutDate,
            employeeID = i.employeeID,
            roomID = i.roomID,
            customerID = i.customerID,
            roomBookingDeposit = i.roomBookingDeposit,
            isActivate = i.isActivate
        FROM inserted i
        WHERE ReservationForm.reservationFormID = i.reservationFormID;
    END
    ELSE --INSERT
    BEGIN
        INSERT INTO ReservationForm(
            reservationFormID, reservationDate, checkInDate, checkOutDate,
            employeeID, roomID, customerID, roomBookingDeposit, isActivate
        )
        SELECT 
            reservationFormID, reservationDate, checkInDate, checkOutDate,
            employeeID, roomID, customerID, roomBookingDeposit, isActivate
        FROM inserted;
    END
END;
GO

-- -- Trigger kiểm tra trạng thái đặt phòng khi thêm dịch vụ
CREATE OR ALTER TRIGGER TR_RoomUsageService_CheckReservationStatus
ON RoomUsageService
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra trường hợp đặt phòng đã bị hủy
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN ReservationForm rf ON i.reservationFormID = rf.reservationFormID
        WHERE rf.isActivate = 'DEACTIVATE'
    )
    BEGIN
        DECLARE @InvalidReservations TABLE (reservationFormID NVARCHAR(15));
        
        INSERT INTO @InvalidReservations (reservationFormID)
        SELECT DISTINCT i.reservationFormID
        FROM inserted i
        JOIN ReservationForm rf ON i.reservationFormID = rf.reservationFormID
        WHERE rf.isActivate = 'DEACTIVATE';
        
        DECLARE @ErrorMsg NVARCHAR(MAX) = N'Không thể thêm dịch vụ cho (các) đặt phòng đã hủy sau:';
        
        SELECT @ErrorMsg = @ErrorMsg + CHAR(13) + '- ' + reservationFormID
        FROM @InvalidReservations;
        
        RAISERROR(@ErrorMsg, 16, 1);
        RETURN;
    END
    
    -- Kiểm tra trường hợp đã check-out
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN HistoryCheckOut ho ON i.reservationFormID = ho.reservationFormID
    )
    BEGIN
        DECLARE @CheckedOutReservations TABLE (reservationFormID NVARCHAR(15));
        
        INSERT INTO @CheckedOutReservations (reservationFormID)
        SELECT DISTINCT i.reservationFormID
        FROM inserted i
        JOIN HistoryCheckOut ho ON i.reservationFormID = ho.reservationFormID;
        
        DECLARE @CheckOutErrorMsg NVARCHAR(MAX) = N'Không thể thêm dịch vụ cho (các) đặt phòng đã check-out sau:';
        
        SELECT @CheckOutErrorMsg = @CheckOutErrorMsg + CHAR(13) + '- ' + reservationFormID
        FROM @CheckedOutReservations;
        
        RAISERROR(@CheckOutErrorMsg, 16, 1);
        RETURN;
    END
    
    -- Nếu tất cả đều hợp lệ, tiến hành thêm dịch vụ
    INSERT INTO RoomUsageService (
        roomUsageServiceId, quantity, unitPrice, dateAdded,
        hotelServiceId, reservationFormID, employeeID
    )
    SELECT
        i.roomUsageServiceId, i.quantity, i.unitPrice, i.dateAdded,
        i.hotelServiceId, i.reservationFormID, i.employeeID
    FROM inserted i;
END;
GO

--trigger để kiểm tra check-in trước khi check-out
CREATE TRIGGER TR_HistoryCheckOut_CheckInCheck
ON HistoryCheckOut
AFTER INSERT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        JOIN HistoryCheckin hc ON i.reservationFormID = hc.reservationFormID
    )
    BEGIN
        RAISERROR ('Đặt phòng phải được check-in trước khi check-out.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Tạo trigger để giới hạn mỗi roomCategoryID chỉ có 2 bản ghi trong bảng Pricing
CREATE TRIGGER trg_LimitPricingForRoomCategory
ON Pricing
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT roomCategoryID
        FROM Pricing
        GROUP BY roomCategoryID
        HAVING COUNT(*) > 2
    )
    BEGIN
        RAISERROR(
            'Mỗi loại phòng chỉ được phép có 2 bản ghi trong Pricing (1 DAY và 1 HOUR)',
            16,
            1
        );
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Tạo procedure check-in
CREATE OR ALTER PROCEDURE sp_CheckinRoom
    @reservationFormID NVARCHAR(15),       -- Mã phiếu đặt phòng
    @historyCheckInID NVARCHAR(15),        -- Mã phiếu check-in
    @employeeID NVARCHAR(15)               -- Mã nhân viên thực hiện check-in
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Kiểm tra phiếu đặt phòng có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM ReservationForm WHERE reservationFormID = @reservationFormID)
        BEGIN
            RAISERROR('Phiếu đặt phòng không tồn tại.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Kiểm tra phiếu đặt phòng có đang hoạt động không
        IF EXISTS (SELECT 1 FROM ReservationForm WHERE reservationFormID = @reservationFormID AND isActivate = 'DEACTIVATE')
        BEGIN
            RAISERROR('Phiếu đặt phòng đã bị hủy.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Kiểm tra phòng đã được check-in chưa
        IF EXISTS (SELECT 1 FROM HistoryCheckin WHERE reservationFormID = @reservationFormID)
        BEGIN
            RAISERROR('Phòng đã được check-in trước đó.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Lấy thông tin phòng và thời gian
        DECLARE @roomID NVARCHAR(15);
        DECLARE @checkInDate DATETIME;
        DECLARE @checkOutDate DATETIME;
        DECLARE @actualCheckInDate DATETIME = GETDATE(); -- Thời điểm thực hiện check-in
        
        SELECT 
            @roomID = rf.roomID,
            @checkInDate = rf.checkInDate,
            @checkOutDate = rf.checkOutDate
        FROM 
            ReservationForm rf
        WHERE 
            rf.reservationFormID = @reservationFormID;
            
        -- Kiểm tra xem phòng có sẵn sàng không
        DECLARE @roomStatus NVARCHAR(20);
        
        SELECT @roomStatus = roomStatus 
        FROM Room 
        WHERE roomID = @roomID;
        
        IF @roomStatus <> 'AVAILABLE'
        BEGIN
            RAISERROR('Phòng không khả dụng để check-in (trạng thái: %s).', 16, 1, @roomStatus);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Thêm bản ghi check-in
        INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
        VALUES (@historyCheckInID, @actualCheckInDate, @reservationFormID, @employeeID);
        
        -- Tạo ID mới cho lịch sử thay đổi phòng bằng hàm fn_GenerateID thay vì sequence
        DECLARE @roomChangeHistoryID NVARCHAR(15) = dbo.fn_GenerateID('RCH-', 'RoomChangeHistory', 'roomChangeHistoryID', 6);
        
        INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
        VALUES (@roomChangeHistoryID, @actualCheckInDate, @roomID, @reservationFormID, @employeeID);
        
        -- Trạng thái phòng sẽ tự động cập nhật thành ON_USE nhờ trigger TR_UpdateRoomStatus_OnCheckin
        
        -- Trả về kết quả thành công
        SELECT 
            @reservationFormID AS ReservationFormID,
            @historyCheckInID AS HistoryCheckInID,
            @actualCheckInDate AS CheckInDate,
            @roomID AS RoomID,
            CASE 
                WHEN @actualCheckInDate > @checkInDate THEN 'Khách hàng check-in muộn'
                WHEN @actualCheckInDate < @checkInDate THEN 'Khách hàng check-in sớm'
                ELSE 'Khách hàng check-in đúng giờ'
            END AS CheckinStatus;
            
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Hiển thị thông tin lỗi
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH
END;
GO


-- Tạo procedure đơn giản hơn để check-in chỉ cần mã đặt phòng và mã nhân viên
CREATE OR ALTER PROCEDURE sp_QuickCheckin
    @reservationFormID NVARCHAR(15),
    @employeeID NVARCHAR(15)
AS
BEGIN
    -- Tạo mã check-in mới sử dụng hàm tạo ID
    DECLARE @historyCheckInID NVARCHAR(15) = dbo.fn_GenerateID('HCI-', 'HistoryCheckin', 'historyCheckInID', 6);
    
    -- Gọi procedure chính để thực hiện check-in
    EXEC sp_CheckinRoom 
        @reservationFormID = @reservationFormID,
        @historyCheckInID = @historyCheckInID,
        @employeeID = @employeeID;
END;
GO


-- Tạo procedure trả phòng
CREATE OR ALTER PROCEDURE sp_CheckoutRoom
    @reservationFormID NVARCHAR(15),       -- Mã phiếu đặt phòng
    @historyCheckOutID NVARCHAR(15),       -- Mã phiếu check-out
    @employeeID NVARCHAR(15),              -- Mã nhân viên thực hiện check-out
    @invoiceID NVARCHAR(15) = NULL         -- Mã hóa đơn (nếu chưa có sẽ tự động tạo)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra phiếu đặt phòng có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM ReservationForm WHERE reservationFormID = @reservationFormID)
        BEGIN
            RAISERROR('Phiếu đặt phòng không tồn tại.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END

        -- Kiểm tra phiếu đặt phòng có đang hoạt động không
        IF EXISTS (SELECT 1 FROM ReservationForm WHERE reservationFormID = @reservationFormID AND isActivate = 'DEACTIVATE')
        BEGIN
            RAISERROR('Phiếu đặt phòng đã bị hủy.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END

        -- Kiểm tra phòng đã được check-in chưa
        IF NOT EXISTS (SELECT 1 FROM HistoryCheckin WHERE reservationFormID = @reservationFormID)
        BEGIN
            RAISERROR('Phòng chưa được check-in nên không thể trả phòng.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END

        -- Kiểm tra phòng đã được check-out chưa
        IF EXISTS (SELECT 1 FROM HistoryCheckOut WHERE reservationFormID = @reservationFormID)
        BEGIN
            RAISERROR('Phòng đã được check-out trước đó.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END

        -- Lấy thông tin phòng và giá tiền
        DECLARE @roomID NVARCHAR(15);
        DECLARE @roomCategoryID NVARCHAR(15);
        DECLARE @dayPrice DECIMAL(18, 2);
        DECLARE @hourPrice DECIMAL(18, 2);
        DECLARE @checkInDate DATETIME;
        DECLARE @checkOutDate DATETIME;
        DECLARE @actualCheckOutDate DATETIME = GETDATE(); -- Thời điểm thực hiện check-out
        DECLARE @roomCharge DECIMAL(18, 2);
        DECLARE @servicesCharge DECIMAL(18, 2) = 0;

        -- Lấy thông tin phòng và lịch đặt
        SELECT 
            @roomID = rf.roomID,
            @roomCategoryID = r.roomCategoryID,
            @checkInDate = rf.checkInDate,
            @checkOutDate = rf.checkOutDate
        FROM 
            ReservationForm rf
            JOIN Room r ON rf.roomID = r.roomID
        WHERE 
            rf.reservationFormID = @reservationFormID;

        -- Lấy giá theo ngày và giờ
        SELECT @dayPrice = p.price 
        FROM Pricing p 
        WHERE p.roomCategoryID = @roomCategoryID AND p.priceUnit = 'DAY';
        
        SELECT @hourPrice = p.price 
        FROM Pricing p 
        WHERE p.roomCategoryID = @roomCategoryID AND p.priceUnit = 'HOUR';

        -- Tính tổng phí dịch vụ
        SELECT @servicesCharge = ISNULL(SUM(totalPrice), 0)
        FROM RoomUsageService
        WHERE reservationFormID = @reservationFormID;

        -- Tính phí phòng dựa trên thời gian thực tế sử dụng
        DECLARE @checkInDateActual DATETIME;
        
        SELECT @checkInDateActual = checkInDate 
        FROM HistoryCheckin 
        WHERE reservationFormID = @reservationFormID;

        -- Tính số ngày sử dụng (làm tròn lên)
        DECLARE @daysUsed INT = CEILING(DATEDIFF(HOUR, @checkInDateActual, @actualCheckOutDate) / 24.0);
        
        -- Tính phí phòng
        SET @roomCharge = @daysUsed * @dayPrice;
        
        -- Thêm phí trả phòng muộn nếu cần
        IF @actualCheckOutDate > @checkOutDate
        BEGIN
            DECLARE @hoursLate INT = DATEDIFF(HOUR, @checkOutDate, @actualCheckOutDate);
            
            -- Nếu trễ dưới 2 giờ, tính theo giờ
            IF @hoursLate <= 2
            BEGIN
                SET @roomCharge = @roomCharge + (@hourPrice * @hoursLate);
            END
            -- Nếu trễ trên 2 giờ nhưng dưới 6 giờ, tính 1/2 ngày
            ELSE IF @hoursLate <= 6
            BEGIN
                SET @roomCharge = @roomCharge + (@dayPrice / 2);
            END
            -- Nếu trễ trên 6 giờ, tính 1 ngày
            ELSE
            BEGIN
                SET @roomCharge = @roomCharge + @dayPrice;
            END
        END

        -- Thêm bản ghi check-out
        INSERT INTO HistoryCheckOut (historyCheckOutID, checkOutDate, reservationFormID, employeeID)
        VALUES (@historyCheckOutID, @actualCheckOutDate, @reservationFormID, @employeeID);

        -- Kiểm tra xem đã có hóa đơn chưa
        IF EXISTS (SELECT 1 FROM Invoice WHERE reservationFormID = @reservationFormID)
        BEGIN
            -- Cập nhật hóa đơn hiện có
            UPDATE Invoice
            SET 
                roomCharge = @roomCharge,
                servicesCharge = @servicesCharge,
                invoiceDate = @actualCheckOutDate
            WHERE 
                reservationFormID = @reservationFormID;
        END
        ELSE
        BEGIN
            -- Tạo hóa đơn mới nếu không có hóa đơn
            DECLARE @newInvoiceID NVARCHAR(15);
            
            -- Sử dụng invoiceID được cung cấp hoặc tạo mã mới
            SET @newInvoiceID = ISNULL(@invoiceID, dbo.fn_GenerateID('INV-', 'Invoice', 'invoiceID', 6));
            
            INSERT INTO Invoice (invoiceID, invoiceDate, roomCharge, servicesCharge, reservationFormID)
            VALUES (@newInvoiceID, @actualCheckOutDate, @roomCharge, @servicesCharge, @reservationFormID);
        END

        -- Trạng thái phòng sẽ tự động cập nhật thành AVAILABLE nhờ trigger TR_UpdateRoomStatus_OnCheckOut

        -- Trả về kết quả thành công
        SELECT 
            @reservationFormID AS ReservationFormID,
            @historyCheckOutID AS HistoryCheckOutID,
            @actualCheckOutDate AS CheckOutDate,
            @roomCharge AS RoomCharge,
            @servicesCharge AS ServicesCharge,
            (@roomCharge + @servicesCharge) AS TotalDue,
            ((@roomCharge + @servicesCharge) * 1.1) AS NetDue,
            CASE 
                WHEN @actualCheckOutDate > @checkOutDate THEN 'Khách hàng trả phòng muộn'
                ELSE 'Khách hàng trả phòng đúng hạn'
            END AS CheckoutStatus;

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Hiển thị thông tin lỗi
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH
END;
GO

---------------------------------------
-- TẠO RPOCEDURE CHECKOUT nhanh hơn
---------------------------------------
CREATE OR ALTER PROCEDURE sp_QuickCheckout
    @reservationFormID NVARCHAR(15),
    @employeeID NVARCHAR(15)
AS
BEGIN
    -- Tạo mã check-out mới
    DECLARE @historyCheckOutID NVARCHAR(15) = dbo.fn_GenerateID('HCO-', 'HistoryCheckOut', 'historyCheckOutID', 6);
    
    -- Gọi procedure chính để thực hiện checkout
    EXEC sp_CheckoutRoom 
        @reservationFormID = @reservationFormID,
        @historyCheckOutID = @historyCheckOutID,
        @employeeID = @employeeID;
END;
GO


--===================================================================================
-- 3. THÊM DỮ LIỆU
--===================================================================================


-- Thêm dữ liệu vào bảng Employee
INSERT INTO Employee (employeeID, fullName, phoneNumber, email, address, gender, idCardNumber, dob, position)
VALUES
    ('EMP-000000', N'ADMIN', '0123456789', 'quanlykhachsan@gmail.com', 'KHÔNG CÓ', 'MALE', '001099012346', '2005-01-17', 'MANAGER'),
    ('EMP-000001', N'Đặng Ngọc Hiếu', '0912345678', 'hieud@gmail.com', N'123 Ho Chi Minh', 'MALE', '001099012345', '2005-01-17', 'MANAGER'),
    ('EMP-000002', N'Nguyễn Văn A', '0912345679', 'nguyenvana@gmail.com', N'456 Ho Chi Minh', 'MALE', '001099012346', '2005-01-17', 'MANAGER'),
    ('EMP-000003', N'Phạm Thị C', '0912345680', 'phamthic@gmail.com', N'123 Ho Chi Minh', 'FEMALE', '001099012347', '2000-03-25', 'RECEPTIONIST'),
    ('EMP-000004', N'Trần Văn C', '0912345681', 'tranvanc@gmail.com', N'234 Ho Chi Minh', 'MALE', '001099012348', '1999-05-30', 'RECEPTIONIST'),
    ('EMP-000005', N'Phạm Thị D', '0912345682', 'phamthid@gmail.com', N'567 Ho Chi Minh', 'FEMALE', '001099012349', '1998-08-15', 'RECEPTIONIST')
GO


-- Thêm dữ liệu vào bảng ServiceCategory
INSERT INTO ServiceCategory (serviceCategoryID, serviceCategoryName)
VALUES
    ('SC-000001', N'Giải trí'),
    ('SC-000002', N'Ăn uống'),
    ('SC-000003', N'Chăm sóc và sức khỏe'),
    ('SC-000004', N'Vận chuyển');
GO

-- Thêm dữ liệu vào bảng HotelService
INSERT INTO HotelService (hotelServiceId, serviceName, description, servicePrice, serviceCategoryID)
VALUES
    ('HS-000001', N'Hồ bơi', N'Sử dụng hồ bơi ngoài trời cho khách nghỉ', 50.00, 'SC-000001'),
    ('HS-000002', N'Bữa sáng tự chọn', N'Bữa sáng buffet với đa dạng món ăn', 30.00, 'SC-000002'),
    ('HS-000003', N'Thức uống tại phòng', N'Phục vụ thức uống tại phòng', 20.00, 'SC-000002'),
    ('HS-000004', N'Dịch vụ Spa', N'Massage toàn thân và liệu trình chăm sóc da', 120.00, 'SC-000003'),
    ('HS-000005', N'Phòng Gym', N'Trung tâm thể hình với trang thiết bị hiện đại', 700000, 'SC-000001'),
    ('HS-00006', N'Trò chơi điện tử', N'Khu vực giải trí với các trò chơi điện tử', 500000, 'SC-000001'),
    ('HS-00007', N'Buffet tối', N'Thực đơn buffet với đa dạng món ăn', 2000000, 'SC-000002'),
    ('HS-00008', N'Dịch vụ Cà phê', N'Cà phê và đồ uống nóng phục vụ cả ngày', 300000, 'SC-000002'),
    ('HS-00009', N'Xe đưa đón sân bay', N'Dịch vụ đưa đón từ sân bay về khách sạn', 1200000, 'SC-000004'),
    ('HS-000010', N'Thuê xe đạp', N'Thuê xe đạp tham quan quanh thành phố', 400000, 'SC-000004'),
    ('HS-000011', N'Thuê xe điện', N'Thuê xe điện cho các chuyến đi ngắn', 600000, 'SC-000004');
GO

-- Thêm dữ liệu vào bảng RoomCategory
INSERT INTO RoomCategory (roomCategoryID, roomCategoryName, numberOfBed)
VALUES
    ('RC-000001', N'Phòng Thường Giường Đơn', 1),
    ('RC-000002', N'Phòng Thường Giường Đôi', 2),
    ('RC-000003', N'Phòng VIP Giường Đơn', 1),
    ('RC-000004', N'Phòng VIP Giường Đôi', 2);
GO

-- Thêm dữ liệu vào bảng Pricing
INSERT INTO Pricing (pricingID, priceUnit, price, roomCategoryID)
VALUES
    ('P-000001', N'HOUR', 150000.00, 'RC-000001'),
    ('P-000002', N'DAY', 800000.00, 'RC-000001'),
    ('P-000003', N'HOUR', 200000.00, 'RC-000002'),
    ('P-000004', N'DAY', 850000.00, 'RC-000002'),
    ('P-000005', N'HOUR', 300000.00, 'RC-000003'),
    ('P-000006', N'DAY', 1600000.00, 'RC-000003'),
    ('P-000007', N'HOUR', 400000.00, 'RC-000004'),
    ('P-000008', N'DAY', 1800000.00, 'RC-000004');
GO

-- Thêm dữ liệu vào bảng Room với mã phòng mới
INSERT INTO Room (roomID, roomStatus, dateOfCreation, roomCategoryID)
VALUES
    ('T1101', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000001'),
    ('V2102', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000004'),
    ('T1203', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000001'),
    ('V2304', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000004'),
    ('T1105', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000001'),
    ('V2206', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000004'),
    ('T1307', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000001'),
    ('V2408', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000004'),
    ('T1109', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000001'),
    ('V2210', N'AVAILABLE', '2025-02-28 10:00:00', 'RC-000004');
GO


-- Thêm dữ liệu vào bảng Customer
INSERT INTO ReservationForm(reservationFormID, reservationDate, checkInDate, checkOutDate, employeeID, roomID, customerID, roomBookingDeposit)
VALUES
    ('RF-000001', '2025-03-25 13:35:00', '2025-03-26 09:00:00', '2025-03-28 10:30:00', 'EMP-000002', 'V2102', 'CUS-000001', 510000),
    ('RF-000002', '2025-03-27 12:40:00', '2025-03-28 08:45:00', '2025-03-30 12:30:00', 'EMP-000003', 'V2206', 'CUS-000006', 510000),
    ('RF-000003', '2025-03-23 11:25:00', '2025-03-24 07:50:00', '2025-03-26 17:20:00', 'EMP-000004', 'V2304', 'CUS-000009', 1080000),
    ('RF-000004', '2025-03-30 16:10:00', '2025-03-31 12:10:00', '2025-04-02 14:40:00', 'EMP-000005', 'V2408', 'CUS-000004', 1080000),
    ('RF-000005', '2025-04-01 09:00:00', '2025-04-02 10:45:00', '2025-04-04 11:15:00', 'EMP-000001', 'T1101', 'CUS-000003', 480000),
    ('RF-000006', '2025-04-05 08:45:00', '2025-04-06 14:20:00', '2025-04-08 10:00:00', 'EMP-000002', 'T1109', 'CUS-000008', 480000),
    ('RF-000007', '2025-04-08 07:30:00', '2025-04-09 13:10:00', '2025-04-11 12:25:00', 'EMP-000003', 'T1105', 'CUS-000006', 720000),
    ('RF-000008', '2025-04-10 10:25:00', '2025-04-11 09:40:00', '2025-04-13 14:35:00', 'EMP-000004', 'T1203', 'CUS-000007', 720000),
    ('RF-000009', '2025-04-12 15:30:00', '2025-04-13 12:50:00', '2025-04-15 10:30:00', 'EMP-000005', 'T1307', 'CUS-000004', 1440000),
    ('RF-000010', '2025-04-15 11:15:00', '2025-04-16 09:15:00', '2025-04-18 16:00:00', 'EMP-000001', 'V2210', 'CUS-000008', 1440000);
GO

-------------------------------------------
-- Thêm dữ liệu checkIn và roomChangeHistory
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000010', '2025-03-26 09:30:00', 'RF-000001', 'EMP-000002');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000010', '2025-03-26 09:30:00', 'V2102', 'RF-000001', 'EMP-000002');

-- Check-in cho RF-000002
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000011', '2025-03-28 09:15:00', 'RF-000002', 'EMP-000003');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000011', '2025-03-28 09:15:00', 'V2206', 'RF-000002', 'EMP-000003');

-- Check-in cho RF-000003
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000012', '2025-03-24 08:30:00', 'RF-000003', 'EMP-000004');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000012', '2025-03-24 08:30:00', 'V2304', 'RF-000003', 'EMP-000004');

-- Check-in cho RF-000004
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000013', '2025-03-31 12:45:00', 'RF-000004', 'EMP-000005');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000013', '2025-03-31 12:45:00', 'V2408', 'RF-000004', 'EMP-000005');

-- Check-in cho RF-000005
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000014', '2025-04-02 10:30:00', 'RF-000005', 'EMP-000001');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000014', '2025-04-02 10:30:00', 'T1101', 'RF-000005', 'EMP-000001');


-- Check-in cho RF-000006
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000015', '2025-04-06 14:35:00', 'RF-000006', 'EMP-000002');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000015', '2025-04-06 14:35:00', 'T1109', 'RF-000006', 'EMP-000002');

-- Check-in cho RF-000007
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000016', '2025-04-09 13:25:00', 'RF-000007', 'EMP-000003');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000016', '2025-04-09 13:25:00', 'T1105', 'RF-000007', 'EMP-000003');

-- Check-in cho RF-000008
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000017', '2025-04-11 10:10:00', 'RF-000008', 'EMP-000004');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000017', '2025-04-11 10:10:00', 'T1203', 'RF-000008', 'EMP-000004');

-- Check-in cho RF-000009
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000018', '2025-04-13 13:15:00', 'RF-000009', 'EMP-000005');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000018', '2025-04-13 13:15:00', 'T1307', 'RF-000009', 'EMP-000005');

-- Check-in cho RF-000010
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000019', '2025-04-16 09:45:00', 'RF-000010', 'EMP-000001');

INSERT INTO RoomChangeHistory (roomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000019', '2025-04-16 09:45:00', 'V2210', 'RF-000010', 'EMP-000001');
-----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--Cập nhật trạng thái phòng thành ON_USE cho các phòng đã check-in
UPDATE Room
SET roomStatus = 'ON_USE'
WHERE roomID IN (
    SELECT r.roomID
    FROM Room r
    JOIN ReservationForm rf ON r.roomID = rf.roomID
    JOIN HistoryCheckin hc ON rf.reservationFormID = hc.reservationFormID
    LEFT JOIN HistoryCheckOut ho ON rf.reservationFormID = ho.reservationFormID
    WHERE ho.historyCheckOutID IS NULL
);


------------------------
--Thực hiện check-out và tạo hóa đơn thông qua stored procedure
-- Check-out cho RF-000001
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000001',
    @historyCheckOutID = 'HCO-000001',
    @employeeID = 'EMP-000002',
    @invoiceID = 'INV-000001';

-- Check-out cho RF-000002
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000002',
    @historyCheckOutID = 'HCO-000002',
    @employeeID = 'EMP-000003',
    @invoiceID = 'INV-000002';

-- Check-out cho RF-000003
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000003',
    @historyCheckOutID = 'HCO-000003',
    @employeeID = 'EMP-000004',
    @invoiceID = 'INV-000003';

-- Check-out cho RF-000004
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000004',
    @historyCheckOutID = 'HCO-000004',
    @employeeID = 'EMP-000005',
    @invoiceID = 'INV-000004';

-- Check-out cho RF-000005
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000005',
    @historyCheckOutID = 'HCO-000005',
    @employeeID = 'EMP-000001',
    @invoiceID = 'INV-000005';

-- Check-out cho RF-000006
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000006',
    @historyCheckOutID = 'HCO-000006',
    @employeeID = 'EMP-000002',
    @invoiceID = 'INV-000006';

-- Check-out cho RF-000007
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000007',
    @historyCheckOutID = 'HCO-000007',
    @employeeID = 'EMP-000003',
    @invoiceID = 'INV-000007';

-- Check-out cho RF-000008
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000008',
    @historyCheckOutID = 'HCO-000008',
    @employeeID = 'EMP-000004',
    @invoiceID = 'INV-000008';

-- Check-out cho RF-000009
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000009',
    @historyCheckOutID = 'HCO-000009',
    @employeeID = 'EMP-000005',
    @invoiceID = 'INV-000009';

-- Check-out cho RF-000010
EXEC sp_CheckoutRoom 
    @reservationFormID = 'RF-000010',
    @historyCheckOutID = 'HCO-000010',
    @employeeID = 'EMP-000001',
    @invoiceID = 'INV-000010';
----------------------------------------------------------------------------------

--Phiếu 1: đã đặt phòng, có thể checkin nhưng chưa vào (đặt vào gần cuối khoảng thời gian)
INSERT INTO ReservationForm (reservationFormID, reservationDate, checkInDate, checkOutDate, employeeID, roomID, customerID, roomBookingDeposit, isActivate)
VALUES ('RF-000016', '2025-04-20 10:00:00', '2025-04-20 14:00:00', '2025-04-22 12:00:00', 'EMP-000001', 'V2210', 'CUS-000008', 500000, 'ACTIVATE');
GO

--Phiếu 2: đã checkin, có 1 bảng ghi trong HistoryCheckIn
INSERT INTO ReservationForm (reservationFormID, reservationDate, checkInDate, checkOutDate, employeeID, roomID, customerID, roomBookingDeposit, isActivate)
VALUES ('RF-000017', '2025-04-05 10:00:00', '2025-04-06 14:00:00', '2025-04-10 12:00:00', 'EMP-000002', 'T1105', 'CUS-000002', 500000, 'ACTIVATE');

INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES 
    ('HCI-000001', '2025-04-06 14:00:00', 'RF-000017', 'EMP-000002');

INSERT INTO RoomChangeHistory (RoomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES
    ('RCH-000001', '2025-04-06 14:00:00', 'T1105', 'RF-000017', 'EMP-000002');

UPDATE Room
SET roomStatus = 'ON_USE'
WHERE roomID = 'T1105';
GO

--Phiếu 3: đã checkin, quá hạn checkout 1 tiếng (dùng ngày 05/04/2025)
INSERT INTO ReservationForm (reservationFormID, reservationDate, checkInDate, checkOutDate, employeeID, roomID, customerID, roomBookingDeposit, isActivate)
VALUES ('RF-000109', '2025-04-02 10:00:00', '2025-04-03 14:00:00', '2025-04-05 11:00:00', 'EMP-000003', 'V2102', 'CUS-000003', 500000, 'ACTIVATE');

INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000002', '2025-04-03 14:00:00', 'RF-000109', 'EMP-000003');

INSERT INTO RoomChangeHistory (RoomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES
    ('RCH-000002', '2025-04-03 14:00:00', 'V2102', 'RF-000109', 'EMP-000003');

UPDATE Room
SET roomStatus = 'OVERDUE'
WHERE roomID = 'V2102';
GO

-- Phiếu 4: đã checkin và gần tới giờ checkout (còn 5 phút)
INSERT INTO ReservationForm (reservationFormID, reservationDate, checkInDate, checkOutDate, employeeID, roomID, customerID, roomBookingDeposit, isActivate)
VALUES ('RF-000110', '2025-04-18 10:00:00', '2025-04-18 14:00:00', '2025-04-20 12:05:00', 'EMP-000004', 'V2206', 'CUS-000004', 500000, 'ACTIVATE');

INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000003', '2025-04-18 14:00:00', 'RF-000110', 'EMP-000004');

INSERT INTO RoomChangeHistory (RoomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES
    ('RCH-000003', '2025-04-18 14:00:00', 'V2206', 'RF-000110', 'EMP-000004');

-- Cập nhật trạng thái phòng
UPDATE Room
SET roomStatus = 'ON_USE'
WHERE roomID = 'V2206';
GO

-- Phiếu 5: Check-in đã thực hiện, sắp quá 2 giờ thời gian checkout
INSERT INTO ReservationForm (reservationFormID, reservationDate, checkInDate, checkOutDate, employeeID, roomID, customerID, roomBookingDeposit, isActivate)
VALUES ('RF-000111', '2025-04-17 10:00:00', '2025-04-18 14:00:00', '2025-04-20 10:01:00', 'EMP-000005', 'V2304', 'CUS-000005', 600000, 'ACTIVATE');

-- Thêm thông tin vào HistoryCheckin
INSERT INTO HistoryCheckin (historyCheckInID, checkInDate, reservationFormID, employeeID)
VALUES ('HCI-000004', '2025-04-18 14:00:00', 'RF-000111', 'EMP-000005');

-- Thêm vào RoomChangeHistory
INSERT INTO RoomChangeHistory (RoomChangeHistoryID, dateChanged, roomID, reservationFormID, employeeID)
VALUES ('RCH-000004', '2025-04-18 14:00:00', 'V2304', 'RF-000111', 'EMP-000005');

-- Cập nhật trạng thái phòng
UPDATE Room
SET roomStatus = 'ON_USE'
WHERE roomID = 'V2304';
GO

-- Phiếu 6: Phiếu đặt phòng chưa check-in, sắp quá 2 tiếng thời gian check-in
INSERT INTO ReservationForm (reservationFormID, reservationDate, checkInDate, checkOutDate, employeeID, roomID, customerID, roomBookingDeposit, isActivate)
VALUES ('RF-000112', '2025-04-19 08:00:00', '2025-04-20 10:03:00', '2025-04-21 12:00:00', 'EMP-000001', 'T1203', 'CUS-000010', 700000, 'ACTIVATE');
GO
USE master
GO


--Tạo 1 checkin ví dụ - sử dụng procedure QuickCheckin
USE HotelManagement;
GO

-- Kiểm tra phiếu đặt phòng RF-000112 (phiếu chưa được check-in)
SELECT 
    reservationFormID, 
    roomID, 
    customerID, 
    checkInDate, 
    checkOutDate 
FROM 
    ReservationForm 
WHERE 
    reservationFormID = 'RF-000005';

-- Thực hiện check-in cho phiếu đặt phòng với nhân viên EMP-000005
EXEC sp_QuickCheckin 
    @reservationFormID = 'RF-000005', 
    @employeeID = 'EMP-000001';

-- Kiểm tra kết quả sau khi check-in
SELECT 
    hc.historyCheckInID,
    hc.checkInDate,
    rf.reservationFormID,
    rf.roomID,
    c.fullName AS CustomerName,
    r.roomStatus
FROM 
    HistoryCheckin hc
    JOIN ReservationForm rf ON hc.reservationFormID = rf.reservationFormID
    JOIN Customer c ON rf.customerID = c.customerID
    JOIN Room r ON rf.roomID = r.roomID
WHERE 
    rf.reservationFormID = 'RF-000112';