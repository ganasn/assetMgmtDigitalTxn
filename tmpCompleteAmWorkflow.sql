USE Backshop
GO

UPDATE tblControlMasterDealPhaseTemplateItem SET
		SkippedSw = 1, DeliverableUserFullName = 'GNARAYAN', AuditUpdateUserId = 'GNARAYAN', AuditAddUserId = 'gnarayan', AuditUpdateDate = GETDATE(), CompletedDate = GETDATE()
	WHERE ControlId_F = '19-0011' AND WorkflowTemplateTypeCd_F = 'AMDEF' AND LoanStatusCd_F IN ('9')
UPDATE tblControlMasterDealPhaseTemplateItem SET
		SkippedSw = 0, DeliverableUserFullName = 'GNARAYAN', AuditUpdateUserId = 'GNARAYAN', AuditAddUserId = 'gnarayan', AuditUpdateDate = GETDATE(), CompletedDate = GETDATE()
	WHERE ControlId_F = '19-0011' AND WorkflowTemplateTypeCd_F = 'AMDEF' AND LoanStatusCd_F IN ('T')
--UPDATE tblControlMasterDealPhaseTemplateItem SET
--		SkippedSw = 0, DeliverableUserFullName = NULL, AuditUpdateUserId = NULL, AuditAddUserId = NULL, AuditUpdateDate = NULL, CompletedDate = NULL
--	WHERE ControlId_F = '19-0011' AND WorkflowTemplateTypeCd_F = 'AMDEF' AND LoanStatusCd_F IN ('S')
GO

SELECT * FROM tblControlMasterDealPhaseTemplateItem 
	WHERE ControlId_F = '19-0011' AND WorkflowTemplateTypeCd_F = 'AMDEF'

