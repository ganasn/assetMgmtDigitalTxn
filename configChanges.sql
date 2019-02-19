USE Backshop
GO


/*
Gana on 24-Aug-2018: Workflow change to mark ALL underwriting tasks & notifications in HCC workflow to OPTIONAL. This way, Processing manager (Dan Masterson) can update loan status from 'underwriting' to 'underwriting approved' without actually 
having to go through underwriting in Backshop. This also allows HCC deal pipeline to be accurate. 
*/

UPDATE tblzCdDealPhaseTemplate 
	SET RequiredSw = 0
WHERE WorkflowTemplateTypeCd_F = 'HCC' AND DealPhaseCd_F = 'PHASE4a' AND InactiveSw = 0
GO
-- Renaming workflow name 'HCC Loan' to 'CRE Loan'
UPDATE tblzCdWorkflowTemplateType 
	SET WorkflowTemplateTypeDesc = 'CRE Loan' 
WHERE WorkflowTemplateTypeCd = 'HCC'
GO
-- Establishing FNMA as Loan Program
UPDATE tblzCdLoanProgram
	SET LoanProgramCD = 'FNMA', LoanProgramDesc = 'CRE FannieMae', InactiveSw = 0, PrimaryWorkflowTemplateTypeCd_F = 'HCC', 
		AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
WHERE LoanProgramCD = 'FREDDIE'
GO
-- Renaming loan program from 'HCC Loan' to 'HFS Loan'
UPDATE tblzCdLoanProgram 
	SET LoanProgramDesc = 'CRE HFS Loan' 
WHERE LoanProgramCD = 'HCC'
GO
-- Renaming FannieMae & Multifamily Property Type (major) to resolve ambiguous naming
UPDATE tblzCdPropertyTypeMajor
	SET PropertyTypeMajorDesc = 'FannieMae Multifamily', UnderwritingAutoCalcTemplateID_F = 3, InactiveSw = 0, 
		AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE PropertyTypeMajorCd = 'FMM'

UPDATE tblzCdPropertyTypeMajor 
	SET PropertyTypeMajorDesc = 'Multifamily Non-FannieMae' , AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE PropertyTypeMajorCd = 'MLT'
GO

-- Update to notification matrix of FNMA Loan Program - Maintain Codes > Notification Matrix
INSERT INTO tblzCdNotificationMatrixToLoanProgram (NotificationMatrixID_F, LoanProgramCD_F, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId, InactiveSw) 
	SELECT NotificationMatrixID_F, 'FNMA', GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN', 0 FROM tblzCdNotificationMatrixToLoanProgram WHERE LoanProgramCD_F = 'HCC'
GO

-- Establishing unit status for FNMA property type (major) for use in Rent Roll
INSERT INTO tblzCdUnitStatus (UnitStatusCd, unitStatus, PropertyTypeMajorCd_F, UnitStausTypeCd_F, RptAsOccupiedSw, OrderKey, InactiveSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId) VALUES 
	('OCF', 'Occupied', 'FMM', 'OCC', 1, 10, 0, GETDATE(), 'GNARAYAN', NULL, NULL),
	('VCF', 'Vacant', 'FMM', 'VAC', 0, 20, 0, GETDATE(), 'GNARAYAN', NULL, NULL),
	('EMF', 'Employee', 'FMM', 'EMP', 1, 30, 0, GETDATE(), 'GNARAYAN', NULL, NULL),
	('MDF', 'Model', 'FMM', 'MDL', 0, 40, 0, GETDATE(), 'GNARAYAN', NULL, NULL),
	('DWF', 'Down', 'FMM', 'DWN', 0, 50, 0, GETDATE(), 'GNARAYAN', NULL, NULL)

-- Establishing unit type for FNMA property type (major) for use in Rent Roll
INSERT INTO tblzCdUnitType (UnitTypeCd, UnitTypeDesc, PropertyTypeMajorCd_F, UnitTypeAbbrev, OrderKey, NumberOfRooms, InactiveSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId) VALUES
	('FST', 'Studio', 'FMM', 'Studio', 10, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F11', '1 BR 1 BA', 'FMM', '1BR1BA', 20, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F16', '1 BR 1.5 BA', 'FMM', '1BR15BA', 30, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F12', '1 BR 2 BA', 'FMM', '1BR2BA', 40, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F21', '2 BR 1 BA', 'FMM', '2BR1BA', 50, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F26', '2 BR 1.5 BA', 'FMM', '2BR15BA', 60, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F22', '2 BR 2 BA', 'FMM', '2BR2BA', 70, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F27', '2 BR 2.5 BA', 'FMM', '2BR25BA', 80, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F23', '2 BR 3 BA', 'FMM', '2BR3BA', 90, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F31', '3 BR 1 BA', 'FMM', '3BR1BA', 100, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F36', '3 BR 1.5 BA', 'FMM', '3BR15BA', 110, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F32', '3 BR 2 BA', 'FMM', '3BR2BA', 120, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F37', '3 BR 2.5 BA', 'FMM', '3BR25BA', 130, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F33', '3 BR 3 BA', 'FMM', '3BR3BA', 140, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F41', '4 BR 1 BA', 'FMM', '4BR1BA', 150, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F46', '4 BR 1.5 BA', 'FMM', '4BR15BA', 160, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F42', '4 BR 2 BA', 'FMM', '4BR2BA', 170, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F47', '4 BR 2.5 BA', 'FMM', '4BR25BA', 180, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F43', '4 BR 3 BA', 'FMM', '4BR3BA', 190, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F48', '4 BR 3.5 BA', 'FMM', '4BR35BA', 200, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('F44', '4 BR 4 BA', 'FMM', '4BR4BA', 210, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL), 
	('FOT', 'Other', 'FMM', 'Other', 220, NULL, 0, GETDATE(), 'GNARAYAN', NULL, NULL)


-- Establishing Tenant Type for FNMA property type (major) for use in Rent Roll
INSERT INTO tblzCdTennantType (TennantTypeCd,TennantTypeName,PropertyTypeMajorCd_F,TennantTypeAbbrev,OrderKey,InactiveSw,AuditAddDate,AuditAddUserId,AuditUpdateDate,AuditUpdateUserId) VALUES 
('FSD','Standard','FMM','STD',10,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'), 
('FSU','Student','FMM','STU',20,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'), 
('FS8','Section 8','FMM','SE8',30,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'), 
('FAL','Senior Living','FMM','ASL',40,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'), 
('FML','Military','FMM','MIL',50,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN')

GO

-- Associating necessary NOI Categories with FNMA property type (major) 

-- Refresh FNMA Operating Statement Template by setting inactive switch to 1 & template switch to 0 
UPDATE tblzCdNOICatPropType 
	SET TemplateSW = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN', InactiveSw = 1
	WHERE PropertyTypeMajorCd_F = 'FMM'

-- Gross Potential Rent
UPDATE tblzCdNOICategory 
	SET OrderKey = 10, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'GRI' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 10, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'GRI' AND PropertyTypeMajorCd_F = 'FMM'

-- Less Vacancy Loss
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Less Vacancy Loss', AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN', OrderKey = 20
	WHERE NOICategoryCd = 'VCL'

INSERT INTO tblzCdNOICatPropType (NOICategoryCd_F, PropertyTypeMajorCd_F, UseOnRentRollSw, RelatedIncomeCd, OrderKey, TemplateSW, DefaultPercent, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId, InactiveSw) VALUES 
	('VCL', 'FMM', 0, NULL, 20, 0, 0.0000, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN', 0)

-- Less Bad Debt
INSERT INTO tblzCdNOICategory (NOICategoryCd,NOICategoryDesc,NOICategoryTypeCd_F,NOICategoryGPIsw,NOICategoryOIsw,NOICategoryReimbursementsw,NOICategoryVacancySw,NOICategoryFixedExpenseSw,NOICategoryDepartmentalExpenseSw,NOICategoryReimbursableExpenseTargetCd,OrderKey,NOICategoryProjectLoanSW,AuditAddDate,AuditAddUserId,AuditUpdateDate,AuditUpdateUserId,InactiveSw) VALUES
	('BAD', 'Less Bad Debt', 'I', 1, 0, 0, 0, 0, 0, NULL, 30, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN', 0)

INSERT INTO tblzCdNOICatPropType (NOICategoryCd_F, PropertyTypeMajorCd_F, UseOnRentRollSw, RelatedIncomeCd, OrderKey, TemplateSW, DefaultPercent, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId, InactiveSw) VALUES 
	('BAD', 'FMM', 0, NULL, 30, 0, 0.0000, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN', 0)

-- Less Concessions
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Less Concessions', AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN', OrderKey = 40
	WHERE NOICategoryCd = 'ICN'

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 40, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'ICN' AND PropertyTypeMajorCd_F = 'FMM'

-- Laundry/Vending Income
UPDATE tblzCdNOICategory 
	SET OrderKey = 50, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'OIV' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 50, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'OIV' AND PropertyTypeMajorCd_F = 'FMM'

-- Parking Income
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Parking Income', OrderKey = 60, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'ILN' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 60, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'ILN' AND PropertyTypeMajorCd_F = 'FMM'

-- Commercial Income
UPDATE tblzCdNOICategory 
	SET OrderKey = 70, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'CIN' 

INSERT INTO tblzCdNOICatPropType (NOICategoryCd_F, PropertyTypeMajorCd_F, UseOnRentRollSw, RelatedIncomeCd, OrderKey, TemplateSW, DefaultPercent, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId, InactiveSw) VALUES 
	('CIN', 'FMM', 0, NULL, 70, 0, 0.0000, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN', 0)

-- Other Income
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Other Income', OrderKey = 80, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'IVC' 

INSERT INTO tblzCdNOICatPropType (NOICategoryCd_F, PropertyTypeMajorCd_F, UseOnRentRollSw, RelatedIncomeCd, OrderKey, TemplateSW, DefaultPercent, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId, InactiveSw) VALUES 
	('IVC', 'FMM', 0, NULL, 80, 0, 0.0000, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN', 0)

-- Management Fees
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Management Fees', OrderKey = 90, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'OMF' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 90, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'OMF' AND PropertyTypeMajorCd_F = 'FMM'

-- G&A
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'General & Administrative', OrderKey = 100, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'OGA' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 100, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'OGA' AND PropertyTypeMajorCd_F = 'FMM'

-- Payroll & Benefits
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Payroll and Benefits', OrderKey = 110, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'OPY' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 110, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'OPY' AND PropertyTypeMajorCd_F = 'FMM'

-- Utilities
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Utilities', OrderKey = 120, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'OUT' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 120, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'OUT' AND PropertyTypeMajorCd_F = 'FMM'

-- Water & Sewer
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Water and Sewer', OrderKey = 130, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'WST' 

INSERT INTO tblzCdNOICatPropType (NOICategoryCd_F, PropertyTypeMajorCd_F, UseOnRentRollSw, RelatedIncomeCd, OrderKey, TemplateSW, DefaultPercent, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId, InactiveSw) VALUES 
	('WST', 'FMM', 0, NULL, 130, 0, 0.0000, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN', 0)

-- Ad & MKtg
UPDATE tblzCdNOICategory 
	SET OrderKey = 140, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'OAD' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 140, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'OAD' AND PropertyTypeMajorCd_F = 'FMM'

-- Pro Fees
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Professional Fees', NOICategoryTypeCd_F = 'O',  OrderKey = 150, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'SC4' 

INSERT INTO tblzCdNOICatPropType (NOICategoryCd_F, PropertyTypeMajorCd_F, UseOnRentRollSw, RelatedIncomeCd, OrderKey, TemplateSW, DefaultPercent, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId, InactiveSw) VALUES 
	('SC4', 'FMM', 0, NULL, 150, 0, 0.0000, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN', 0)

-- Ground Rent
UPDATE tblzCdNOICategory 
	SET OrderKey = 160, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'OGD' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 160, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'OGD' AND PropertyTypeMajorCd_F = 'FMM'

-- Repairs & Maintenance
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Repairs & Maintenance', OrderKey = 170, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'ORM' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 170, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'ORM' AND PropertyTypeMajorCd_F = 'FMM'

-- Property Insurance
UPDATE tblzCdNOICategory 
	SET NOICategoryDesc = 'Property Insurance', OrderKey = 180, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'OIN' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 180, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'OIN' AND PropertyTypeMajorCd_F = 'FMM'

-- Real Estate Taxes
UPDATE tblzCdNOICategory 
	SET OrderKey = 190, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'RET' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 190, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'RET' AND PropertyTypeMajorCd_F = 'FMM'

-- Other Expenses
UPDATE tblzCdNOICategory 
	SET OrderKey = 200, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'OTH' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 200, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'OTH' AND PropertyTypeMajorCd_F = 'FMM'

-- Replacement Reserves
UPDATE tblzCdNOICategory 
	SET OrderKey = 210, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'CRS' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 210, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'CRS' AND PropertyTypeMajorCd_F = 'FMM'

-- Extraordinary Capital 
UPDATE tblzCdNOICategory 
	SET OrderKey = 220, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd = 'CEO' 

UPDATE tblzCdNOICatPropType 
	SET OrderKey = 220, InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE NOICategoryCd_F = 'CEO' AND PropertyTypeMajorCd_F = 'FMM'

GO

-- Cleaning up Covenants

UPDATE tblzcdAssetManagementCovenantObject 
	SET InactiveSw = 1, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN' 
	WHERE AssetManagementCovenantObjectCD NOT IN ('DSCR', 'LIQUIDITY', 'OTHER')

UPDATE tblzcdAssetManagementCovenantObject 
	SET AssetManagementCovenantObjectDesc = 'DSCR - Minimum', InactiveSw = 0, OrderKey = 10, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE AssetManagementCovenantObjectCD = 'DSCR'

UPDATE tblzcdAssetManagementCovenantObject 
	SET InactiveSw = 0, OrderKey = 30, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE AssetManagementCovenantObjectCD = 'LTV'

UPDATE tblzcdAssetManagementCovenantObject 
	SET InactiveSw = 0, OrderKey = 60, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE AssetManagementCovenantObjectCD = 'NETWORTH'

UPDATE tblzcdAssetManagementCovenantObject 
	SET InactiveSw = 0, OrderKey = 70, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE AssetManagementCovenantObjectCd = 'LIQUIDITY'

UPDATE tblzcdAssetManagementCovenantObject 
	SET InactiveSw = 0, OrderKey = 100, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE AssetManagementCovenantObjectCD = 'LTC'

INSERT INTO tblzcdAssetManagementCovenantObject (AssetManagementCovenantObjectCD,AssetManagementCovenantObjectDesc,CovenantObjectFormatType,CovenantObjectDecimalPlaces,OrderKey,InactiveSw,AuditAddDate,AuditAddUserId,AuditUpdateDate,AuditUpdateUserId) VALUES
	('DSCR-ACHV','DSCR - Achievement','N','2','20','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('NOI-MIN','NOI/NCF - Minimum','$','0','40','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('NOI-ACHV','NOI/NCF - Achievement','$','0','50','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('GLOBALDSCR','Global DSCR - Minimum','N','2','80','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('LOC','Letter of Credit ','T','0','90','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('DEPBAL','Deposit account balance','$','0','110','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('CONVPERM','Conversion to Perm','T','0','120','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('CONVAMORT','Conversion to Amortization','T','0','130','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('EARNOUT','Earnout','T','0','140','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('RECOURSE','Recourse','T','0','150','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('EXTEN','Extension','T','0','160','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('ROFO','Right of First Opportunity','T','0','170','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('REQ-REP','Required Repairs','T','0','180','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('OCC-MIN','Occupancy - Minimum','N','2','190','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('OCC-ACHV','Occupancy - Achievement','N','2','200','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('ENVIRON','Environmental','T','0','210','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('NEEDS','Property Needs Assessment','T','0','220','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('TAXABATE','Tax abatement ','T','0','230','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('TAXASSESS','Tax Assessement','T','0','240','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('CONDO','Condo association ','T','0','250','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('GRNDLEAS','Ground lease','T','0','260','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('AFFHOUSE','Affordable housing requirements','T','0','270','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('ANNBUD','Annual budget','$','0','280','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('LEASREQ','Tenant/Leasing requirements','T','0','290','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('PRJ-COMP','Project completion','T','0','300','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('INSP-CLO','Specific inspection Items','T','0','310','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('CERTOCC','Certificate of Occupancy due date','T','0','320','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('CON-START','Construction Start Date','T','0','330','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('EASEMENT','Easements/Recorded Agreements','T','0','340','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('TRAIL-CLO','Trailing Closing Condition','T','0','350','0',GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN')
GO


-- Cleaning up Reporting Requirements

UPDATE tblzCdReportingRequirementType 
	SET InactiveSw = 1 , AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE ReportingRequirementTypeCd = 'PROVISIONAL' 

UPDATE tblzCdReportingRequirementSubType
	SET InactiveSw = 1, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE ReportingRequirementSubTypeCd NOT IN ('FINANCIALSTMTS', 'INCOME STATEMENT', 'REAL ESTATE SCHEDULE', 'RENT ROLL', 'TAX RETURN')

UPDATE tblzCdReportingRequirementSubType
	SET ReportingRequirementSubTypeDesc = 'Financial Reporting Package', InactiveSw = 0,
		AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN', OrderKey = 10
	WHERE ReportingRequirementSubTypeCd = 'FINANCIALSTMTS'

UPDATE tblzCdReportingRequirementSubType
	SET ReportingRequirementSubTypeDesc = 'Operating/Income Statement Property', InactiveSw = 0,
		AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN', OrderKey = 20
	WHERE ReportingRequirementSubTypeCd = 'INCOME STATEMENT'

UPDATE tblzCdReportingRequirementSubType 
	SET ReportingRequirementSubTypeDesc = 'Rent Roll', AuditUpdateDate = GETDATE(), 
		AuditUpdateUserId = 'GNARAYAN', InactiveSw = 0, OrderKey = 30
	WHERE ReportingRequirementSubTypeCd = 'RENT ROLL'

UPDATE tblzCdReportingRequirementSubType 
	SET ReportingRequirementSubTypeDesc = 'Sales Report - Retail', ReportingRequirementSubTypeCd = 'RETAIL SALES REPORT',
		AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN', InactiveSw = 0, OrderKey = 50
	WHERE ReportingRequirementSubTypeCd = 'SALES REPORT'

UPDATE tblzCdReportingRequirementSubType
	SET ReportingRequirementSubTypeDesc = 'Property Operating Budget', InactiveSw = 0,
		AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN', OrderKey = 70
	WHERE ReportingRequirementSubTypeCd = 'OPERATING BUDGET'

INSERT INTO tblzCdReportingRequirementSubType (ReportingRequirementSubTypeCd,ReportingRequirementTypeCd_F,ReportingRequirementSubTypeDesc,OrderKey,InactiveSw,AuditAddDate,AuditAddUserId,AuditUpdateDate,AuditUpdateUserId) VALUES
	('AFFORDABLEHOUSING','MISCELLANEOUS','Affordable Housing Reporting Package',40,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('HOSP SALES REPORT','FINANCIAL','Sales Report - Hospitality',60,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
	('ENERGYSTAR','MISCELLANEOUS','Energy Star Reports',80,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN')
GO

--	Cleaning-up Reporting Requirement Status 

UPDATE tblzCdReportingRequirementStatus SET InactiveSw = 1, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'

INSERT INTO tblzCdReportingRequirementStatus (ReportingRequirementStatusCd,ReportingRequirementStatusDesc,OrderKey,InactiveSw,AuditAddDate,AuditAddUserId,AuditUpdateDate,AuditUpdateUserId) VALUES
('RXDPENDRVW','Received Pending Review',10,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
('RXDWEXC','Received with Exceptions',20,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
('IPRDYANL','Input Ready for Analysis',30,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
('AMRVWDONE','Asset Manager Review Complete',40,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN'),
('ANLTOOB','Analysis Uploaded to OnBase',50,0,GETDATE(),'GNARAYAN',GETDATE(),'GNARAYAN')

UPDATE tblzCdReportingRequirementStatus 
	SET InactiveSw = 0, OrderKey = 60, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN' 
	WHERE ReportingRequirementStatusCd = 'Waived'
GO

-- Remove "application date" field from Deal Wizard (Deal)
UPDATE tblzCDDealWizardConfig 
	SET isActive = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE DealWizardCD = 'APPLICATIONDATE'
GO