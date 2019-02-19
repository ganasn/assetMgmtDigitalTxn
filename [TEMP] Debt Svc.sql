-- Debt Service Temp

USE CRE_ODS
GO

DECLARE @ServicerLoanNumber BIGINT = 900100548; --900100548 900100765 900100492 900100933
DECLARE @Liens TABLE (SecondLiens BIGINT, LienOrder INT) 
DECLARE @eom TABLE (dates DATE)
DECLARE @cntr INT = 1

WHILE @cntr <= 12
	BEGIN
		INSERT INTO @eom 
			SELECT EOMONTH(DATEFROMPARTS(YEAR(GETDATE())-1, @cntr, @cntr))
		SET @cntr = @cntr + 1
	END

INSERT INTO @Liens
	SELECT a.ServicerLoanNumber, 
		CASE
			WHEN b.LienPositionCd_F = 'F' THEN 1
			ELSE 2	
		END AS OrderKey 
		FROM tblNoteExp a 
			INNER JOIN tblNote b ON b.NoteId = a.NoteId_F
			LEFT JOIN tblNote c ON b.ControlId_F = c.ControlId_F AND b.NoteId <> c.NoteId
			LEFT JOIN tblNoteExp d ON d.NoteId_F = c.NoteId
		WHERE d.ServicerLoanNumber = @ServicerLoanNumber
	UNION 
	SELECT @ServicerLoanNumber, 
		CASE
			WHEN b.LienPositionCd_F = 'F' THEN 1
			ELSE 2	
		END AS OrderKey 
		FROM tblNote b
			INNER JOIN tblNoteExp a ON a.NoteId_F = b.NoteId
		WHERE a.ServicerLoanNumber = @ServicerLoanNumber



SELECT YEAR(a.[Reporting Period End Date]) AS [YEAR], [Lender/Servicer Loan #] AS [LOANNBR],  CONVERT(MONEY,[Combined NCF after CapEx]/NULLIF([Combined DSCR NCF], 0)) AS [DS_AMT] , b.LienOrder 
	FROM HSB_HIST.DEBT_SERVICE a
		INNER JOIN @Liens b ON b.secondLiens = a.[Lender/Servicer Loan #]
	WHERE CONVERT(BIGINT, [Lender/Servicer Loan #]) IN (SELECT SecondLiens FROM @Liens)
UNION
SELECT YEAR(DATA_EFFDATE) AS [YEAR], a.LOANNBR, SUM(a.[PAYMENT-P&I_AMT]) AS [DS_AMOUNT], b.LienOrder 
	FROM HSB_HIST.STRATEGY_EXTRACT a
		INNER JOIN @Liens b ON a.LOANNBR = b.SecondLiens
	WHERE DATA_EFFDATE IN ( 
			SELECT dates FROM @eom
		)
	GROUP BY a.LOANNBR, LienOrder, YEAR(DATA_EFFDATE) 

