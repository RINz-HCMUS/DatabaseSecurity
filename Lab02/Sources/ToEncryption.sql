-- LAB 02
-- Doãn Hoàng Sơn |	22127365
-- Võ Hữu Tuấn    |	22127439

USE master

-- a) Tạo Database
IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'QLBD')
    CREATE DATABASE QLBD;

GO

USE QLBD;
GO

-- b) Tạo các bảng
CREATE TABLE QUOCGIA (
    MAQG VARCHAR(5) PRIMARY KEY,
    TENQG NVARCHAR(60) NOT NULL
);

CREATE TABLE TINH (
    MATINH VARCHAR(5) PRIMARY KEY,
    TENTINH NVARCHAR(100) NOT NULL
);

CREATE TABLE SANVD (
    MASAN VARCHAR(5) PRIMARY KEY,
    TENSAN NVARCHAR(100) NOT NULL,
    DIACHI NVARCHAR(200)
);

CREATE TABLE CAULACBO (
    MACLB VARCHAR(5) PRIMARY KEY,
    TENCLB NVARCHAR(100) NOT NULL,
    MASAN VARCHAR(5) NOT NULL,
    MATINH VARCHAR(5) NOT NULL,
    FOREIGN KEY (MASAN) REFERENCES SANVD(MASAN),
    FOREIGN KEY (MATINH) REFERENCES TINH(MATINH)
);

CREATE TABLE CAUTHU (
    MACT NUMERIC PRIMARY KEY IDENTITY(1,1),
    HOTEN NVARCHAR(100) NOT NULL,
    VITRI NVARCHAR(20) NOT NULL,
    NGAYSINH DATETIME,
    DIACHI NVARCHAR(200),
    MACLB VARCHAR(5) NOT NULL,
    MAQG VARCHAR(5) NOT NULL,
    SO INT NOT NULL,
    FOREIGN KEY (MACLB) REFERENCES CAULACBO(MACLB),
    FOREIGN KEY (MAQG) REFERENCES QUOCGIA(MAQG)
);

CREATE TABLE HUANLUYENVIEN (
    MAHLV VARCHAR(5) PRIMARY KEY,
    TENHLV NVARCHAR(100) NOT NULL,
    NGAYSINH DATETIME,
    DIACHI NVARCHAR(200),
    DIENTHOAI NVARCHAR(20),
    MAQG VARCHAR(5) NOT NULL,
    FOREIGN KEY (MAQG) REFERENCES QUOCGIA(MAQG)
);

CREATE TABLE HLV_CLB (
    MAHLV VARCHAR(5),
    MACLB VARCHAR(5),
    VAITRO NVARCHAR(100) NOT NULL,
    PRIMARY KEY (MAHLV, MACLB),
    FOREIGN KEY (MAHLV) REFERENCES HUANLUYENVIEN(MAHLV),
    FOREIGN KEY (MACLB) REFERENCES CAULACBO(MACLB)
);

CREATE TABLE TRANDAU (
    MATRAN NUMERIC PRIMARY KEY IDENTITY(1,1),
    NAM INT NOT NULL,
    VONG INT NOT NULL,
    NGAYTD DATETIME NOT NULL,
    MACLB1 VARCHAR(5) NOT NULL,
    MACLB2 VARCHAR(5) NOT NULL,
    MASAN VARCHAR(5) NOT NULL,
    KETQUA VARCHAR(5) NOT NULL,
    FOREIGN KEY (MACLB1) REFERENCES CAULACBO(MACLB),
    FOREIGN KEY (MACLB2) REFERENCES CAULACBO(MACLB),
    FOREIGN KEY (MASAN) REFERENCES SANVD(MASAN)
);

CREATE TABLE BANGXH (
    MACLB VARCHAR(5),
    NAM INT,
    VONG INT,
    SOTRAN INT NOT NULL,
    THANG INT NOT NULL,
    HOA INT NOT NULL,
    THUA INT NOT NULL,
    HIEUSO VARCHAR(5) NOT NULL,
    DIEM INT NOT NULL,
    HANG INT NOT NULL,
    PRIMARY KEY (MACLB, NAM, VONG),
    FOREIGN KEY (MACLB) REFERENCES CAULACBO(MACLB)
);

GO

-- c) Nhập dữ liệu
INSERT INTO QUOCGIA (MAQG, TENQG) VALUES
('VN' , N'Việt Nam'),
('ANH', N'Anh Quốc'),
('TBN', N'Tây Ban Nha'),
('BDN', N'Bồ Đào Nha'),
('BRA', N'Brazil'),
('ITA', N'Ý'),
('THA', N'Thái Lan');

INSERT INTO TINH (MATINH, TENTINH) VALUES
('BD', N'Bình Dương'),
('GL', N'Gia Lai'),
('DN', N'Đà Nẵng'),
('KH', N'Khánh Hòa'),
('PY', N'Phú Yên'),
('LA', N'Long An');

INSERT INTO SANVD (MASAN, TENSAN, DIACHI) VALUES
('GD', N'Gò Đậu'    , N'123 QL1, TX Thủ Dầu Một, Bình Dương'),
('PL', N'Pleiku'    , N'22 Hồ Tùng Mậu, Thống Nhất, Thị xã Pleiku, Gia Lai'),
('CL', N'Chi Lăng'  , N'127 Võ Văn Tần, Đà Nẵng'),
('NT', N'Nha Trang' , N'128 Phan Chu Trinh, Nha Trang, Khánh Hòa'),
('TH', N'Tuy Hòa'   , N'57 Trường Chinh, Tuy Hòa, Phú Yên'),
('LA', N'Long An'   , N'102 Hùng Vương, Tp Tân An, Long An');


INSERT INTO CAULACBO (MACLB, TENCLB, MASAN, MATINH) VALUES
('BBD' , N'BECAMEX BÌNH DƯƠNG'      , 'GD', 'BD'),
('HAGL', N'HOÀNG ANH GIA LAI'       , 'PL', 'GL'),
('SDN' , N'SHB ĐÀ NẴNG'             , 'CL', 'DN'),
('KKH' , N'KHATOCO KHÁNH HÒA'       , 'NT', 'KH'),
('TPY' , N'THÉP PHÚ YÊN'            , 'TH', 'PY'),
('GDT' , N'GẠCH ĐỒNG TÂM LONG AN'   , 'LA', 'LA');


INSERT INTO HUANLUYENVIEN (MAHLV, TENHLV, NGAYSINH, DIACHI, DIENTHOAI, MAQG) VALUES
('HLV01', N'Vital'          , '10-15-1955', NULL, '0918011075' , 'BDN'),
('HLV02', N'Lê Huỳnh Đức'   , '05-20-1972', NULL, '01223456789', 'VN'),
('HLV03', N'Kiatisuk'       , '12-11-1970', NULL, '01990123456', 'THA'),
('HLV04', N'Hoàng Anh Tuấn' , '06-10-1970', NULL, '0989112233' , 'VN'),
('HLV05', N'Trần Công Minh' , '07-07-1973', NULL, '0909099990' , 'VN'),
('HLV06', N'Trần Văn Phúc'  , '03-02-1965', NULL, '01650101234', 'VN');


INSERT INTO HLV_CLB (MAHLV, MACLB, VAITRO) VALUES
('HLV01', 'BBD' , N'HLV Chính'),
('HLV02', 'SDN' , N'HLV Chính'),
('HLV03', 'HAGL', N'HLV Chính'),
('HLV04', 'KKH' , N'HLV Chính'),
('HLV05', 'GDT' , N'HLV Chính'),
('HLV06', 'BBD' , N'HLV thủ môn');

INSERT INTO CAUTHU (HOTEN, VITRI, NGAYSINH, DIACHI, MACLB, MAQG, SO) VALUES
(N'Nguyễn Vũ Phong'	 , N'Tiền vệ' , '02-20-1990', NULL, 'BBD' , 'VN', 17),
(N'Nguyễn Công Vinh' , N'Tiền đạo', '03-10-1992', NULL, 'HAGL', 'VN', 9),
(N'Trần Tấn Tài'	 , N'Tiền vệ' , '11-12-1989', NULL, 'BBD' , 'VN', 8),
(N'Phan Hồng Sơn'	 , N'Thủ môn' , '06-10-1991', NULL, 'HAGL', 'VN', 1),
(N'Ronaldo'			 , N'Tiền vệ' , '12-12-1989', NULL, 'SDN' , 'BRA', 7),
(N'Robinho'			 , N'Tiền vệ' , '10-12-1989', NULL, 'SDN' , 'BRA', 8),
(N'Vidic'			 , N'Hậu vệ'  , '10-15-1987', NULL, 'HAGL', 'ANH', 3),
(N'Trần Văn Santos'	 , N'Thủ môn' , '10-21-1990', NULL, 'BBD' , 'BRA', 1),
(N'Nguyễn Trường Sơn', N'Hậu vệ'  , '08-26-1993', NULL, 'BBD' , 'VN', 4);


INSERT INTO TRANDAU (NAM, VONG, NGAYTD, MACLB1, MACLB2, MASAN, KETQUA) VALUES
(2009, 1, '02-07-2009', 'BBD', 'SDN', 'GD', '3-0'),
(2009, 1, '02-07-2009', 'KKH', 'GDT', 'NT', '1-1'),
(2009, 2, '02-16-2009', 'SDN', 'KKH', 'CL', '2-2'),
(2009, 2, '02-16-2009', 'TPY', 'BBD', 'TH', '5-0'),
(2009, 3, '03-01-2009', 'TPY', 'GDT', 'TH', '0-2'),
(2009, 3, '03-01-2009', 'KKH', 'BBD', 'NT', '0-1'),
(2009, 4, '03-07-2009', 'KKH', 'TPY', 'NT', '1-0'),
(2009, 4, '03-07-2009', 'BBD', 'GDT', 'GD', '2-2');


INSERT INTO BANGXH (MACLB, NAM, VONG, SOTRAN, THANG, HOA, THUA, HIEUSO, DIEM, HANG) VALUES
('BBD', 2009, 1, 1, 1, 0, 0, '3-0', 3, 1),
('KKH', 2009, 1, 1, 0, 1, 0, '1-1', 1, 2),
('GDT', 2009, 1, 1, 0, 1, 0, '1-1', 1, 3),
('TPY', 2009, 1, 0, 0, 0, 0, '0-0', 0, 4),
('SDN', 2009, 1, 1, 0, 0, 1, '0-3', 0, 5),

('TPY', 2009, 2, 1, 1, 0, 0, '5-0', 3, 1),
('BBD', 2009, 2, 2, 1, 0, 1, '3-5', 3, 2),
('KKH', 2009, 2, 2, 0, 2, 0, '3-3', 2, 3),
('GDT', 2009, 2, 1, 0, 1, 0, '1-1', 1, 4),
('SDN', 2009, 2, 2, 1, 1, 0, '2-5', 1, 5),

('BBD', 2009, 3, 3, 2, 0, 1, '4-5', 6, 1),
('GDT', 2009, 3, 2, 1, 1, 0, '3-1', 4, 2),
('TPY', 2009, 3, 2, 1, 0, 1, '5-2', 3, 3),
('KKH', 2009, 3, 3, 0, 2, 1, '3-4', 2, 4),
('SDN', 2009, 3, 2, 1, 1, 0, '2-5', 1, 5),

('BBD', 2009, 4, 4, 2, 1, 1, '6-7', 7, 1),
('GDT', 2009, 4, 3, 1, 2, 0, '5-1', 5, 2),
('KKH', 2009, 4, 4, 1, 2, 1, '4-4', 5, 3),
('TPY', 2009, 4, 3, 1, 0, 2, '5-3', 3, 4),
('SDN', 2009, 4, 2, 1, 1, 0, '2-5', 1, 5);

GO

-- e) Stored procedure
CREATE PROCEDURE SP_SEL_NO_ENCRYPT
    @TenCLB NVARCHAR(100),
    @TenQG NVARCHAR(60)
AS
BEGIN
    SELECT MACT, HOTEN, NGAYSINH, DIACHI, VITRI
    FROM CAUTHU CT
    JOIN CAULACBO CLB ON CT.MACLB = CLB.MACLB
    JOIN QUOCGIA QG ON CT.MAQG = QG.MAQG
    WHERE CLB.TENCLB = @TenCLB AND QG.TENQG = @TenQG;
END;

GO

CREATE PROCEDURE SP_SEL_ENCRYPT
    @TenCLB NVARCHAR(100),
    @TenQG NVARCHAR(60)
WITH ENCRYPTION -- Mã hóa nội dung Stored Procedure
AS
BEGIN
    SELECT MACT, HOTEN, NGAYSINH, DIACHI, VITRI
    FROM CAUTHU CT
    JOIN CAULACBO CLB ON CT.MACLB = CLB.MACLB
    JOIN QUOCGIA QG ON CT.MAQG = QG.MAQG
    WHERE CLB.TENCLB = @TenCLB AND QG.TENQG = @TenQG;
END;


GO

-- g) Thực thi stored procedure
EXEC SP_SEL_NO_ENCRYPT N'SHB ĐÀ NẴNG', 'Brazil';
EXEC SP_SEL_ENCRYPT N'SHB Đà Nẵng', 'Brazil';

-- Xem mã nguồn stored procedure
EXEC sp_helptext 'SP_SEL_NO_ENCRYPT';
EXEC sp_helptext 'SP_SEL_ENCRYPT';


-- h) Giả sử trong CSDL có 100 stored procedure, có cách nào để Encrypt toàn bộ 100 stored procedure trước khi cài đặt cho khách hàng không? Nếu có, hãy mô tả các bước thực hiện. 
-- Có thực hiện thủ công hoặc sử dụng vòng for để chạy như sau:
-- Duyệt qua tất cả stored procedure:
--	Lưu tên của stored procedure và mã nguồn của nó
--	Xóa stored procedure đó
--	Tạo stored procedure mới với tên và mã nguồn đã lưu cùng với "WITH ENCRYPTION"

GO

-- j) Tạo và phân quyền trên Stored Procedure 
-- Tạo Stored Procedure 
--1. Cho biết mã số, họ tên, ngày sinh, địa chỉ và vị trí của các cầu thủ thuộc đội 
--bóng “SHB Đà Nẵng” có quốc tịch “Brazil”.
CREATE PROCEDURE SPCau1 
    @TenCLB NVARCHAR(100),
    @TenQG NVARCHAR(60)
AS
BEGIN
    SELECT MACT, HOTEN, NGAYSINH, DIACHI, VITRI
    FROM CAUTHU CT
    JOIN CAULACBO CLB ON CT.MACLB = CLB.MACLB
    JOIN QUOCGIA QG ON CT.MAQG = QG.MAQG
    WHERE CLB.TENCLB = @TenCLB AND QG.TENQG = @TenQG;
END;

GO

--2. Cho biết kết quả (MATRAN, NGAYTD, TENSAN, TENCLB1, TENCLB2, 
--KETQUA)  các trận đấu vòng 3 của mùa bóng năm 2009. 
CREATE PROCEDURE SPCau2 
    @Vong INT,
    @Nam INT
AS
BEGIN
    SELECT TD.MATRAN, TD.NGAYTD, SVD.TENSAN, CLB1.TENCLB AS TENCLB1, CLB2.TENCLB AS TENCLB2, TD.KETQUA
    FROM TRANDAU TD
    JOIN SANVD SVD ON TD.MASAN = SVD.MASAN
    JOIN CAULACBO CLB1 ON TD.MACLB1 = CLB1.MACLB
    JOIN CAULACBO CLB2 ON TD.MACLB2 = CLB2.MACLB
    WHERE TD.VONG = @Vong AND TD.NAM = @Nam;
END;

GO

--3. Cho biết mã huấn luyện viên, họ tên, ngày sinh, địa chỉ, vai trò và tên CLB 
--đang làm việc của các huấn luyện viên có quốc tịch “Việt Nam”. 
CREATE PROCEDURE SPCau3 
    @QuocGia NVARCHAR(60)
AS
BEGIN
    SELECT HLV.MAHLV, HLV.TENHLV, HLV.NGAYSINH, HLV.DIACHI, HLV_CLB.VAITRO, CLB.TENCLB
    FROM HUANLUYENVIEN HLV
    JOIN HLV_CLB ON HLV.MAHLV = HLV_CLB.MAHLV
    JOIN CAULACBO CLB ON HLV_CLB.MACLB = CLB.MACLB
    WHERE HLV.MAQG = @QuocGia;
END;

GO

--4. Cho biết mã câu lạc bộ, tên câu lạc bộ, tên sân vận động, địa chỉ và số lượng 
--cầu thủ nước ngoài (có quốc tịch khác “Việt Nam”) tương ứng của các câu lạc bộ 
--có nhiều hơn 2 cầu thủ nước ngoài. 
CREATE PROCEDURE SPCau4 
    @SoLuongCauThu INT
AS
BEGIN
    SELECT CLB.MACLB, CLB.TENCLB, SVD.TENSAN, SVD.DIACHI, COUNT(CT.MACT) AS SoLuongCauThuNuocNgoai
    FROM CAULACBO CLB
    JOIN SANVD SVD ON CLB.MASAN = SVD.MASAN
    JOIN CAUTHU CT ON CLB.MACLB = CT.MACLB
    WHERE CT.MAQG <> 'VN'
    GROUP BY CLB.MACLB, CLB.TENCLB, SVD.TENSAN, SVD.DIACHI
    HAVING COUNT(CT.MACT) >= @SoLuongCauThu;
END;

GO

--5. Cho biết tên tỉnh, số lượng cầu thủ đang thi đấu ở vị trí tiền đạo trong các câu lạc 
--bộ thuộc địa bàn tỉnh đó quản lý. 
CREATE PROCEDURE SPCau5 
AS
BEGIN
    SELECT T.TENTINH, COUNT(CT.MACT) AS SoLuongTienDao
    FROM TINH T
    JOIN CAULACBO CLB ON T.MATINH = CLB.MATINH
    JOIN CAUTHU CT ON CLB.MACLB = CT.MACLB
    WHERE CT.VITRI = N'Tiền đạo'
    GROUP BY T.TENTINH;
END;

GO

--6. Cho biết tên câu lạc bộ, tên tỉnh mà CLB đang đóng nằm ở vị trí cao nhất của 
--bảng xếp hạng của vòng 3, năm 2009. 
CREATE PROCEDURE SPCau6 
    @Vong INT,
    @Nam INT
AS
BEGIN
    SELECT BX.MACLB, CLB.TENCLB, T.TENTINH
    FROM BANGXH BX
    JOIN CAULACBO CLB ON BX.MACLB = CLB.MACLB
    JOIN TINH T ON CLB.MATINH = T.MATINH
    WHERE BX.VONG = @Vong AND BX.NAM = @Nam
    AND BX.HANG = 1;
END;

GO


--7. Cho biết tên huấn luyện viên đang nắm giữ một vị trí trong một câu lạc bộ mà 
--chưa có số điện thoại. 
CREATE PROCEDURE SPCau7 
AS
BEGIN
    SELECT MAHLV, TENHLV, NGAYSINH, DIACHI
    FROM HUANLUYENVIEN
    WHERE DIENTHOAI IS NULL OR DIENTHOAI = '';
END;

GO

--8. Liệt kê các huấn luyện viên thuộc quốc gia Việt Nam chưa làm công tác huấn 
--luyện tại bất kỳ một câu lạc bộ nào. 
CREATE PROCEDURE SPCau8 
AS
BEGIN
    SELECT HLV.MAHLV, HLV.TENHLV, HLV.NGAYSINH, HLV.DIACHI
    FROM HUANLUYENVIEN HLV
    LEFT JOIN HLV_CLB HLVCLB ON HLV.MAHLV = HLVCLB.MAHLV
    WHERE HLV.MAQG = 'VN' AND HLVCLB.MAHLV IS NULL;
END;

GO

--9. Cho biết danh sách các trận đấu (NGAYTD, TENSAN, TENCLB1, TENCLB2, 
--KETQUA) của câu lạc bộ CLB đang xếp hạng cao nhất tính đến hết vòng 3 năm 
--2009. 
CREATE PROCEDURE SPCau9 
AS
BEGIN
    SELECT TD.NGAYTD, SVD.TENSAN, CLB1.TENCLB AS TENCLB1, CLB2.TENCLB AS TENCLB2, TD.KETQUA
    FROM TRANDAU TD
    JOIN SANVD SVD ON TD.MASAN = SVD.MASAN
    JOIN CAULACBO CLB1 ON TD.MACLB1 = CLB1.MACLB
    JOIN CAULACBO CLB2 ON TD.MACLB2 = CLB2.MACLB
    WHERE (TD.MACLB1 IN (SELECT MACLB FROM BANGXH WHERE VONG = 3 AND NAM = 2009 AND HANG = 1) 
    OR TD.MACLB2 IN (SELECT MACLB FROM BANGXH WHERE VONG = 3 AND NAM = 2009 AND HANG = 1));
END;

GO

--10. Cho biết danh sách các trận đấu (NGAYTD, TENSAN, TENCLB1, TENCLB2, 
--KETQUA) của câu lạc bộ CLB có thứ hạng thấp nhất trong bảng xếp hạng vòng 
--3 năm 2009



CREATE PROCEDURE SPCau10
    @Vong INT,
    @Nam INT
AS
BEGIN
    -- Bước 1: Tìm CLB có thứ hạng thấp nhất trong vòng @Vong của năm @Nam
    DECLARE @CLBThapNhat VARCHAR(5);

    SELECT TOP 1 @CLBThapNhat = MACLB
    FROM BANGXH
    WHERE NAM = @Nam AND VONG = @Vong
    ORDER BY HANG DESC;  -- CLB có hạng cao nhất trong danh sách giảm dần (tức thấp nhất thực tế)

    -- Kiểm tra nếu không tìm thấy CLB nào
    IF @CLBThapNhat IS NULL
    BEGIN
        PRINT 'Không có dữ liệu của vòng' + @Vong + 'trong' + @Nam;
        RETURN;
    END

    -- Bước 2: Xuất ra tất cả trận đấu của CLB có hạng thấp nhất
    SELECT TD.NGAYTD, SVD.TENSAN, CLB1.TENCLB AS TENCLB1, CLB2.TENCLB AS TENCLB2, TD.KETQUA
    FROM TRANDAU TD
    JOIN SANVD SVD ON TD.MASAN = SVD.MASAN
    JOIN CAULACBO CLB1 ON TD.MACLB1 = CLB1.MACLB
    JOIN CAULACBO CLB2 ON TD.MACLB2 = CLB2.MACLB
    WHERE TD.NAM = @Nam
    AND (
        TD.MACLB1 = @CLBThapNhat
        OR TD.MACLB2 = @CLBThapNhat
    );
END;
GO



--GO
---- Test 
--USE QLBongDa;
--EXEC SPCau1 N'SHB Đà Nẵng', N'Brazil';

--EXEC SPCau2 3, 2009;

--EXEC SPCau3 N'Việt Nam';

--EXEC SPCau4 2;

--EXEC SPCau5;

--EXEC SPCau6 3, 2009;

--EXEC SPCau7;

--EXEC SPCau8;

--EXEC SPCau9;

--EXEC SPCau10 3, 2009;


GO

-- Lấy danh sách các stored procedure no encrypt
SELECT p.name AS StoredProcedureName
FROM sys.procedures p
JOIN sys.sql_modules m ON p.object_id = m.object_id
WHERE m.definition IS NOT NULL -- no encrypt

GO

-- Kiểm tra mã nguồn từng stored procedure
EXEC sp_helptext 'SPCau1';
EXEC sp_helptext 'SPCau2';
EXEC sp_helptext 'SPCau3';
EXEC sp_helptext 'SPCau4';
EXEC sp_helptext 'SPCau5';
EXEC sp_helptext 'SPCau6';
EXEC sp_helptext 'SPCau7';
EXEC sp_helptext 'SPCau8';
EXEC sp_helptext 'SPCau9';
EXEC sp_helptext 'SPCau10';

GO

-- h)



GO

-- Test 
SELECT *
FROM sys.procedures

EXEC sp_helptext 'SPCau1';
EXEC SPCau1 N'SHB Đà Nẵng', N'Brazil';

EXEC sp_helptext 'SPCau2';
EXEC sp_helptext 'SPCau3';
EXEC sp_helptext 'SPCau4';
EXEC sp_helptext 'SPCau5';
EXEC sp_helptext 'SPCau6';
EXEC sp_helptext 'SPCau7';
EXEC sp_helptext 'SPCau8';
EXEC sp_helptext 'SPCau9';
EXEC sp_helptext 'SPCau10';


-- Xóa tất cả stored procedure đang có
DECLARE @SPName NVARCHAR(255);
DECLARE cur CURSOR FOR 
SELECT name FROM sys.procedures; 

OPEN cur;
FETCH NEXT FROM cur INTO @SPName;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC('DROP PROCEDURE IF EXISTS ' + @SPName);
    PRINT 'Đã xóa Stored Procedure: ' + @SPName;
    FETCH NEXT FROM cur INTO @SPName;
END;

CLOSE cur;
DEALLOCATE cur;
