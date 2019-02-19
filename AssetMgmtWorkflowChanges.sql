USE Backshop
GO

UPDATE tblzCdLoanStatus SET 
	InactiveSw = 0,
	LoanStatusDesc = 'Review Complete',
	OrderKey = 110,
	AuditUpdateDate = GETDATE(),
	AuditUpdateUserId = 'GNARAYAN'
WHERE LoanStatusCd = 'T'

UPDATE tblzCdLoanStatus SET 
	InactiveSw = 0,
	LoanStatusDesc = 'Submitted to Investor',
	OrderKey = 120,
	AuditUpdateDate = GETDATE(),
	AuditUpdateUserId = 'GNARAYAN'
WHERE LoanStatusCd = 'S'

GO

INSERT INTO tblzCdDeliverableEventType (DeliverableEventTypeCD, DeliverableEventTypeDesc, OrderKey, SiteMapCD_F, InactiveSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId) VALUES 
	('AMSUBMIT', 'Submitted to Investor', 5200, NULL, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN')
GO

UPDATE tblzCdDealPhaseTemplate 
	SET LoanStatusCd_F = 'T'
	WHERE WorkflowTemplateTypeCd_F = 'AMDEF' AND DealPhaseCd_F = 'PHASE50A' AND DeliverableEventTypeCD_F = 'AMFIN'

INSERT INTO tblzCdDealPhaseTemplate (WorkflowTemplateTypeCd_F, DealPhaseCd_F, LoanStatusCd_F, DealPhaseItemTypeCd_F, UserRoleCd_F, RequiredSw, DeliverableEventTypeCD_F, OrderKey, CompleteOnDealWizardCreate, LoanStatusChangeOnCompletedCd_F, ShowCommentSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId) VALUES 
	('AMDEF', 'PHASE50A', 'S', 'TASK', 'ASSETMAN', 0, 'AMSUBMIT', 5200, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN')
GO
