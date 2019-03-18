USE Backshop
GO

SELECT * FROM tblzCdAssetManagementCovenantCompliantType ORDER BY OrderKey

INSERT INTO tblzCdAssetManagementCovenantCompliantType( AssetManagementCovenantCompliantTypeCd, AssetManagementCovenantCompliantTypeDesc, OrderKey, InactiveSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId ) VALUES
	('OPEXT', 'Open & Extended', 10, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
	('CLCOM', 'Closed & Compliant', 20, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
	('CLNC', 'Closed & Non-Compliant', 30, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
	('WVD', 'Waived', 40, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN')

SELECT * FROM tblzCdAssetManagementCovenantCompliantType ORDER BY OrderKey
