-- BDU03

use QLBongDa

-- Kiểm tra VIEW
SELECT * FROM vCau1; 
SELECT * FROM vCau2;
SELECT * FROM vCau3;
SELECT * FROM vCau4;

-- Kiểm tra procedure
EXEC SPCau1 N'SHB Đà Nẵng', N'Brazil'; 
EXEC SPCau10 3, 2009; 
EXEC SPCau3 N'Việt Nam';
EXEC SPCau4 N'Việt Nam'; 