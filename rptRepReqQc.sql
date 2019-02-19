/* 
This SQL retrieves reporting requirements for FNMA loans
*/

USE CRE_ODS
GO

DECLARE @ASSET_MANAGER NVARCHAR (200), @REP_REQ_STATUS NVARCHAR (200)

SET @ASSET_MANAGER = 'SETH PRESWITCH'
SET @REP_REQ_STATUS = 'ALL' -- AMRVWDONE OPEN

IF @REP_REQ_STATUS =  'OPEN'
BEGIN
	SELECT 
		UPPER(CONCAT(gg.FirstName, SPACE(1), gg.LastName)) AS [ASSET_MANAGER],
		aa.ControlId AS [BACKSHOP_LOAN_IDENTIFIER],
		ee.ServicerLoanNumber AS [STR_LOAN_IDENTIFIER],
		bb.PropertyName AS [BACKSHOP_PROP_NAME],
		ii.LoanProgramDesc AS [LOAN_PROGRAM],
		a.AssetManagementCovenantCategoryCd_F AS [REPORTING_FOR], 
		a.ReportingRequirementTypeCd_F AS [REPORTING_TYPE],
		c.ReportingRequirementSubTypeDesc AS [REPORTING_SUB_TYPE],
		a.DaysDueWithin AS [DAYS_DUE_WITHIN],
		FORMAT(a.AsOfDate, 'MM/dd/yyyy') AS [AS_OF_DATE],
		ISNULL(a.ReportingRequirementStatusCd_F, 'Open') AS [REQ_STATUS],
		FORMAT(a.ReceivedDate, 'MM/dd/yyyy') AS [RXD_DATE], 
		FORMAT(DATEADD(dd, a.DaysDueWithin, a.AsOfDate), 'MM/dd/yyyy') AS [DUE_DATE], 
		FORMAT(a.AuditUpdateDate, 'MM/dd/yyyy') AS [UPDATE_DATE], 
		a.Comment AS [COMMENT]
	FROM 
		tblReportingRequirement a 
		INNER JOIN (
			tblControlMaster aa 
			INNER JOIN tblProperty bb ON aa.ControlId = bb.ControlId_F -- AND bb.PropertyTypeMajorCd_F = 'FMM'
			INNER JOIN tblNote dd ON dd.ControlId_F = aa.ControlId
			INNER JOIN tblNoteExp ee ON ee.NoteId_F = dd.NoteId -- AND ee.ServicerLoanNumber IS NOT NULL
			) ON aa.ControlId = a.ControlId_F
		INNER JOIN tblzCdReportingRequirementSubType c ON c.ReportingRequirementSubTypeCd = a.ReportingRequirementSubTypeCd_F AND c.ReportingRequirementTypeCd_F = a.ReportingRequirementTypeCd_F
		LEFT JOIN (tblSecUser ff 
			INNER JOIN tblContact gg ON gg.ContactID = ff.ContactID_F
			) ON ff.UserId = aa.AssetManager_UserID_F
		LEFT JOIN tblzCdLoanProgram ii ON ii.LoanProgramCD = aa.LoanProgramCD_F
		WHERE 
			a.Inactive = 0 AND
			UPPER(CONCAT(gg.FirstName, SPACE(1), gg.LastName)) IN (@ASSET_MANAGER) AND
			a.ReportingRequirementStatusCd_F IS NULL
		ORDER BY a.AsOfDate, ee.ServicerLoanNumber
END
ELSE IF @REP_REQ_STATUS =  'ALL'
BEGIN
	SELECT 
		UPPER(CONCAT(gg.FirstName, SPACE(1), gg.LastName)) AS [ASSET_MANAGER],
		aa.ControlId AS [BACKSHOP_LOAN_IDENTIFIER],
		ee.ServicerLoanNumber AS [STR_LOAN_IDENTIFIER],
		bb.PropertyName AS [BACKSHOP_PROP_NAME],
		ii.LoanProgramDesc AS [LOAN_PROGRAM],
		a.AssetManagementCovenantCategoryCd_F AS [REPORTING_FOR], 
		a.ReportingRequirementTypeCd_F AS [REPORTING_TYPE],
		c.ReportingRequirementSubTypeDesc AS [REPORTING_SUB_TYPE],
		a.DaysDueWithin AS [DAYS_DUE_WITHIN],
		FORMAT(a.AsOfDate, 'MM/dd/yyyy') AS [AS_OF_DATE],
		ISNULL(a.ReportingRequirementStatusCd_F, 'Open') AS [REQ_STATUS],
		FORMAT(a.ReceivedDate, 'MM/dd/yyyy') AS [RXD_DATE], 
		FORMAT(DATEADD(dd, a.DaysDueWithin, a.AsOfDate), 'MM/dd/yyyy') AS [DUE_DATE], 
		FORMAT(a.AuditUpdateDate, 'MM/dd/yyyy') AS [UPDATE_DATE], 
		a.Comment AS [COMMENT]
	FROM 
		tblReportingRequirement a 
		INNER JOIN (
			tblControlMaster aa 
			INNER JOIN tblProperty bb ON aa.ControlId = bb.ControlId_F -- AND bb.PropertyTypeMajorCd_F = 'FMM'
			INNER JOIN tblNote dd ON dd.ControlId_F = aa.ControlId
			INNER JOIN tblNoteExp ee ON ee.NoteId_F = dd.NoteId -- AND ee.ServicerLoanNumber IS NOT NULL
			) ON aa.ControlId = a.ControlId_F
		INNER JOIN tblzCdReportingRequirementSubType c ON c.ReportingRequirementSubTypeCd = a.ReportingRequirementSubTypeCd_F AND c.ReportingRequirementTypeCd_F = a.ReportingRequirementTypeCd_F
		LEFT JOIN (tblSecUser ff 
			INNER JOIN tblContact gg ON gg.ContactID = ff.ContactID_F
			) ON ff.UserId = aa.AssetManager_UserID_F
		LEFT JOIN tblzCdReportingRequirementStatus hh ON hh.ReportingRequirementStatusCd = a.ReportingRequirementStatusCd_F
		LEFT JOIN tblzCdLoanProgram ii ON ii.LoanProgramCD = aa.LoanProgramCD_F
		WHERE 
			UPPER(CONCAT(gg.FirstName, SPACE(1), gg.LastName)) IN (@ASSET_MANAGER) 
		ORDER BY a.AsOfDate, ee.ServicerLoanNumber
END
ELSE
BEGIN
	SELECT 
		UPPER(CONCAT(gg.FirstName, SPACE(1), gg.LastName)) AS [ASSET_MANAGER],
		aa.ControlId AS [BACKSHOP_LOAN_IDENTIFIER],
		ee.ServicerLoanNumber AS [STR_LOAN_IDENTIFIER],
		bb.PropertyName AS [BACKSHOP_PROP_NAME],
		ii.LoanProgramDesc AS [LOAN_PROGRAM],
		a.AssetManagementCovenantCategoryCd_F AS [REPORTING_FOR], 
		a.ReportingRequirementTypeCd_F AS [REPORTING_TYPE],
		c.ReportingRequirementSubTypeDesc AS [REPORTING_SUB_TYPE],
		a.DaysDueWithin AS [DAYS_DUE_WITHIN],
		FORMAT(a.AsOfDate, 'MM/dd/yyyy') AS [AS_OF_DATE],
		ISNULL(a.ReportingRequirementStatusCd_F, 'Open') AS [REQ_STATUS],
		FORMAT(a.ReceivedDate, 'MM/dd/yyyy') AS [RXD_DATE], 
		FORMAT(DATEADD(dd, a.DaysDueWithin, a.AsOfDate), 'MM/dd/yyyy') AS [DUE_DATE], 
		FORMAT(a.AuditUpdateDate, 'MM/dd/yyyy') AS [UPDATE_DATE], 
		a.Comment AS [COMMENT]
	FROM 
		tblReportingRequirement a 
		INNER JOIN (
			tblControlMaster aa 
			INNER JOIN tblProperty bb ON aa.ControlId = bb.ControlId_F -- AND bb.PropertyTypeMajorCd_F = 'FMM'
			INNER JOIN tblNote dd ON dd.ControlId_F = aa.ControlId
			INNER JOIN tblNoteExp ee ON ee.NoteId_F = dd.NoteId -- AND ee.ServicerLoanNumber IS NOT NULL
			) ON aa.ControlId = a.ControlId_F
		INNER JOIN tblzCdReportingRequirementSubType c ON c.ReportingRequirementSubTypeCd = a.ReportingRequirementSubTypeCd_F AND c.ReportingRequirementTypeCd_F = a.ReportingRequirementTypeCd_F
		LEFT JOIN (tblSecUser ff 
			INNER JOIN tblContact gg ON gg.ContactID = ff.ContactID_F
			) ON ff.UserId = aa.AssetManager_UserID_F
		INNER JOIN tblzCdReportingRequirementStatus hh ON hh.ReportingRequirementStatusCd = a.ReportingRequirementStatusCd_F
		LEFT JOIN tblzCdLoanProgram ii ON ii.LoanProgramCD = aa.LoanProgramCD_F
		WHERE 
			UPPER(CONCAT(gg.FirstName, SPACE(1), gg.LastName)) IN (@ASSET_MANAGER) AND
			a.ReportingRequirementStatusCd_F IN (@REP_REQ_STATUS) 
		ORDER BY a.AsOfDate, ee.ServicerLoanNumber
END				
					

		
	
	
	--SELECT NULL AS ReportingRequirementStatusCd, NULL AS ReportingRequirementStatusDesc, 0 AS OrderKey, 0 AS InactiveSw  
	--UNION
	--SELECT ReportingRequirementStatusCd, ReportingRequirementStatusDesc, OrderKey, InactiveSw  FROM tblzCdReportingRequirementStatus WHERE InactiveSw = 0 ORDER BY OrderKey
	