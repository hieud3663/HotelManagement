--- Liệt kê tất cả các phòng và trạng thái hiện tại
SELECT 
    r.roomID, 
    r.roomStatus, 
    rc.roomCategoryName
FROM 
    Room r
    JOIN RoomCategory rc ON r.roomCategoryID = rc.roomCategoryID
ORDER BY 
    r.roomID;

-- Hiển thị danh sách nhân viên theo chức vụ 
SELECT 
    employeeID,
    fullName as [Họ và tên],
    phoneNumber as [Số điện thoại],
    email as [Email],
    position as [Chức vụ],
    gender as [Giới tính],
    dob as [Ngày sinh],
    address as [Địa chỉ]
FROM 
    Employee
ORDER BY 
    position;



--Đếm số lượng phòng theo trạng thái
SELECT 
    roomStatus as [Trạng thái phòng],
    COUNT(*) AS [Số lượng phòng]
FROM 
    Room
GROUP BY 
    roomStatus
ORDER BY 
    [Số lượng phòng] DESC;

--Lấy thông tin đặt phòng 
SELECT 
    rf.reservationFormID,
    rf.checkInDate,
    rf.checkOutDate,
    c.fullName AS CustomerName,
    e.fullName AS EmployeeName,
    r.roomID
FROM ReservationForm rf
JOIN Customer c ON rf.customerID = c.customerID
JOIN Employee e ON rf.employeeID = e.employeeID
JOIN Room r ON rf.roomID = r.roomID;


--Xác định nhân viên xử lý nhiều đặt phòng nhất
SELECT 
    e.employeeID,
    e.fullName as [Họ và tên],
    COUNT(rf.reservationFormID) AS [Tổng số đặt phòng]
FROM Employee e
LEFT JOIN ReservationForm rf ON e.employeeID = rf.employeeID
GROUP BY e.employeeID, e.fullName
ORDER BY [Tổng số đặt phòng] DESC;


-- Hiển thị thông tin các phòng đã được check-in nhưng chưa check-out
SELECT 
    r.roomID,
    rf.checkInDate as [Ngày check-in],
    rf.checkOutDate as [Ngày check-out],
    DATEDIFF(DAY, hc.checkInDate, rf.checkOutDate) AS [T/gian lưu trú dự kiến],
    c.fullName AS [Khách hàng],
    e.fullName AS [Nhân viên check-in]
FROM 
    Room r
    JOIN ReservationForm rf ON r.roomID = rf.roomID
    JOIN HistoryCheckin hc ON rf.reservationFormID = hc.reservationFormID
    JOIN Customer c ON rf.customerID = c.customerID
    JOIN Employee e ON hc.employeeID = e.employeeID
    LEFT JOIN HistoryCheckOut ho ON rf.reservationFormID = ho.reservationFormID
WHERE 
    ho.historyCheckOutID IS NULL
ORDER BY 
    hc.checkInDate;


--Tính tổng doanh thu từ hóa đơn trong tháng 4/2025
SELECT 
    SUM(roomCharge) AS [Tổng tiền phòng],
    SUM(servicesCharge) AS [Tổng tiền dịch vụ],
    SUM(totalDue) AS [Tổng tiền thanh toán],
    SUM(netDue) AS [Tổng tiền thực thu (gồm VAT)],
    COUNT(*) AS InvoiceCount
FROM 
    Invoice
WHERE 
    YEAR(invoiceDate) = 2025 AND MONTH(invoiceDate) = 4;

--Tìm phòng được đặt nhiều nhất
SELECT 
    r.roomID,
    rc.roomCategoryName AS [Loại phòng],
    COUNT(rf.reservationFormID) AS [Tổng số lần đặt],
    SUM(DATEDIFF(DAY, rf.checkInDate, rf.checkOutDate)) AS [T/gian lưu trú (ngày)]
FROM 
    Room r
    JOIN ReservationForm rf ON r.roomID = rf.roomID
    JOIN RoomCategory rc ON r.roomCategoryID = rc.roomCategoryID
GROUP BY 
    r.roomID, rc.roomCategoryName
ORDER BY 
    [Tổng số lần đặt] DESC, [T/gian lưu trú (ngày)] DESC;

--Phân tích doanh thu theo loại phòng và tháng
SELECT 
    rc.roomCategoryName,
    MONTH(i.invoiceDate) AS [Tháng],
    YEAR(i.invoiceDate) AS [Năm],
    COUNT(DISTINCT i.invoiceID) AS [Tổng hóa đơn],
    SUM(i.roomCharge) AS [Doanh thu tiền phòng],
    AVG(i.roomCharge) AS [Doanh thu trung bình tiền phòng],
    SUM(i.totalDue) AS [Tổng doanh thu]
FROM 
    Invoice i
    JOIN ReservationForm rf ON i.reservationFormID = rf.reservationFormID
    JOIN Room r ON rf.roomID = r.roomID
    JOIN RoomCategory rc ON r.roomCategoryID = rc.roomCategoryID
WHERE 
    YEAR(i.invoiceDate) = 2025
GROUP BY 
    rc.roomCategoryName, MONTH(i.invoiceDate), YEAR(i.invoiceDate)
ORDER BY 
    rc.roomCategoryName, [Tháng], [Năm];


-- Phân tích hiệu suất của các nhân viên dựa trên số lượng check-in, check-out và doanh thu
WITH EmployeeMetrics AS (
    SELECT 
        e.employeeID,
        e.fullName,
        e.position,
        COUNT(DISTINCT hc.reservationFormID) AS TotalCheckins,
        0 AS TotalCheckouts,
        0 AS TotalRevenue
    FROM 
        Employee e
        LEFT JOIN HistoryCheckin hc ON e.employeeID = hc.employeeID
    GROUP BY 
        e.employeeID, e.fullName, e.position
    
    UNION ALL
    

    SELECT 
        e.employeeID,
        e.fullName,
        e.position,
        0 AS TotalCheckins,
        COUNT(DISTINCT ho.reservationFormID) AS TotalCheckouts,
        0 AS TotalRevenue
    FROM 
        Employee e
        LEFT JOIN HistoryCheckOut ho ON e.employeeID = ho.employeeID
    GROUP BY 
        e.employeeID, e.fullName, e.position
    
    UNION ALL
    
    -- Revenue metrics (from invoices created during checkout)
    SELECT 
        e.employeeID,
        e.fullName,
        e.position,
        0 AS TotalCheckins,
        0 AS TotalCheckouts,
        SUM(i.netDue) AS TotalRevenue
    FROM 
        Employee e
        LEFT JOIN HistoryCheckOut ho ON e.employeeID = ho.employeeID
        LEFT JOIN Invoice i ON ho.reservationFormID = i.reservationFormID
    GROUP BY 
        e.employeeID, e.fullName, e.position
)

SELECT 
    employeeID as [ID nhân viên],
    fullName as [Họ và tên],
    position as [Chức vụ],
    SUM(TotalCheckins) AS [Tổng số check-in],
    SUM(TotalCheckouts) AS [Tổng số check-out],
    SUM(TotalRevenue) AS [Tổng doanh thu],
    CASE WHEN SUM(TotalCheckins) > 0 THEN 
        SUM(TotalRevenue) / SUM(TotalCheckins) ELSE 0 END AS [Doanh thu trung bình mỗi check-in]
FROM 
    EmployeeMetrics
GROUP BY 
    employeeID, fullName, position
ORDER BY 
    [Tổng doanh thu] DESC, [Tổng số check-out] DESC;

-- Kiểm tra trạng thái tất cả các đặt phòng
SELECT 
    rf.reservationFormID AS [Mã đặt phòng],
    rf.checkInDate AS [Ngày check-in dự kiến],
    rf.checkOutDate AS [Ngày check-out dự kiến],
    r.roomID AS [Mã phòng],
    c.fullName AS [Tên khách hàng],
    CASE 
        WHEN ho.historyCheckOutID IS NOT NULL THEN N'Đã check-out'
        WHEN hc.historyCheckInID IS NOT NULL THEN N'Đã check-in'
        WHEN rf.checkInDate > GETDATE() THEN N'Đang chờ check-in'
        WHEN rf.checkInDate <= GETDATE() THEN N'Trễ check-in'
    END AS [Trạng thái đặt phòng],
    hc.checkInDate AS [Ngày check-in thực tế],
    ho.checkOutDate AS [Ngày check-out thực tế]
FROM 
    ReservationForm rf
    JOIN Room r ON rf.roomID = r.roomID
    JOIN Customer c ON rf.customerID = c.customerID
    LEFT JOIN HistoryCheckin hc ON rf.reservationFormID = hc.reservationFormID
    LEFT JOIN HistoryCheckOut ho ON rf.reservationFormID = ho.reservationFormID
ORDER BY 
    rf.checkInDate;

-- So sánh T/gian check-in/check-out thực tế với dự kiến
SELECT 
    rf.reservationFormID AS [Mã đặt phòng],
    rf.checkInDate AS [Check-in dự kiến],
    hc.checkInDate AS [Check-in thực tế],
    DATEDIFF(MINUTE, rf.checkInDate, hc.checkInDate) AS [Chênh lệch check-in (phút)],
    CASE 
        WHEN hc.checkInDate > rf.checkInDate THEN N'Trễ'
        WHEN hc.checkInDate < rf.checkInDate THEN N'Sớm'
        ELSE N'Đúng giờ'
    END AS [Tình trạng check-in],
    rf.checkOutDate AS [Check-out dự kiến],
    ho.checkOutDate AS [Check-out thực tế],
    DATEDIFF(MINUTE, rf.checkOutDate, ho.checkOutDate) AS [Chênh lệch check-out (phút)],
    CASE 
        WHEN ho.checkOutDate > rf.checkOutDate THEN N'Trễ'
        WHEN ho.checkOutDate < rf.checkOutDate THEN N'Sớm'
        WHEN ho.checkOutDate IS NULL THEN N'Chưa check-out'
        ELSE N'Đúng giờ'
    END AS [Tình trạng check-out]
FROM 
    ReservationForm rf
    LEFT JOIN HistoryCheckin hc ON rf.reservationFormID = hc.reservationFormID
    LEFT JOIN HistoryCheckOut ho ON rf.reservationFormID = ho.reservationFormID
WHERE 
    hc.historyCheckInID IS NOT NULL
ORDER BY 
    rf.reservationDate;


-- Phân tích thói quen đặt phòng của khách hàng thân thiết
SELECT 
    c.customerID AS [Mã khách hàng],
    c.fullName AS [Tên khách hàng],
    COUNT(rf.reservationFormID) AS [Số lần đặt phòng],
    AVG(DATEDIFF(DAY, rf.checkInDate, rf.checkOutDate)) AS [T/gian lưu trú TB (ngày)],
    STRING_AGG(r.roomID, ', ') AS [Các phòng đã đặt],
    COUNT(DISTINCT r.roomCategoryID) AS [Số loại phòng đã dùng],
    MAX(rf.reservationDate) AS [Lần đặt phòng gần nhất],
    SUM(i.netDue) AS [Tổng chi tiêu]
FROM 
    Customer c
    JOIN ReservationForm rf ON c.customerID = rf.customerID
    JOIN Room r ON rf.roomID = r.roomID
    LEFT JOIN Invoice i ON rf.reservationFormID = i.reservationFormID
GROUP BY 
    c.customerID, c.fullName
ORDER BY 
    [Số lần đặt phòng] DESC, [Tổng chi tiêu] DESC;

-- Phân tích quy trình đặt phòng từ đặt -> check-in -> check-out -> thanh toán
WITH BookingProcess AS (
    SELECT 
        rf.reservationFormID,
        rf.reservationDate,
        hc.checkInDate,
        ho.checkOutDate,
        i.invoiceDate,
        DATEDIFF(HOUR, rf.reservationDate, hc.checkInDate) AS HoursFromBookingToCheckin,
        DATEDIFF(HOUR, hc.checkInDate, ho.checkOutDate) AS HoursStay,
        DATEDIFF(MINUTE, ho.checkOutDate, i.invoiceDate) AS MinutesFromCheckoutToInvoice
    FROM 
        ReservationForm rf
        LEFT JOIN HistoryCheckin hc ON rf.reservationFormID = hc.reservationFormID
        LEFT JOIN HistoryCheckOut ho ON rf.reservationFormID = ho.reservationFormID
        LEFT JOIN Invoice i ON rf.reservationFormID = i.reservationFormID
    WHERE 
        hc.checkInDate IS NOT NULL AND ho.checkOutDate IS NOT NULL AND i.invoiceDate IS NOT NULL
)

SELECT 
    COUNT(*) AS [Số lượng giao dịch hoàn thành],
    AVG(HoursFromBookingToCheckin) AS [T/gian từ đặt đến check-in TB (giờ)],
    AVG(HoursStay) AS [T/gian lưu trú TB (giờ)],
    AVG(MinutesFromCheckoutToInvoice) AS [T/gian từ check-out đến lập hóa đơn TB (phút)],
    (SELECT COUNT(*) FROM ReservationForm WHERE reservationFormID NOT IN 
        (SELECT reservationFormID FROM HistoryCheckin)) AS [Số đặt phòng chưa check-in],
    (SELECT COUNT(*) FROM HistoryCheckin hc 
        LEFT JOIN HistoryCheckOut ho ON hc.reservationFormID = ho.reservationFormID
        WHERE ho.historyCheckOutID IS NULL) AS [Số phòng đã check-in chưa check-out]
FROM 
    BookingProcess;

-- Phân tích xu hướng đặt phòng theo ngày trong tuần và thời điểm trong ngày
WITH BookingTimeAnalysis AS (
    SELECT
        DATEPART(WEEKDAY, reservationDate) AS DayOfWeek,
        DATEPART(HOUR, reservationDate) AS HourOfDay,
        COUNT(*) AS BookingCount
    FROM
        ReservationForm
    GROUP BY
        DATEPART(WEEKDAY, reservationDate),
        DATEPART(HOUR, reservationDate)
)

SELECT
    CASE DayOfWeek
        WHEN 1 THEN N'Chủ nhật'
        WHEN 2 THEN N'Thứ hai'
        WHEN 3 THEN N'Thứ ba'
        WHEN 4 THEN N'Thứ tư'
        WHEN 5 THEN N'Thứ năm'
        WHEN 6 THEN N'Thứ sáu'
        WHEN 7 THEN N'Thứ bảy'
    END AS [Ngày trong tuần],
    HourOfDay AS [Giờ trong ngày],
    BookingCount AS [Số lượng đặt phòng],
    CAST(BookingCount * 100.0 / SUM(BookingCount) OVER (PARTITION BY DayOfWeek) AS DECIMAL(5,2)) AS [Phần trăm theo ngày],
    CAST(BookingCount * 100.0 / SUM(BookingCount) OVER () AS DECIMAL(5,2)) AS [Phần trăm tổng]
FROM
    BookingTimeAnalysis
ORDER BY
    DayOfWeek, HourOfDay;


------------------------------
--- QUÁ TRÌNH ĐẶT PHÒNG ---
------------------------------
-- 1. Kiểm tra phòng trống trong khoảng thời gian cần đặt
DECLARE @CheckInDate DATETIME = '2025-05-01 14:00:00';
DECLARE @CheckOutDate DATETIME = '2025-05-03 12:00:00';

SELECT 
    r.roomID AS [Số phòng],
    rc.roomCategoryName AS [Loại phòng],
    rc.numberOfBed AS [Số giường],
    p.price AS [Giá theo ngày],
    r.roomStatus AS [Trạng thái hiện tại]
FROM 
    Room r
    JOIN RoomCategory rc ON r.roomCategoryID = rc.roomCategoryID
    JOIN Pricing p ON rc.roomCategoryID = p.roomCategoryID
WHERE 
    r.roomStatus = 'AVAILABLE'
    AND r.isActivate = 'ACTIVATE'
    AND p.priceUnit = 'DAY'
    AND NOT EXISTS (
        SELECT 1
        FROM ReservationForm rf
        WHERE rf.roomID = r.roomID
          AND rf.isActivate = 'ACTIVATE'
          AND (
              (@CheckInDate BETWEEN rf.checkInDate AND rf.checkOutDate)
              OR
              (@CheckOutDate BETWEEN rf.checkInDate AND rf.checkOutDate)
              OR
              (@CheckInDate <= rf.checkInDate AND @CheckOutDate >= rf.checkOutDate)
          )
    )
ORDER BY 
    rc.roomCategoryName, p.price;
GO

-- 2. Kiểm tra khách hàng đã tồn tại trong hệ thống chưa
SELECT 
    customerID, fullName, phoneNumber, email
FROM 
    Customer
WHERE 
    phoneNumber = '0987654321' OR idCardNumber = '123456789012';

-- 2b. Nếu chưa có, thêm khách hàng mới
INSERT INTO Customer (
    customerID, fullName, phoneNumber, email, 
    address, gender, idCardNumber, dob
)
VALUES (
    'CUS-000020', N'Nguyễn Văn Khách','0987654321','khachhang@gmail.com', 
    N'123 Đường ABC, Quận 1, TP.HCM', 'MALE', '123456789012','1990-05-15'
);

-- 2c. Kiểm tra lại thông tin khách hàng đã thêm
SELECT * FROM Customer WHERE customerID = 'CUS-000020';

GO

-- 3. Thực hiện đặt phòng
DECLARE @CheckInDate DATETIME = '2025-05-01 14:00:00';
DECLARE @CheckOutDate DATETIME = '2025-05-03 12:00:00';
DECLARE @RoomID NVARCHAR(15) = 'T1105'; -- Phòng được chọn từ bước 1
DECLARE @CustomerID NVARCHAR(15) = 'CUS-000020'; -- Khách hàng từ bước 2
DECLARE @EmployeeID NVARCHAR(15) = 'EMP-000003'; -- Nhân viên thực hiện
DECLARE @RoomDeposit FLOAT = 500000; -- Tiền đặt cọc
DECLARE @ReservationID NVARCHAR(15);

-- 3a. Tạo ID đặt phòng mới
SELECT @ReservationID = 'RF-' + RIGHT('000000' + CAST((SELECT COUNT(*) + 1 FROM ReservationForm) AS NVARCHAR), 6);

-- 3b. Thêm thông tin đặt phòng vào bảng ReservationForm
INSERT INTO ReservationForm (
    reservationFormID, reservationDate, checkInDate, checkOutDate, 
    roomBookingDeposit, isActivate, roomID, customerID, employeeID
)
VALUES (
    @ReservationID, GETDATE(), @CheckInDate, @CheckOutDate, 
    @RoomDeposit, 'ACTIVATE', @RoomID, @CustomerID, @EmployeeID
);

-- 3c. Cập nhật trạng thái phòng thành RESERVED (nếu cần)
UPDATE Room
SET roomStatus = 'RESERVED'
WHERE roomID = @RoomID;

-- 3d. In ra thông tin đặt phòng vừa tạo
SELECT 
    'Đặt phòng thành công!' AS [Trạng thái],
    @ReservationID AS [Mã đặt phòng],
    @CheckInDate AS [Ngày check-in],
    @CheckOutDate AS [Ngày check-out],
    DATEDIFF(DAY, @CheckInDate, @CheckOutDate) AS [Số ngày ở],
    @RoomID AS [Mã phòng],
    @RoomDeposit AS [Tiền đặt cọc],
    (SELECT fullName FROM Customer WHERE customerID = @CustomerID) AS [Tên khách hàng],
    (SELECT fullName FROM Employee WHERE employeeID = @EmployeeID) AS [Nhân viên đặt phòng];

GO

-- 4. Trước khi check-in, tìm thông tin đặt phòng
DECLARE @ReservationID NVARCHAR(15);

SELECT @ReservationID = reservationFormID
FROM ReservationForm
WHERE customerID = 'CUS-000020'
AND checkInDate >= '2025-05-01'
AND isActivate = 'ACTIVATE';
-----
-- 4b. Thực hiện check-in
-----
EXEC sp_QuickCheckin
    @reservationFormID = @ReservationID,
    @employeeID = 'EMP-000003';
-----------
-- 4c. Xác nhận thông tin check-in
---------
SELECT 
    hc.historyCheckInID AS [Mã check-in],
    hc.checkInDate AS [Thời gian check-in thực tế],
    rf.checkInDate AS [Thời gian check-in dự kiến],
    CASE 
        WHEN hc.checkInDate > rf.checkInDate THEN N'Trễ ' + CAST(DATEDIFF(MINUTE, rf.checkInDate, hc.checkInDate) AS NVARCHAR) + N' phút'
        ELSE N'Sớm ' + CAST(DATEDIFF(MINUTE, hc.checkInDate, rf.checkInDate) AS NVARCHAR) + N' phút' 
    END AS [Tình trạng check-in],
    e.fullName AS [Nhân viên thực hiện],
    r.roomStatus AS [Trạng thái phòng hiện tại]
FROM 
    HistoryCheckin hc
    JOIN ReservationForm rf ON hc.reservationFormID = rf.reservationFormID
    JOIN Employee e ON hc.employeeID = e.employeeID
    JOIN Room r ON rf.roomID = r.roomID
WHERE 
    rf.reservationFormID = @ReservationID;
GO

-- 5. Thêm dịch vụ cho khách trong quá trình lưu trú
DECLARE @ReservationID NVARCHAR(15) = 'RF-000020'; -- Lấy từ bước đặt phòng
DECLARE @ServiceID NVARCHAR(15) = 'HS-000002'; -- ID của dịch vụ bữa sáng
DECLARE @EmployeeID NVARCHAR(15) = 'EMP-000003'; -- Nhân viên thực hiện
---
-- 5a. Lấy giá dịch vụ từ bảng HotelService
---
DECLARE @ServicePrice DECIMAL(18,2);
SELECT @ServicePrice = servicePrice FROM HotelService WHERE hotelServiceId = @ServiceID;
---
-- 5b. Tạo mã dịch vụ mới
---
DECLARE @roomUsageServiceID NVARCHAR(15) = 'RUS-' + RIGHT('000000' + CAST((SELECT COUNT(*) + 1 FROM RoomUsageService) AS NVARCHAR), 6);
---
-- 5c. Thêm dịch vụ vào bảng RoomUsageService
---
INSERT INTO RoomUsageService (
    roomUsageServiceId, quantity, unitPrice, dateAdded,
    hotelServiceId, reservationFormID, employeeID
)
VALUES (
    @roomUsageServiceID, -- Mã sử dụng dịch vụ
    2, -- Số lượng
    @ServicePrice, -- Đơn giá
    GETDATE(), -- Thời điểm sử dụng
    @ServiceID, -- Mã dịch vụ
    @ReservationID, -- Mã đặt phòng
    @EmployeeID -- Nhân viên phục vụ
);
---
-- 5d. Xem lại các dịch vụ đã thêm
---
SELECT 
    rus.roomUsageServiceId AS [Mã sử dụng dịch vụ],
    hs.serviceName AS [Tên dịch vụ],
    sc.serviceCategoryName AS [Loại dịch vụ],
    rus.quantity AS [Số lượng],
    rus.unitPrice AS [Đơn giá],
    rus.totalPrice AS [Thành tiền],
    rus.dateAdded AS [Ngày sử dụng],
    e.fullName AS [Nhân viên phục vụ]
FROM 
    RoomUsageService rus
    JOIN HotelService hs ON rus.hotelServiceId = hs.hotelServiceId
    JOIN ServiceCategory sc ON hs.serviceCategoryID = sc.serviceCategoryID
    JOIN Employee e ON rus.employeeID = e.employeeID
WHERE 
    rus.reservationFormID = @ReservationID
ORDER BY 
    rus.dateAdded;
GO

-- 6. Khi khách trả phòng, thực hiện check-out
DECLARE @ReservationID NVARCHAR(15) = 'RF-000020'; -- Mã đặt phòng từ các bước trước
DECLARE @EmployeeID NVARCHAR(15) = 'EMP-000004'; -- Nhân viên thực hiện check-out

-- 6a. Thực hiện check-out sử dụng stored procedure (tự động tạo mã hóa đơn)
EXEC sp_QuickCheckout
    @reservationFormID = @ReservationID,
    @employeeID = @EmployeeID;

-- 6b. Kiểm tra thông tin hóa đơn thanh toán
SELECT 
    i.invoiceID AS [Mã hóa đơn],
    i.invoiceDate AS [Ngày lập hóa đơn],
    rf.checkInDate AS [Ngày check-in],
    rf.checkOutDate AS [Ngày check-out dự kiến],
    ho.checkOutDate AS [Ngày check-out thực tế],
    DATEDIFF(DAY, hc.checkInDate, ho.checkOutDate) AS [Số ngày lưu trú thực tế],
    r.roomID AS [Số phòng],
    c.fullName AS [Tên khách hàng],
    i.roomCharge AS [Tiền phòng],
    i.servicesCharge AS [Tiền dịch vụ],
    i.totalDue AS [Tổng tiền chưa thuế],
    i.netDue AS [Tổng tiền sau thuế],
    i.netDue - rf.roomBookingDeposit AS [Số tiền cần thanh toán thêm],
    e.fullName AS [Nhân viên thanh toán]
FROM 
    Invoice i
    JOIN ReservationForm rf ON i.reservationFormID = rf.reservationFormID
    JOIN HistoryCheckin hc ON rf.reservationFormID = hc.reservationFormID
    JOIN HistoryCheckOut ho ON rf.reservationFormID = ho.reservationFormID
    JOIN Room r ON rf.roomID = r.roomID
    JOIN Customer c ON rf.customerID = c.customerID
    JOIN Employee e ON ho.employeeID = e.employeeID
WHERE 
    rf.reservationFormID = @ReservationID;

-- 7. Kiểm tra trạng thái phòng sau khi trả
SELECT 
    r.roomID AS [Số phòng],
    r.roomStatus AS [Trạng thái hiện tại],
    rc.roomCategoryName AS [Loại phòng]
FROM 
    Room r
    JOIN ReservationForm rf ON r.roomID = rf.roomID
    JOIN RoomCategory rc ON r.roomCategoryID = rc.roomCategoryID
WHERE 
    rf.reservationFormID = @ReservationID;

-- 8. Kiểm tra lịch sử giao dịch đầy đủ của khách hàng
SELECT 
    c.fullName AS [Tên khách hàng],
    rf.reservationFormID AS [Mã đặt phòng],
    rf.reservationDate AS [Ngày đặt phòng],
    hc.checkInDate AS [Ngày check-in],
    ho.checkOutDate AS [Ngày check-out],
    DATEDIFF(DAY, hc.checkInDate, ho.checkOutDate) AS [Số ngày lưu trú],
    r.roomID AS [Số phòng],
    rc.roomCategoryName AS [Loại phòng],
    rf.roomBookingDeposit AS [Tiền đặt cọc],
    i.roomCharge AS [Tiền phòng],
    i.servicesCharge AS [Tiền dịch vụ],
    i.netDue AS [Tổng tiền cuối],
    e_in.fullName AS [Nhân viên check-in],
    e_out.fullName AS [Nhân viên check-out]
FROM 
    ReservationForm rf
    JOIN Customer c ON rf.customerID = c.customerID
    JOIN Room r ON rf.roomID = r.roomID
    JOIN RoomCategory rc ON r.roomCategoryID = rc.roomCategoryID
    JOIN HistoryCheckin hc ON rf.reservationFormID = hc.reservationFormID
    JOIN HistoryCheckOut ho ON rf.reservationFormID = ho.reservationFormID
    JOIN Invoice i ON rf.reservationFormID = i.reservationFormID
    JOIN Employee e_in ON hc.employeeID = e_in.employeeID
    JOIN Employee e_out ON ho.employeeID = e_out.employeeID
WHERE 
    rf.reservationFormID = @ReservationID;

-- 10. Xem chi tiết dịch vụ đã sử dụng
SELECT 
    hs.serviceName AS [Tên dịch vụ],
    sc.serviceCategoryName AS [Loại dịch vụ],
    rus.quantity AS [Số lượng],
    rus.unitPrice AS [Đơn giá],
    rus.totalPrice AS [Thành tiền],
    rus.dateAdded AS [Ngày sử dụng],
    e.fullName AS [Nhân viên phục vụ]
FROM 
    RoomUsageService rus
    JOIN HotelService hs ON rus.hotelServiceId = hs.hotelServiceId
    JOIN ServiceCategory sc ON hs.serviceCategoryID = sc.serviceCategoryID
    JOIN Employee e ON rus.employeeID = e.employeeID
WHERE 
    rus.reservationFormID = @ReservationID
ORDER BY 
    rus.dateAdded;