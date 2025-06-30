CREATE DATABASE OrnekVT;
GO
USE OrnekVT;
GO
CREATE TABLE Musteri (
    MusteriID INT PRIMARY KEY IDENTITY(1,1),
    AdSoyad NVARCHAR(100),
    Email NVARCHAR(100)
);
GO

INSERT INTO Musteri (AdSoyad, Email)     -- Örnek müþteri verileri ekleme
VALUES 
    ('Ali Yýlmaz', 'ali.yilmaz@example.com'),
    ('Ayþe Demir', 'ayse.demir@example.com'),
    ('Mehmet Kaya', 'mehmet.kaya@example.com'),
	('Cenin Rihavi', 'tarikrihawi45@gmail.com'),
	('Umut Akylbek kyzy', 'umutAky22@gmail.com');

-- Giriþ (login) oluþtur
CREATE LOGIN Umutkullanici WITH PASSWORD = 'Guv3nliP@rola!';
-- Veritabaný kullanýcýsý oluþtur
USE OrnekVT;
GO
CREATE USER Umutkullanici FOR LOGIN Umutkullanici;
GO

GRANT SELECT ON Musteri TO Umutkullanici; -- Sadece veri okuma yetkisi ver
SELECT * FROM Musteri;

DENY INSERT ON Musteri TO Umutkullanici;   -- Veri ekleme yetkisini engelle (DENY INSERT)

GRANT INSERT ON Musteri TO Umutkullanici;

REVOKE SELECT ON Musteri FROM sql_kullanici;  -- Yetkiyi kaldýr (örneðin SELECT yetkisini kaldýrmak)

EXEC sp_helpuser 'Umutkullanici'

INSERT INTO Musteri (AdSoyad, Email)
VALUES ('Mehmet Yýlmaz', 'mehmet.yilmaz@example.com');
SELECT * FROM Musteri;

EXEC sp_droprolemember 'db_datawriter', 'Umutkullanici';    -- Kullanýcýyý db_datawriter rolünden çýkar 

EXEC sp_droprolemember 'db_owner', 'Umutkullanici';     -- db_owner'dan da çýkar 

EXEC sp_helpuser 'laptop-ifon0j6j\asus'

-- Kullanýcýnýn "Musteri" tablosu üzerindeki izinlerini kontrol et
SELECT * 
FROM sys.database_permissions 
WHERE grantee_principal_id = USER_ID('Umutkullanici')
AND major_id = OBJECT_ID('Musteri');

-- Veritabaný kullanýcýsý olarak ekle
USE OrnekVT;
GO
CREATE USER [laptop-ifon0j6j\asus] FOR LOGIN [laptop-ifon0j6j\asus];
GO

EXEC sp_addrolemember 'db_datareader', 'Umutkullanici'; -- sql_kullanici kullanýcýsýný sadece okuma rolüne ekle
EXEC sp_addrolemember 'db_owner', 'laptop-ifon0j6j\asus';  -- Windows kullanýcýsýna tam yetki ver

EXEC sp_helpuser 'Umutkullanici'
EXEC sp_helpuser 'laptop-ifon0j6j\asus'

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Guv3nliParola123!';   -- Anahtar oluþtur

CREATE CERTIFICATE VeriSertifikasi     -- Sertifika oluþtur
WITH SUBJECT = 'Musteri Verisi Sertifikasi';

CREATE TABLE SifreliMusteriler (    -- Þifreli tablo oluþtur
    ID INT IDENTITY,
    AdSoyad VARBINARY(MAX)
);

DROP CERTIFICATE VeriSertifikasi;

DROP TABLE IF EXISTS SifreliMusteriler;

INSERT INTO SifreliMusteriler (AdSoyad)     -- Veri ekleme (þifreli)
VALUES (EncryptByCert(Cert_ID('VeriSertifikasi'), 'Ahmet Yýlmaz'));

SELECT CONVERT(NVARCHAR, DecryptByCert(Cert_ID('VeriSertifikasi'), AdSoyad))    -- Veri okuma (decryption)
FROM SifreliMusteriler;

-- Bu sorgu SQL injection'a açýktýr
DECLARE @kullaniciAdi NVARCHAR(100) = 'admin''; DROP TABLE Musteri;--';
EXEC('SELECT * FROM Musteri WHERE AdSoyad = ''' + @kullaniciAdi + '''');

-- Güvenli parametreli sorgu
DECLARE @kullaniciAd NVARCHAR(100) = 'admin';

EXEC sp_executesql
    N'SELECT * FROM Musteri WHERE AdSoyad = @adi',
    N'@adi NVARCHAR(100)',
    @adi = @kullaniciAd;

-- Eðer daha önce var olan bir trigger varsa, onu sil
DROP TRIGGER IF EXISTS trg_Musteriler_Log;
GO

CREATE TABLE LogKayitlar (
    LogID INT IDENTITY(1,1) PRIMARY KEY,       
    IslemTuru NVARCHAR(50),                     
    Tarih DATETIME DEFAULT GETDATE(),          
    KullaniciSistemi NVARCHAR(100),           
    Aciklama NVARCHAR(MAX)                    
);

SELECT * FROM LogKayitlar;

CREATE TRIGGER trg_Musteriler_Log     -- Yeni trigger oluþturuluyor
ON Musteri  -- Trigger, Musteri tablosu üzerinde çalýþacak
AFTER INSERT, DELETE, UPDATE  
AS
BEGIN
    -- Ýþlem türünü tutacak deðiþken
    DECLARE @Islem NVARCHAR(50);

    -- Eðer hem INSERT hem de DELETE iþlemleri yapýlmýþsa, bu bir UPDATE iþlemidir
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Islem = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Islem = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Islem = 'DELETE';

    -- LogKayitlar tablosuna iþlem türünü, kullanýcý bilgisini ve açýklamayý ekle
    INSERT INTO LogKayitlar (IslemTuru, KullaniciSistemi, Aciklama)
    VALUES (
        @Islem,  -- Ýþlem türü (INSERT, UPDATE, DELETE)
        SYSTEM_USER,  -- Sistemi kullanan kullanýcý adý
        'Musteriler tablosunda ' + @Islem + ' iþlemi yapýldý.'  -- Ýþlemin açýklamasý
    );
END
GO

select * from LogKayitlar

UPDATE Musteri 
SET AdSoyad = 'Mehmet Yýlmaz' 
WHERE AdSoyad = 'Ahmet Yýlmaz';

select * from Musteri

DELETE FROM Musteri 
WHERE AdSoyad = 'Mehmet Yýlmaz';

SELECT * FROM Musteri

-- Sertifika ve anahtarý sil
DROP CERTIFICATE VeriSertifikasi;
DROP MASTER KEY;

-- Tabloyu sil
DROP TABLE IF EXISTS SifreliMusteriler;

-- Trigger'ý sil
DROP TRIGGER IF EXISTS trg_Musteriler_Log;

-- LogKayitlar tablosunu sil
DROP TABLE IF EXISTS LogKayitlar;
