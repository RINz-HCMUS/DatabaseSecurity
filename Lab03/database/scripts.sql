-- LAB 03
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

-- c. Viết các Stored procedure

-- i. SP_INS_PUBLIC_NHANVIEN
-- Stored dùng để thêm mới dữ liệu (Insert) vào table NHANVIEN

CREATE PROCEDURE SP_INS_PUBLIC_NHANVIEN
    @MANV VARCHAR(20),
    @HOTEN NVARCHAR(100),
    @EMAIL VARCHAR(20),
    @LUONGCB INT,
    @TENDN NVARCHAR(100),
    @MK NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;  

    DECLARE @HASHED_MK VARBINARY(MAX)
    DECLARE @ENCRYPTED_LUONG VARBINARY(MAX)
    DECLARE @PUBKEY_NAME VARCHAR(20)
    DECLARE @SQL NVARCHAR(MAX)

    -- Kiểm tra nếu nhân viên đã tồn tại
    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV OR TENDN = @TENDN)
    BEGIN
        PRINT 'Lỗi: Mã nhân viên hoặc tên đăng nhập đã tồn tại!';
        RETURN;
    END

    -- Mã hóa mật khẩu bằng SHA1
    PRINT 'Mã hóa mật khẩu bằng SHA1...';
    SET @HASHED_MK = HASHBYTES('SHA1', @MK)
    PRINT 'Mật khẩu đã được mã hóa.';

    -- Tạo tên khóa Public Key theo MANV
    SET @PUBKEY_NAME = @MANV

    -- Nếu khóa RSA cho nhân viên đã tồn tại, xóa đi trước khi tạo mới
    IF EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = @PUBKEY_NAME)
    BEGIN
        PRINT 'Khóa RSA đã tồn tại, đang xóa...';
        SET @SQL = 'DROP ASYMMETRIC KEY ' + QUOTENAME(@PUBKEY_NAME) + ';'
        EXEC sp_executesql @SQL;
        PRINT 'Khóa RSA cũ đã được xóa.';
    END

    -- **Sửa lỗi: Tạo khóa RSA với thuật toán đúng (RSA_2048)**
    PRINT 'Đang tạo khóa RSA mới...';
    SET @SQL = '
        CREATE ASYMMETRIC KEY ' + QUOTENAME(@PUBKEY_NAME) + '
        WITH ALGORITHM = RSA_2048  
        ENCRYPTION BY PASSWORD = ''' + @MK + ''';'
    EXEC sp_executesql @SQL;
    PRINT 'Khóa RSA mới đã được tạo.';

    -- Kiểm tra xem khóa đã tạo thành công chưa
    IF NOT EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = @PUBKEY_NAME)
    BEGIN
        PRINT 'Lỗi: Tạo khóa RSA không thành công!';
        RETURN;
    END

    -- **Sửa lỗi: Mã hóa lương bằng khóa RSA**
    PRINT 'Đang mã hóa lương bằng khóa RSA mới...';
    SET @ENCRYPTED_LUONG = ENCRYPTBYASYMKEY(ASYMKEY_ID(@PUBKEY_NAME), CAST(@LUONGCB AS NVARCHAR(100)));

    -- Kiểm tra nếu mã hóa thất bại
    IF @ENCRYPTED_LUONG IS NULL
    BEGIN
        PRINT 'Lỗi: Mã hóa lương không thành công!';
        RETURN;
    END
    PRINT 'Lương đã được mã hóa thành công.';

    -- Chèn nhân viên vào bảng
    PRINT 'Đang thêm nhân viên vào bảng NHANVIEN...';
    INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, LUONG, TENDN, MATKHAU, PUBKEY)
    VALUES (@MANV, @HOTEN, @EMAIL, @ENCRYPTED_LUONG, @TENDN, @HASHED_MK, @PUBKEY_NAME);
    PRINT 'Nhân viên đã được thêm thành công.';
END

GO

--- Test ---

-- Thêm nhân viên
EXEC SP_INS_PUBLIC_NHANVIEN 'NV01', N'NGUYEN VAN A', 'NVA@', 3000000, 'NVA', 'abcd12';
EXEC SP_INS_PUBLIC_NHANVIEN 'NV02', N'Tran Van B', 'TVB@', 5000000, 'TVB', 'abc123';
GO

-- Kiểm thông tin trong NHANVIEN
SELECT * FROM NHANVIEN;

------

GO

-- ii. SP_SEL_PUBLIC_NHANVIEN
-- Stored dùng để truy vấn dữ liệu nhân viên (NHANVIEN)
CREATE PROCEDURE SP_SEL_PUBLIC_NHANVIEN
    @TENDN NVARCHAR(100),
    @MK NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MANV VARCHAR(20)
    DECLARE @HOTEN NVARCHAR(100)
    DECLARE @EMAIL VARCHAR(20)
    DECLARE @ENCRYPTED_LUONG VARBINARY(MAX)
    DECLARE @LUONGCB NVARCHAR(100)
    DECLARE @PUBKEY_NAME VARCHAR(20)
    DECLARE @SQL NVARCHAR(MAX)

    -- Lấy thông tin nhân viên
    SELECT 
        @MANV = MANV,
        @HOTEN = HOTEN,
        @EMAIL = EMAIL,
        @ENCRYPTED_LUONG = LUONG,
        @PUBKEY_NAME = PUBKEY
    FROM NHANVIEN
    WHERE TENDN = @TENDN;

    -- Kiểm tra nhân viên đã được tạo chưa
    IF @MANV IS NULL
    BEGIN
        PRINT 'Loi: Nhan vien khong ton tai!';
        RETURN;
    END

    -- Kiểm tra khóa RSA
    IF NOT EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = @PUBKEY_NAME)
    BEGIN
        PRINT 'Loi: Khoa RSA khong ton tai!';
        RETURN;
    END

    -- Giải mã lương
    SET @LUONGCB = CONVERT(NVARCHAR(MAX), DECRYPTBYASYMKEY(ASYMKEY_ID(@PUBKEY_NAME), @ENCRYPTED_LUONG, @MK));

	-- Kiểm tra nếu giải mã thất bại
    IF @LUONGCB IS NULL
    BEGIN
        PRINT 'Loi: Giai ma LUONG that bai!';
        RETURN;
    END

    -- Trả về kết quả
    PRINT 'Truy van thanh cong!';
    SELECT 
        @MANV AS MANV,
        @HOTEN AS HOTEN,
        @EMAIL AS EMAIL,
        @LUONGCB AS LUONGCB;
END

GO

---- Kiểm tra ----

-- Truy vấn thông tin của NHANVIEN
EXEC SP_SEL_PUBLIC_NHANVIEN 'NVA', 'abcd12' 
EXEC SP_SEL_PUBLIC_NHANVIEN 'TVB', 'abc123' 

-- Kiểm thông tin trong NHANVIEN
SELECT * FROM NHANVIEN;

-- Thêm lớp
INSERT INTO LOP (MALOP, TENLOP, MANV)
VALUES ('L01', N'Công nghệ tri thức', 'NV01'),
	   ('L02', N'Mạng máy tính', 'NV02');

SELECT * FROM LOP;

-- Thêm sinh viên
INSERT INTO SINHVIEN (MASV, HOTEN, NGAYSINH, DIACHI, MALOP, TENDN, MATKHAU)
VALUES 
    ('SV01', N'Nguyễn Văn C', '2004-05-10', N'Hà Nội', 'L01', 'NVC', HASHBYTES('SHA1', 'abc1')),
    ('SV02', N'Trần Thị D', '2003-06-15', N'Hồ Chí Minh', 'L01', 'TTD', HASHBYTES('SHA1', 'abc2')),
    ('SV03', N'Lê Văn E', '2002-07-20', N'Đà Nẵng', 'L02', 'LVE', HASHBYTES('SHA1', 'abc3')),
    ('SV04', N'Phạm Thị F', '2001-02-23', N'Cần Thơ', 'L02', 'PTF', HASHBYTES('SHA1', 'abc4'));

SELECT * FROM SINHVIEN;

-- Thêm học phần
INSERT INTO HOCPHAN (MAHP, TENHP, SOTC)
VALUES 
    ('BMCSDL', N'Bảo mật cơ sở dữ liệu', 4),
    ('MHUD', N'Mã hóa ứng dụng', 4);

SELECT * FROM HOCPHAN;


GO

-- Thêm điểm
CREATE PROCEDURE SP_INS_PUBLIC_BANGDIEM
    @MANV VARCHAR(20),   
    @MASV VARCHAR(20),  
    @MAHP VARCHAR(20),   
    @DIEMTHI FLOAT      
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MALOP VARCHAR(20)
    DECLARE @PUBKEY_NAME VARCHAR(20)
    DECLARE @ENCRYPTED_DIEM VARBINARY(MAX)

    -- Lấy lớp học của sinh viên
    SELECT @MALOP = MALOP FROM SINHVIEN WHERE MASV = @MASV;

    -- Kiểm tra nếu sinh viên không tồn tại
    IF @MALOP IS NULL
    BEGIN
        PRINT 'Loi: Sinh vien khong ton tai!';
        RETURN;
    END

    -- Lấy Public Key của nhân viên
    SELECT @PUBKEY_NAME = PUBKEY FROM NHANVIEN WHERE MANV = @MANV;

    -- Kiểm tra nếu không có Public Key
    IF @PUBKEY_NAME IS NULL
    BEGIN
        PRINT 'Loi: NHANVIEN khong co PUBLIC KEY!';
        RETURN;
    END

    -- Mã hóa điểm bằng RSA
    SET @ENCRYPTED_DIEM = EncryptByAsymKey(AsymKey_ID(@PUBKEY_NAME), CAST(@DIEMTHI AS NVARCHAR(100)));

    -- Kiểm tra nếu mã hóa thất bại
    IF @ENCRYPTED_DIEM IS NULL
    BEGIN
        PRINT 'Loi: Ma hoa diem khong thanh cong!';
        RETURN;
    END

    -- Thêm hoặc cập nhật điểm trong bảng BANGDIEM
    IF EXISTS (SELECT 1 FROM BANGDIEM WHERE MASV = @MASV AND MAHP = @MAHP)
    BEGIN
        UPDATE BANGDIEM
        SET DIEMTHI = @ENCRYPTED_DIEM
        WHERE MASV = @MASV AND MAHP = @MAHP;
        PRINT 'Cap nhat diem thanh cong!';
    END
    ELSE
    BEGIN
        INSERT INTO BANGDIEM (MASV, MAHP, DIEMTHI)
        VALUES (@MASV, @MAHP, @ENCRYPTED_DIEM);
        PRINT 'Them diem thanh cong!';
    END
END;

GO

-- Xem điểm
CREATE PROCEDURE SP_SEL_PUBLIC_BANGDIEM
    @MANV VARCHAR(20),   -- Nhân viên đăng nhập
    @MK NVARCHAR(100)    -- Mật khẩu của nhân viên để mở khóa giải mã
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PUBKEY_NAME VARCHAR(20)
    
    -- Lấy Public Key của nhân viên
    SELECT @PUBKEY_NAME = PUBKEY FROM NHANVIEN WHERE MANV = @MANV;

    -- Kiểm tra nếu không có Public Key
    IF @PUBKEY_NAME IS NULL
    BEGIN
        PRINT 'Lỗi: Không tìm thấy khóa RSA của nhân viên!';
        RETURN;
    END

    -- Truy vấn điểm thi và giải mã
    PRINT 'Đang giải mã điểm...';
    SELECT 
        B.MASV, S.HOTEN, B.MAHP, H.TENHP,
        CONVERT(NVARCHAR(MAX), DecryptByAsymKey(AsymKey_ID(@PUBKEY_NAME), B.DIEMTHI, @MK)) AS DIEMTHI
    FROM BANGDIEM B
    JOIN SINHVIEN S ON B.MASV = S.MASV
    JOIN HOCPHAN H ON B.MAHP = H.MAHP
    WHERE B.DIEMTHI IS NOT NULL;
END;

GO

-- Test --
-- Thêm điểm
EXEC SP_INS_PUBLIC_BANGDIEM 'NV01', 'SV01', 'BMCSDL', 10;
-- Xem điểm
SELECT * FROM BANGDIEM;

EXEC SP_SEL_PUBLIC_BANGDIEM 'NV01', 'abcd12';

EXEC SP_SEL_PUBLIC_BANGDIEM 'NV02', 'abc123';