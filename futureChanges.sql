USE Backshop_DEV
GO


-- ENABLE Closing > Insurance > Insurance Monitoring & Closing > Insurance > Insurance Monitoring > Create Multiple Insurance Records
UPDATE tblSiteMap SET 
	isGotoLinkSW = 1, isMenuable = 1
	WHERE SiteMapCD IN ('INSURANCEMONITORING', 'CREATEMULTIPLEINSURANCEMONITORING')

