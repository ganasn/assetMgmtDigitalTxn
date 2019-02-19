/* 
This SQL retrieves total income, total op-expenses, total cap-expenses, NOI, & NCF for FNMA properties on Backshop. This data has to be juxtaposed with OSAR data from Strategy for comparison. 
In addition, this SQL identifies those FNMA properties that do NOT have a *900* loan number associated with it in Backshop. If that is the case, loan in Backshop will NOT match that in STR.

*/

USE CRE_ODS
GO

SELECT 
	aa.ControlId,
	ee.ServicerLoanNumber,
	cc.StatementYear,
	a.EffGrossInc, 
	a.TotalOpExp,
	a.NetOpInc,
	a.TotalCapital,
	a.NetCashFlow, 
	bb.StreetAddress
FROM 
	tblOperatingStatementBlueLineCalc a 
	INNER JOIN (
		tblControlMaster aa 
		INNER JOIN tblProperty bb ON aa.ControlId = bb.ControlId_F AND bb.PropertyTypeMajorCd_F = 'FMM'
		INNER JOIN tblOpStatementHeader cc ON cc.PropertyId_F = bb.PropertyId AND cc.MonthsCovered = 12 AND FORMAT(cc.StatementDate, 'MM/dd/yyyy') = '12/31/2017'
		INNER JOIN tblNote dd ON dd.ControlId_F = aa.ControlId
		INNER JOIN tblNoteExp ee ON ee.NoteId_F = dd.NoteId -- AND ee.ServicerLoanNumber IS NOT NULL
		) ON cc.OpStatementHeaderId = a.OpStatementHeaderId_F

		