USE CRE_ODS

--USE Backshop
GO

--HBSEADWHT02.CRE_ODS.HSB_HIST.STRATEGY_EXTRACT

DECLARE @LoanMaster TABLE (CONTROLID NVARCHAR (7), LOANNUMBER BIGINT, PROPTYPE NVARCHAR (3), EFFDATE DATE, LOANSTATUS NVARCHAR (50), LOANSTATUSCD NVARCHAR (20))

INSERT INTO @LoanMaster 
	SELECT a.ControlId, c.ServicerLoanNUmber, e.PropertyTypeMajorCd_F AS [PROP_TYPE], MAX(d.DATA_EFFDATE), f.LoanStatusDesc, f.LoanStatusCd
		FROM dbo.tblControlMaster a 
			INNER JOIN tblNote b ON a.ControlId = b.ControlId_F
			INNER JOIN tblNoteExp c ON c.NoteId_F = b.NoteId
			INNER JOIN tblProperty e ON e.ControlId_F = a.ControlId
			INNER JOIN tblzCdLoanStatus f ON f.LoanStatusCd = a.LoanStatusCd_F
			LEFT OUTER JOIN HBSEADWHP01.CRE_ODS.HSB_HIST.STRATEGY_EXTRACT d ON d.[LOANNBR] = c.ServicerLoanNumber
		GROUP BY a.ControlId, c.ServicerLoanNUmber, e.PropertyTypeMajorCd_F, f.LoanStatusDesc, f.LoanStatusCd
		ORDER BY a.ControlId, CONVERT(BIGINT, ServicerLoanNUmber)


--SELECT * FROM @loanMaster ORDER BY CONTROLID DESC, LOANNUMBER
SELECT 'NO STR', COUNT(*) FROM @loanMaster WHERE EFFDATE IS NULL
UNION
SELECT 'STR', COUNT(*) FROM @loanMaster WHERE EFFDATE IS NOT NULL
UNION
SELECT 'IN BS', COUNT(*) FROM tblNote
	
-- MARK /CLOSED 
	-- Mark Loan Status as Funded (and it does NOT lock the loan for asset management purposes)
UPDATE tblControlMaster SET LoanStatusCd_F = 'F', AuditUpdateDate = GETDATE(), AuditUpdateUserId = 'SYSTEM' WHERE ControlId IN (SELECT CONTROLID FROM @LoanMaster WHERE EFFDATE IS NOT NULL)

	-- Mark production workflow (HCC) as COMPLETE
UPDATE tblControlMasterDealPhaseTemplateItem SET 
	CompletedDate = GETDATE(), SkippedSw = 1, AuditUpdateUserId = 'SYSTEM', AuditUpdateDate = GETDATE()
	WHERE ControlId_F IN (SELECT CONTROLID FROM @LoanMaster WHERE EFFDATE IS NOT NULL) AND CompletedDate IS NULL AND WorkflowTemplateTypeCd_F = 'HCC'



-- CHECK LOAN STATUS
SELECT ControlId, SErvicerLoanNumber, LoanStatusDesc FROM tblControlMaster a INNER JOIN tblNOte b ON a.ControlId = b.ControlId_F INNER JOIN tblNoteExp c ON c.NoteId_f = b.NoteId 
	AND c.ServicerLoanNumber IN (SELECT DISTINCT LOANNBR FROM HSB_HIST.STRATEGY_EXTRACT)
	INNER JOIN tblzCdLoanStatus d ON d.LoanStatusCd = a.LoanStatusCd_F
	WHERE LoanStatusDesc = 'Funded'