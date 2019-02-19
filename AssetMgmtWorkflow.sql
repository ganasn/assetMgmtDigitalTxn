USE Backshop
GO

/* 
SELECT * FROM tblzCdLoanProgram
SELECT * FROM tblzCdWorkflowTemplateType ORDER BY OrderKey
SELECT * FROM tblzCdDealPhase WHERE InactiveSw <> 1 ORDER BY OrderKey
SELECT * FROM tblzCdLoanStatus WHERE InactiveSw = 0 ORDER BY ClientIdentifier DESC, OrderKey
SELECT * FROM tblzcdLoanStatusSourceTarget
SELECT * FROM tblzCdDeliverableEventType ORDER BY OrderKey DESC
SELECT * FROM tblzCdDealPhaseTemplate 
*/

/* COMMON SCRIPT TO SETUP LOAN TYPE, LOAN STATUS, AND ALL OTHER CONFIGURATION - EXCEPT - ACTUAL WORKFLOW TEMPLATE ITEMS & THEIR SEQUENCE */ 

/* SCRIPT TO SETUP LOAN PROGRAMS FOR CRE WORKFLOW */

-- NO ENTRIES IN tblzCdLoanProgram FOR ASSET MANAGEMENT AS IT APPLIES TO ALL LOANS IN THE PORTFOLIO


/* SCRIPT TO SETUP WORKFLOW TEMPLATE NAME */

INSERT INTO tblzCdWorkflowTemplateType (WorkflowTemplateTypeCd, WorkflowTemplateTypeDesc, OrderKey, InactiveSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId) VALUES
('AMDEF', 'Asset Management', 20, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN')
GO

/* Gana on 26-Mar-2018: SCRIPT TO CONNECT WORKFLOW TO LOAN PROGRAM AS A RESULT OF NEW UI (v7) */
-- NO ENTRIES IN tblzCdLoanProgramWorkflowTemplateType FOR ASSET MANAGEMENT AS IT APPLIES TO ALL LOANS IN THE PORTFOLIO

/* SCRIPT TO SETUP DEAL PHASE FOR CRE WORKFLOW */

INSERT INTO tblzCdDealPhase (DealPhaseCd, DealPhaseDesc, OrderKey, InactiveSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId) VALUES
('PHASE50A', 'Loan Administration', 50, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN')
GO

/* SCRIPT TO SETUP DEAL STATUS FOR ASSET MANAGEMENT WORKFLOW */

--INSERT INTO tblzCdLoanStatus (LoanStatusCd, LoanStatusDesc, OrderKey, CommentRequiredonNewSW, StatusRoleExceptionSw, ClientIdentifier, DeadTypeSw, InactiveSw, ReasonRequiredSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId, UpdateAmortOnIndexUpdateSw, CopyOpStatementToOtherPropertySw, IncludeOnLoanStatusAgingReportSw, DefaultCopyStatusSw) VALUES 
--('9', 'Asset Management', 100, 0, 0, 'CRE', 0, 0, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN', 0, 0, 0, 0)
UPDATE tblzCdLoanStatus SET
	LoanStatusDesc = 'Asset Management', OrderKey = 100, ClientIdentifier = 'CRE', InactiveSw = 0, AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'GNARAYAN'
	WHERE LoanStatusCd = '9'
GO

INSERT INTO tblzCdDeliverableEventType (DeliverableEventTypeCD, DeliverableEventTypeDesc, OrderKey, SiteMapCD_F, InactiveSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId) VALUES 
('AMREPREQ', 'Setup/validate reporting requirements', 5010, 'REPORTINGREQUIREMENT', 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMCOV', 'Setup/validate covenants', 5020, 'ASSETMANAGEMENTDETAIL', 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMBMINSP', 'Setup/validate baseline inspection', 5030, 'ENGINEERINGREPT', 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMUWCF', 'Setup/validate underwriting cash-flow/prior OSAR', 5040, 'UNDERWRITTENCFHEADER', 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'), 
('AMBMINSU', 'Setup/validate insurance', 5050, 'INSURANCE', 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMGETREP', 'Gather reporting requirements', 5060, 'REPORTINGREQUIREMENT', 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMOSAR', 'Perform OSAR', 5070, 'OPSTATEMENTSUMMARY', 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMPERFINSP', 'Perform inspection', 5080, 'ENGINEERINGREPT', 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMPERFINSU', 'Validate insurance', 5090, 'INSURANCE', 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMFIN', 'Complete loan review', 5100, NULL, 0, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN')
GO

-- THIS SQL CAN BE RUN ONLY ONCE - MULTIPLE EXECUTIONS IN THE SAME ENVIRONMENT DUPLICATES TASKS FOR THE WORKFLOW
INSERT INTO tblzCdDealPhaseTemplate (WorkflowTemplateTypeCd_F, DealPhaseCd_F, LoanStatusCd_F, DealPhaseItemTypeCd_F, UserRoleCd_F, RequiredSw, DeliverableEventTypeCD_F, OrderKey, CompleteOnDealWizardCreate, LoanStatusChangeOnCompletedCd_F, ShowCommentSw, AuditAddDate, AuditAddUserId, AuditUpdateDate, AuditUpdateUserId) VALUES 
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMREPREQ', 5010, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMCOV', 5020, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMBMINSP', 5030, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMUWCF', 5040, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMBMINSU', 5050, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMGETREP', 5060, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMOSAR', 5070, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMPERFINSP', 5080, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMPERFINSU', 5090, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN'),
('AMDEF', 'PHASE50A', '9', 'TASK', 'ASSETMAN', 0, 'AMFIN', 5100, 0, NULL, 1, GETDATE(), 'GNARAYAN', GETDATE(), 'GNARAYAN')
GO