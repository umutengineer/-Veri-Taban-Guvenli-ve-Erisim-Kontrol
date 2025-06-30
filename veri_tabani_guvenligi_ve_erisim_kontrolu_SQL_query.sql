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

INSERT INTO Musteri (AdSoyad, Email)     -- �rnek m��teri verileri ekleme
VALUES 
    ('Ali Y�lmaz', 'ali.yilmaz@example.com'),
    ('Ay�e Demir', 'ayse.demir@example.com'),
    ('Mehmet Kaya', 'mehmet.kaya@example.com'),
	('Cenin Rihavi', 'tarikrihawi45@gmail.com'),
	('Umut Akylbek kyzy', 'umutAky22@gmail.com');

-- Giri� (login) olu�tur
CREATE LOGIN Umutkullanici WITH PASSWORD = 'Guv3nliP@rola!';
-- Veritaban� kullan�c�s� olu�tur
USE OrnekVT;
GO
CREATE USER Umutkullanici FOR LOGIN Umutkullanici;
GO

GRANT SELECT ON Musteri TO Umutkullanici; -- Sadece veri okuma yetkisi ver
SELECT * FROM Musteri;

DENY INSERT ON Musteri TO Umutkullanici;   -- Veri ekleme yetkisini engelle (DENY INSERT)

GRANT INSERT ON Musteri TO Umutkullanici;

REVOKE SELECT ON Musteri FROM sql_kullanici;  -- Yetkiyi kald�r (�rne�in SELECT yetkisini kald�rmak)

EXEC sp_helpuser 'Umutkullanici'

INSERT INTO Musteri (AdSoyad, Email)
VALUES ('Mehmet Y�lmaz', 'mehmet.yilmaz@example.com');
SELECT * FROM Musteri;

EXEC sp_droprolemember 'db_datawriter', 'Umutkullanici';    -- Kullan�c�y� db_datawriter rol�nden ��kar 

EXEC sp_droprolemember 'db_owner', 'Umutkullanici';     -- db_owner'dan da ��kar 

EXEC sp_helpuser 'laptop-ifon0j6j\asus'

-- Kullan�c�n�n "Musteri" tablosu �zerindeki izinlerini kontrol et
SELECT * 
FROM sys.database_permissions 
WHERE grantee_principal_id = USER_ID('Umutkullanici')
AND major_id = OBJECT_ID('Musteri');

-- Veritaban� kullan�c�s� olarak ekle
USE OrnekVT;
GO
CREATE USER [laptop-ifon0j6j\asus] FOR LOGIN [laptop-ifon0j6j\asus];
GO

EXEC sp_addrolemember 'db_datareader', 'Umutkullanici'; -- sql_kullanici kullan�c�s�n� sadece okuma rol�ne ekle
EXEC sp_addrolemember 'db_owner', 'laptop-ifon0j6j\asus';  -- Windows kullan�c�s�na tam yetki ver

EXEC sp_helpuser 'Umutkullanici'
EXEC sp_helpuser 'laptop-ifon0j6j\asus'

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Guv3nliParola123!';   -- Anahtar olu�tur

CREATE CERTIFICATE VeriSertifikasi     -- Sertifika olu�tur
WITH SUBJECT = 'Musteri Verisi Sertifikasi';

CREATE TABLE SifreliMusteriler (    -- �ifreli tablo olu�tur
    ID INT IDENTITY,
    AdSoyad VARBINARY(MAX)
);

DROP CERTIFICATE VeriSertifikasi;

DROP TABLE IF EXISTS SifreliMusteriler;

INSERT INTO SifreliMusteriler (AdSoyad)     -- Veri ekleme (�ifreli)
VALUES (EncryptByCert(Cert_ID('VeriSertifikasi'), 'Ahmet Y�lmaz'));

SELECT CONVERT(NVARCHAR, DecryptByCert(Cert_ID('VeriSertifikasi'), AdSoyad))    -- Veri okuma (decryption)
FROM SifreliMusteriler;

-- Bu sorgu SQL injection'a a��kt�r
DECLARE @kullaniciAdi NVARCHAR(100) = 'admin''; DROP TABLE Musteri;--';
EXEC('SELECT * FROM Musteri WHERE AdSoyad = ''' + @kullaniciAdi + '''');

-- G�venli parametreli sorgu
DECLARE @kullaniciAd NVARCHAR(100) = 'admin';

EXEC sp_executesql
    N'SELECT * FROM Musteri WHERE AdSoyad = @adi',
    N'@adi NVARCHAR(100)',
    @adi = @kullaniciAd;

-- E�er daha �nce var olan bir trigger varsa, onu sil
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

CREATE TRIGGER trg_Musteriler_Log     -- Yeni trigger olu�turuluyor
ON Musteri  -- Trigger, Musteri tablosu �zerinde �al��acak
AFTER INSERT, DELETE, UPDATE  
AS
BEGIN
    -- ��lem t�r�n� tutacak de�i�ken
    DECLARE @Islem NVARCHAR(50);

    -- E�er hem INSERT hem de DELETE i�lemleri yap�lm��sa, bu bir UPDATE i�lemidir
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Islem = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Islem = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @Islem = 'DELETE';

    -- LogKayitlar tablosuna i�lem t�r�n�, kullan�c� bilgisini ve a��klamay� ekle
    INSERT INTO LogKayitlar (IslemTuru, KullaniciSistemi, Aciklama)
    VALUES (
        @Islem,  -- ��lem t�r� (INSERT, UPDATE, DELETE)
        SYSTEM_USER,  -- Sistemi kullanan kullan�c� ad�
        'Musteriler tablosunda ' + @Islem + ' i�lemi yap�ld�.'  -- ��lemin a��klamas�
    );
END
GO

select * from LogKayitlar

UPDATE Musteri 
SET AdSoyad = 'Mehmet Y�lmaz' 
WHERE AdSoyad = 'Ahmet Y�lmaz';

select * from Musteri

DELETE FROM Musteri 
WHERE AdSoyad = 'Mehmet Y�lmaz';

SELECT * FROM Musteri

-- Sertifika ve anahtar� sil
DROP CERTIFICATE VeriSertifikasi;
DROP MASTER KEY;

-- Tabloyu sil
DROP TABLE IF EXISTS SifreliMusteriler;

-- Trigger'� sil
DROP TRIGGER IF EXISTS trg_Musteriler_Log;

-- LogKayitlar tablosunu sil
DROP TABLE IF EXISTS LogKayitlar;
