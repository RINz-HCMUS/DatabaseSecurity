-- LAB 04
-- Doãn Hoàng Sơn |	22127365
-- Võ Hữu Tuấn    |	22127439


--  a. tạo Database có tên QLSVNhom
USE MASTER

GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'QLSVNhom')
BEGIN
    CREATE DATABASE QLSVNhom;
END;

GO

USE QLSVNhom;

GO

-- b. tạo các Table SINHVIEN, NHANVIEN, LOP, HOCPHAN, BANGDIEM

-- Tạo bảng SINHVIEN
CREATE TABLE SINHVIEN (
    MASV VARCHAR(20) PRIMARY KEY,
    HOTEN NVARCHAR(100) NOT NULL,
    NGAYSINH DATETIME,
    DIACHI NVARCHAR(200),
    MALOP VARCHAR(20),
    TENDN NVARCHAR(100) UNIQUE NOT NULL,
    MATKHAU VARBINARY(MAX) NOT NULL
);

GO

-- Tạo bảng NHANVIEN
CREATE TABLE NHANVIEN (
    MANV VARCHAR(20) PRIMARY KEY,
    HOTEN NVARCHAR(100) NOT NULL,
    EMAIL VARCHAR(20),
    LUONG VARBINARY(MAX),
    TENDN NVARCHAR(100) UNIQUE NOT NULL,
    MATKHAU VARBINARY(MAX) NOT NULL,
    PUBKEY VARCHAR(20) NOT NULL
);

GO

-- Tạo bảng LOP
CREATE TABLE LOP (
    MALOP VARCHAR(20) PRIMARY KEY,
    TENLOP NVARCHAR(100) NOT NULL,
    MANV VARCHAR(20),
    FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
);

GO

-- Tạo bảng HOCPHAN
CREATE TABLE HOCPHAN (
    MAHP VARCHAR(20) PRIMARY KEY,
    TENHP NVARCHAR(100) NOT NULL,
    SOTC INT
);

GO

-- Tạo bảng BANGDIEM
CREATE TABLE BANGDIEM (
    MASV VARCHAR(20),
    MAHP VARCHAR(20),
    DIEMTHI VARBINARY(MAX),
    PRIMARY KEY (MASV, MAHP),
    FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV),
    FOREIGN KEY (MAHP) REFERENCES HOCPHAN(MAHP)
);

GO

-- Thêm học phần
INSERT INTO HOCPHAN (MAHP, TENHP, SOTC)
VALUES 
    ('BMCSDL', N'Bảo mật cơ sở dữ liệu', 4),
    ('MHUD', N'Mã hóa ứng dụng', 4),
	('MMTNC', N'Mạng máy tính nâng cao', 4);

GO

-- b. Viết các Stored procedure

-- i. SP_INS_PUBLIC_NHANVIEN
-- Stored dùng để thêm mới dữ liệu (Insert) vào table NHANVIEN
CREATE PROCEDURE SP_INS_PUBLIC_NHANVIEN
    @MANV VARCHAR(20),
    @HOTEN NVARCHAR(100),
    @EMAIL VARCHAR(20),
    @LUONGCB VARBINARY(MAX),	-- Đã Encryp từ client
    @TENDN NVARCHAR(100),
    @MK VARBINARY(MAX),			-- Đã Hash từ client
	@PUB VARCHAR(20)			-- Đã tạo trên client
AS
BEGIN
	SET NOCOUNT ON;

    -- Kiểm tra nhân viên
    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV OR TENDN = @TENDN)
    BEGIN
        PRINT N'Lỗi: Mã nhân viên hoặc tên đăng nhập đã tồn tại!';
        RETURN;
    END

   -- Thêm vào bảng NHANVIEN
    INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, LUONG, TENDN, MATKHAU, PUBKEY)
    VALUES (@MANV, @HOTEN, @EMAIL, @LUONGCB, @TENDN, @MK, @PUB);

    PRINT N'Nhân viên đã được thêm thành công.';
END

GO

-- ii. SP_SEL_PUBLIC_NHANVIEN
-- Stored dùng để truy vấn dữ liệu nhân viên (NHANVIEN)
CREATE PROCEDURE SP_SEL_PUBLIC_ENCRYPT_NHANVIEN
    @MANV VARCHAR(100),
    @MK VARBINARY(MAX)    -- Đã hash từ client
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  MANV, 
			HOTEN, 
			EMAIL, 
			LUONG, -- chưa giải mã
			TENDN
    FROM NHANVIEN
    WHERE MANV = @MANV AND MATKHAU = @MK;
END

GO

-- d. Procedure hỗ trợ app

-- i. SP_INS_PUBLIC_ENCRYPT_BANGDIEM
-- Hàm thêm, chỉnh sửa điểm sinh viên
CREATE PROCEDURE SP_INS_PUBLIC_ENCRYPT_BANGDIEM
	@MANV VARCHAR(20),
	@MASV VARCHAR(20),
    @MAHP VARCHAR(20),
    @DIEMTHI VARBINARY(MAX)   -- Đã được mã hóa từ client
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra sinh viên 
    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MASV = @MASV)
    BEGIN
        PRINT N'Lỗi: Sinh viên không tồn tại!';
        RETURN;
    END

	-- Kiểm tra học phần
    IF NOT EXISTS (SELECT 1 FROM HOCPHAN WHERE MAHP = @MAHP)
    BEGIN
        PRINT N'Lỗi: Học phần không tồn tại!';
        RETURN;
    END

    -- Kiểm tra nhân viên có quyền quản lý điểm của sinh viên
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MANV = @MANV AND MALOP = (SELECT MALOP FROM SINHVIEN WHERE MASV = @MASV))
    BEGIN
        PRINT N'Lỗi: Nhân viên không có quyền quản lý điểm của sinh viên này!';
        RETURN;
    END

    -- Cập nhật hoặc thêm điểm
    IF EXISTS (SELECT 1 FROM BANGDIEM WHERE MASV = @MASV AND MAHP = @MAHP)
    BEGIN
        UPDATE BANGDIEM
        SET DIEMTHI = @DIEMTHI
        WHERE MASV = @MASV AND MAHP = @MAHP;
        PRINT N'Cập nhật điểm thành công.';
    END
    ELSE
    BEGIN
        INSERT INTO BANGDIEM (MASV, MAHP, DIEMTHI)
        VALUES (@MASV, @MAHP, @DIEMTHI);
        PRINT N'Thêm điểm thành công.';
    END
END

GO

-- ii SP_SEL_PUBLIC_ENCRYPT_BANGDIEM 
-- Hàm xem điểm sinh viên (Chỉ hiển thị các điểm được chấm bởi Nhân viên đó)
CREATE PROCEDURE SP_SEL_PUBLIC_ENCRYPT_BANGDIEM
	 @MANV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        B.MASV,
        S.HOTEN,
        B.MAHP,
        H.TENHP,
        B.DIEMTHI -- Điểm chưa được giải mã
    FROM BANGDIEM B
    JOIN SINHVIEN S ON B.MASV = S.MASV
	JOIN LOP L ON L.MALOP = S.MALOP
    JOIN HOCPHAN H ON B.MAHP = H.MAHP
    WHERE L.MANV = @MANV AND B.DIEMTHI IS NOT NULL; 
END
GO

---- Kiểm tra ----

-- Kiểm thông tin trong NHANVIEN
SELECT * FROM NHANVIEN;

SELECT * FROM LOP;

SELECT * FROM SINHVIEN;

SELECT * FROM HOCPHAN;

SELECT * FROM BANGDIEM;

-- Truy vấn thông tin của NHANVIEN
EXEC SP_SEL_PUBLIC_ENCRYPT_NHANVIEN 'NV01', 0x2F3309423FD7FC1100241B801FE95659465701C1
EXEC SP_SEL_PUBLIC_ENCRYPT_NHANVIEN 'NV02', 0x689307D2FC53AF0FB941BC1BB42737CE4F3EF540

-- Truy vấn điểm
EXEC SP_SEL_PUBLIC_ENCRYPT_BANGDIEM 'NV01';
EXEC SP_SEL_PUBLIC_ENCRYPT_BANGDIEM 'NV02';
