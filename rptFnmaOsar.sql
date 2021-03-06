
USE CRE_ODS
GO

DECLARE @ServicerLoanNumber BIGINT = 509172; --600101246 900100415 900100632 439119 
DECLARE @OpStmtName_Prior INT = 2838, @OpStmtName_Latest INT = 2835; 
DECLARE @DS_A_Note_Prior MONEY = 414517.92, @DS_B_Note_Prior MONEY = 0, @DS_A_Note_Latest MONEY = 0, @DS_B_Note_Latest MONEY = 0;
DECLARE @RR_BB_Latest MONEY = 0, @RR_BB_Prior MONEY = 0, @RR_EB_Latest MONEY = 0, @RR_EB_Prior MONEY = 0, @RR_Exp_Latest MONEY = 0, @RR_Exp_Prior MONEY = 0;


-- OPERATING STATEMENT SELECTIONS
--SELECT OpStatementHeaderId, StatementYear
--	FROM tblOpStatementHeader
--	WHERE
--		PropertyId_F IN
--			(SELECT PropertyId FROM tblProperty WHERE ControlId_F = (SELECT ControlID FROM (tblControlMaster INNER JOIN tblNote ON ControlId = ControlId_F) INNER JOIN tblNoteExp ON NoteId_F = NoteId WHERE ServicerLoanNumber = @ServicerLoanNumber))
--	ORDER BY SortOrder

-- HEADER SETUP
--SELECT a.PropertyName, b.ServicerLoanNumber FROM tblProperty a INNER JOIN tblNote c ON a.ControlId_F = c.ControlId_F INNER JOIN tblNoteExp b ON b.NoteId_F = c.NoteId AND b.ServicerLoanNumber = @ServicerLoanNumber


-- FOUNDATION SETUP
DECLARE @fnmaOsar TABLE (
	LOANNUMBER BIGINT, 
	MD_STATEMENT_ORDER INT, 
	MD_NOI_CAT_TYPE_ORDER INT, 
	MD_NOI_CAT_TYPE_NAME NVARCHAR (100),
	MD_STATEMENT_ID	INT, 
	MD_NOI_CAT_ORDER INT, 
	STATEMENT_YEAR NVARCHAR(100), 
	NOI_CATEGORY NVARCHAR(100), 
	REPORTED MONEY, 
	ADJUSTMENTS MONEY, 
	NORMALIZED MONEY
	)

-- IDENTIFY Control Id FOR SUBSEQUENT PROCESSING
DECLARE @ControlId NVARCHAR (7) = (SELECT ControlID_F FROM tblNote a INNER JOIN tblNoteExp b ON a.NoteId = b.NoteId_F AND b.ServicerLoanNumber = @ServicerLoanNumber) 


-- OPERATING STATEMENTS
INSERT INTO @fnmaOsar (MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED)
SELECT 
    CASE 
		WHEN b.OpStatementHeaderId = @OpStmtName_Latest THEN 0
		WHEN b.OpStatementHeaderId = @OpStmtName_Prior THEN 1
		ELSE 2
	END AS MD_STATEMENT_ORDER, 
	g.OrderKey AS [MD_NOI_CAT_TYPE_ORDER], 
	CASE 
		WHEN f.NOICategoryTypeCd_F = 'I' THEN 'Income' 
		WHEN f.NOICategoryTypeCd_F = 'O' THEN 'Expenses' 
		WHEN f.NOICategoryTypeCd_F = 'C' THEN 'Capital Expenditures' 
	END AS [MD_NOI_CAT_TYPE_NAME], 	
	-- g.NOICategoryTypeDesc AS [MD_NOI_CAT_TYPE_NAME], 
	b.OpStatementHeaderId AS [MD_STATEMENT_ID], 
	f.OrderKey AS [MD_NOI_CAT_ORDER], 
	b.StatementYear AS [STATEMENT_YEAR], 
	f.NOICategoryDesc AS [NOI_CATEGORY], 
	SUM(a.ItemAmount) AS [REPORTED], 
	SUM(a.ItemAmountAdj) AS [ADJUSTMENTS], 
	SUM(a.ItemAmountAfterAdjustment) AS [NORMALIZED]
FROM tblOpStatementDetail a 
	INNER JOIN tblOpStatementHeader b ON a.OpStatementHeaderId_F = b.OpStatementHeaderId
	INNER JOIN tblProperty c ON c.PropertyId = b.PropertyId_F
	INNER JOIN tblNote d ON c.ControlId_F = d.ControlId_F
	INNER JOIN tblNoteExp e ON d.NoteId = e.NoteId_F
	INNER JOIN tblzCdNOICategory f ON f.NOICategoryCd = a.NOICategoryCd_F
	INNER JOIN tblzCdNOICategoryType g ON g.NOICategoryTypeCd = f.NOICategoryTypeCd_F
WHERE 
	e.ServicerLoanNumber = @ServicerLoanNumber AND 
	b.OpStatementHeaderId IN (@OpStmtName_Latest, @OpStmtName_Prior)
GROUP BY 
	b.OpStatementHeaderId, b.StatementYear, f.NOICategoryTypeCd_F, f.NOICategoryDesc, g.OrderKey, f.OrderKey
ORDER BY 
	b.OpStatementHeaderId, g.OrderKey, f.OrderKey


INSERT INTO @fnmaOsar (MD_STATEMENT_ID, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_ORDER, MD_NOI_CAT_TYPE_NAME, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, NORMALIZED) 
	(SELECT OpStatementHeaderId_F, 10, 890 /*MAX(b.OrderKey) + 10*/ ,'Income', StatementYear, 'Effective Gross Income', SUM(ItemAmount), SUM(ItemAmountAfterAdjustment) FROM tblOpStatementDetail 
		INNER JOIN tblOpStatementHeader ON OpStatementHeaderId = OpStatementHeaderId_F
		INNER JOIN tblzCdNOICategory b ON NOICategoryCd = NOICategoryCd_F
		WHERE OpStatementHeaderId_F IN (@OpStmtName_Latest, @OpStmtName_Prior)
			AND NOICategoryTypeCd_F = 'I'
		GROUP BY OpStatementHeaderId_F, StatementYear)
	UNION 
	(SELECT OpStatementHeaderId_F, 20, 960 /*MAX(b.OrderKey) + 10 */,'Expenses', StatementYear, 'Total Expenses', SUM(ItemAmount), SUM(ItemAmountAfterAdjustment) FROM tblOpStatementDetail 
		INNER JOIN tblOpStatementHeader ON OpStatementHeaderId = OpStatementHeaderId_F
		INNER JOIN tblzCdNOICategory b ON NOICategoryCd = NOICategoryCd_F
		WHERE OpStatementHeaderId_F IN  (@OpStmtName_Latest, @OpStmtName_Prior)
			AND NOICategoryTypeCd_F = 'O'
		GROUP BY OpStatementHeaderId_F, StatementYear)
	UNION
	(SELECT OpStatementHeaderId_F, 30, MAX(b.OrderKey) + 10 ,'Capital Expenditures', StatementYear, 'Total Capital:', SUM(ItemAmount), SUM(ItemAmountAfterAdjustment) FROM tblOpStatementDetail 
		INNER JOIN tblOpStatementHeader ON OpStatementHeaderId = OpStatementHeaderId_F
		INNER JOIN tblzCdNOICategory b ON NOICategoryCd = NOICategoryCd_F
		WHERE OpStatementHeaderId_F IN  (@OpStmtName_Latest, @OpStmtName_Prior)
			AND NOICategoryTypeCd_F = 'C'
		GROUP BY OpStatementHeaderId_F, StatementYear)

INSERT INTO @fnmaOsar (MD_STATEMENT_ID, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_ORDER, MD_NOI_CAT_TYPE_NAME, STATEMENT_YEAR, NOI_CATEGORY, REPORTED) 
	SELECT OpStatementHeaderId, 10, 900,'Income', StatementYear, 'Physical Occupancy', (Occupancy) FROM tblOpStatementHeader WHERE OpStatementHeaderId IN (@OpStmtName_Prior, @OpStmtName_Latest)


UPDATE @fnmaOsar SET LOANNUMBER = @ServicerLoanNumber, MD_STATEMENT_ORDER = (
		CASE 
			WHEN @OpStmtName_Latest = MD_STATEMENT_ID THEN 0
			WHEN @OpStmtName_Prior = MD_STATEMENT_ID THEN 1
			ELSE 2
		END
	) 


-- DEBT SERVICE - BEGIN

DECLARE @Liens TABLE (FirstLien BIGINT, SecondLiens BIGINT, LienOrder INT, DSYear INT, DSAmount MONEY) 
DECLARE @eom TABLE (dates DATE)
DECLARE @cntr INT = 1

WHILE @cntr <= 12
	BEGIN
		INSERT INTO @eom 
			SELECT EOMONTH(DATEFROMPARTS(YEAR(GETDATE())-1, @cntr, @cntr))
		SET @cntr = @cntr + 1
	END

	-- DS: SETUP A & B NOTES FOR 2 YEARS
INSERT INTO @Liens (FirstLien, SecondLiens, LienOrder, DSYear)
	SELECT d.ServicerLoanNumber, a.ServicerLoanNumber, 
		CASE
			WHEN b.LienPositionCd_F = 'F' THEN 1
			ELSE 2	
		END AS OrderKey, 
		YEAR(GETDATE()) - 1 
		FROM tblNoteExp a 
			INNER JOIN tblNote b ON b.NoteId = a.NoteId_F
			LEFT JOIN tblNote c ON b.ControlId_F = c.ControlId_F AND b.NoteId <> c.NoteId
			LEFT JOIN tblNoteExp d ON d.NoteId_F = c.NoteId
		WHERE d.ServicerLoanNumber = @ServicerLoanNumber
	UNION 
	SELECT a.ServicerLoanNumber, @ServicerLoanNumber, 
		CASE
			WHEN b.LienPositionCd_F = 'F' THEN 1
			ELSE 2	
		END AS OrderKey, 
		YEAR(GETDATE()) - 1 
		FROM tblNote b
			INNER JOIN tblNoteExp a ON a.NoteId_F = b.NoteId
		WHERE a.ServicerLoanNumber = @ServicerLoanNumber
	UNION
	SELECT d.ServicerLoanNumber, a.ServicerLoanNumber, 
		CASE
			WHEN b.LienPositionCd_F = 'F' THEN 1
			ELSE 2	
		END AS OrderKey, 
		YEAR(GETDATE()) - 2 
		FROM tblNoteExp a 
			INNER JOIN tblNote b ON b.NoteId = a.NoteId_F
			LEFT JOIN tblNote c ON b.ControlId_F = c.ControlId_F AND b.NoteId <> c.NoteId
			LEFT JOIN tblNoteExp d ON d.NoteId_F = c.NoteId
		WHERE d.ServicerLoanNumber = @ServicerLoanNumber
	UNION 
	SELECT a.ServicerLoanNumber, @ServicerLoanNumber, 
		CASE
			WHEN b.LienPositionCd_F = 'F' THEN 1
			ELSE 2	
		END AS OrderKey, 
		YEAR(GETDATE()) - 2 
		FROM tblNote b
			INNER JOIN tblNoteExp a ON a.NoteId_F = b.NoteId
		WHERE a.ServicerLoanNumber = @ServicerLoanNumber

	-- DS: RETRIEVE DS DATA
;WITH ds_cte AS (
	SELECT YEAR(a.[Reporting Period End Date]) AS [YEAR], [Lender/Servicer Loan #] AS [LOANNBR],  CONVERT(MONEY,[Combined NCF after CapEx]/NULLIF([Combined DSCR NCF], 0)) AS [DS_AMT] , b.LienOrder 
		FROM HSB_HIST.DEBT_SERVICE a
			INNER JOIN @Liens b ON b.secondLiens = a.[Lender/Servicer Loan #]
		WHERE CONVERT(BIGINT, [Lender/Servicer Loan #]) IN (SELECT SecondLiens FROM @Liens)
	UNION
	SELECT YEAR(DATA_EFFDATE) AS [YEAR], a.LOANNBR, SUM(a.[PAYMENT-P&I_AMT]) AS [DS_AMT], b.LienOrder 
		FROM HSB_HIST.STRATEGY_EXTRACT a
			INNER JOIN (SELECT DISTINCT LienOrder, SecondLiens FROM @Liens ) AS b ON a.LOANNBR = b.SecondLiens
		WHERE DATA_EFFDATE IN ( 
				SELECT dates FROM @eom
			)
		GROUP BY a.LOANNBR, LienOrder, YEAR(DATA_EFFDATE) 
	)

	-- DS: CONSOLIDATE DS DATASET

UPDATE a SET 
		a.DSAmount = b.DS_AMT	
	FROM @Liens a INNER JOIN ds_cte b ON a.SecondLiens = b.LOANNBR AND a.DSYear = b.[YEAR]

	-- DS: INCORPORATE DS DATA INTO FOUNDATION
INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED) 
	SELECT FirstLien, CASE
			WHEN DSYear = (YEAR(GETDATE()) - 2)  THEN 1
			WHEN DSYear = (YEAR(GETDATE()) - 1)  THEN 0
		END, 40, 'Cash Flow Analysis', CASE
			WHEN DSYear = (YEAR(GETDATE()) - 2)  THEN @OpStmtName_Prior
			WHEN DSYear = (YEAR(GETDATE()) - 1)  THEN @OpStmtName_Latest
		END, 20, '', 'Debt Service - A Note:', ISNULL(DSAmount, 0), 0, ISNULL(DSAmount, 0) FROM @Liens WHERE LienOrder = 1
	UNION
	SELECT FirstLien, CASE
			WHEN DSYear = (YEAR(GETDATE()) - 2)  THEN 1
			WHEN DSYear = (YEAR(GETDATE()) - 1)  THEN 0
		END, 40, 'Cash Flow Analysis',  CASE
			WHEN DSYear = (YEAR(GETDATE()) - 2)  THEN @OpStmtName_Prior
			WHEN DSYear = (YEAR(GETDATE()) - 1)  THEN @OpStmtName_Latest
		END, 30, '', 'Debt Service - B Note:', ISNULL(DSAmount, 0), 0, ISNULL(DSAmount, 0) FROM @Liens WHERE LienOrder = 2

	--DS: ADDRESS USER INPUT, IF ANY, FOR DS 
IF @DS_A_Note_Latest <> 0 
	BEGIN
		UPDATE @fnmaOsar SET REPORTED = @DS_A_Note_Latest, NORMALIZED = @DS_A_Note_Latest
			WHERE NOI_CATEGORY = 'Debt Service - A Note:' AND MD_STATEMENT_ORDER = 0
	END 
IF @DS_A_Note_Prior <> 0 
	BEGIN
		UPDATE @fnmaOsar SET REPORTED = @DS_A_Note_Prior, NORMALIZED = @DS_A_Note_Prior
			WHERE NOI_CATEGORY = 'Debt Service - A Note:' AND MD_STATEMENT_ORDER = 1
	END
IF @DS_B_Note_Latest <> 0 
	BEGIN
		UPDATE @fnmaOsar SET REPORTED = @DS_B_Note_Latest, NORMALIZED = @DS_B_Note_Latest
			WHERE NOI_CATEGORY = 'Debt Service - B Note:' AND MD_STATEMENT_ORDER = 0
	END
IF @DS_B_Note_Prior <> 0 
	BEGIN
		UPDATE @fnmaOsar SET REPORTED = @DS_B_Note_Prior, NORMALIZED = @DS_B_Note_Prior
			WHERE NOI_CATEGORY = 'Debt Service - B Note:' AND MD_STATEMENT_ORDER = 1
	END

	--Gana: On 3/4/19, adding DS on B-Note when there isn't one - BEGIN
	IF NOT EXISTS (SELECT * FROM @fnmaOsar WHERE NOI_CATEGORY = 'Debt Service - B Note:' AND MD_STATEMENT_ORDER = 0)
	BEGIN 
		INSERT INTO @fnmaOsar
			SELECT @ServicerLoanNumber, 0, 40, 'Cash Flow Analysis', @OpStmtName_Latest, 30, '', 'Debt Service - B Note:', 0, 0, 0
	END
	IF NOT EXISTS (SELECT * FROM @fnmaOsar WHERE NOI_CATEGORY = 'Debt Service - B Note:' AND MD_STATEMENT_ORDER = 1)
	BEGIN 
		INSERT INTO @fnmaOsar
			SELECT @ServicerLoanNumber, 1, 40, 'Cash Flow Analysis', @OpStmtName_Prior, 30, '', 'Debt Service - B Note:', 0, 0, 0
	END

	--Gana: On 3/4/19, adding DS on B-Note when there isn't one - END


-- DEBT SERVICE - END


-- REPLACEMENT RESERVES - BEGIN

	--RR: TEMP DATASET TO HOLD R/R TRANSACTIONS
DECLARE @rr_txn TABLE (ROW_NUM INT, LOAN_NUMBER BIGINT, ESCROW_SEQ INT, BEG_BAL MONEY, DDA_AC_NUM BIGINT, TXN_CODE NVARCHAR (4), TXN_DESC NVARCHAR (25), TXN_DATE DATE, PAID_DATE DATE)

		;WITH rr_cte AS(
		-- Gana: On 3/8/19, simplified CTE to process disbursals (debits) before interests & payments (credits) - BEGIN
			SELECT ROW_NUMBER() OVER (PARTITION BY [LOAN NUMBER] ORDER BY CONVERT(DATE, [TRANSACTION DATE]), [FULL DESC] DESC) AS ROW_NUM, 
					[LOAN NUMBER],
					[ESCROW #],
					[BEGINNING BALANCE],
					[D.D.A. #],
					[TRANSACTION CODE],
					[FULL DESC],
					CONVERT(DATE, [TRANSACTION DATE]) AS [TRANSACTION DATE],
					CONVERT(DATE, [PAID FOR DATE]) AS [PAID FOR DATE] 
				FROM HSB_HIST.REPLACEMENT_RESERVES 
					WHERE [LOAN NUMBER] = @ServicerLoanNumber
						AND YEAR(CONVERT(DATE, [DATE LAST POSTED])) = YEAR(GETDATE()) 
						AND (YEAR(CONVERT(DATE, [TRANSACTION DATE])) IN (YEAR(GETDATE()) - 2, YEAR(GETDATE()) - 1, YEAR(GETDATE()))) 
						AND [D.D.A. #] IN (
							SELECT DISTINCT [D.D.A. #] FROM HSB_HIST.REPLACEMENT_RESERVES 
								WHERE [LOAN NUMBER] IN (@ServicerLoanNumber) 
									AND YEAR(CONVERT(DATE, [PAID FOR DATE])) IN (YEAR(GETDATE()), YEAR(GETDATE()) - 1, YEAR(GETDATE()) - 2)
							)
		-- Gana: On 3/8/19, simplified CTE to process disbursals (debits) before interests & payments (Credits) - END
			)
		INSERT INTO @rr_txn
			SELECT * FROM rr_cte

		--Gana: On 3/4/19, added IF section to short-circuit entire process when there are no reserves collected on a loan -AND- ELSE section to default records in such case - END
	IF EXISTS (SELECT * FROM @rr_txn) 
	BEGIN
		DECLARE @rr_data TABLE (LOAN_NUMBER BIGINT, BEG_BAL MONEY, END_BAL MONEY, DISBURSALS MONEY, TXN_YEAR INT)

			--RR: DATASET TO HOLD R/R DATA FOR OSAR
		INSERT INTO @rr_data (TXN_YEAR, LOAN_NUMBER)
			SELECT DISTINCT YEAR(TXN_DATE), LOAN_NUMBER FROM @rr_txn

		UPDATE @rr_data SET
			DISBURSALS = (
				SELECT SUM(ISNULL([DIFF], 0)) AS [DISBURSALS] FROM (
					SELECT ISNULL((b.[BEG_BAL] - a.[BEG_BAL]), 0) AS [DIFF], a.* FROM @rr_txn a INNER JOIN @rr_txn b ON a.ROW_NUM + 1 = b.ROW_NUM --AND a.[DDA_AC_NUM] = b.[DDA_AC_NUM]  
					) AS B
				WHERE B.TXN_DESC LIKE '%DIS%' AND YEAR(B.TXN_DATE) IN (YEAR(GETDATE()) - 1, YEAR(GETDATE()) - 2) AND LOAN_NUMBER = LOAN_NUMBER AND TXN_YEAR = YEAR(TXN_DATE) 
				GROUP BY LOAN_NUMBER, YEAR(B.TXN_DATE)
			)

			--RR: TEMP DATASET TO HOLD FIRST TRANSACTION DATES FOR EASY DATA ACCESS FROM RR_TXN TEMP DATASET 
		DECLARE @rr_dates TABLE (DATES DATE, TXN_YEAR INT, LOAN_NUMBER BIGINT)

		INSERT INTO @rr_dates
			SELECT MIN(TXN_DATE) AS DATES, YEAR(TXN_DATE) AS TXN_YEAR, LOAN_NUMBER FROM @rr_txn GROUP BY LOAN_NUMBER, YEAR(TXN_DATE)

			--RR: CONSOLIDATE R/R DATASET
		UPDATE a SET 
			a.BEG_BAL = b.BEG_BAL,
			a.DISBURSALS = ISNULL(a.DISBURSALS, 0)
			FROM @rr_data a INNER JOIN @rr_txn b ON a.LOAN_NUMBER = b.LOAN_NUMBER 
				INNER JOIN @rr_dates c ON a.LOAN_NUMBER = c.LOAN_NUMBER
			WHERE b.TXN_DATE = c.DATES AND a.TXN_YEAR = c.TXN_YEAR

		UPDATE a SET 
			a.END_BAL = ISNULL(b.BEG_BAL, 0)
			FROM @rr_data a INNER JOIN @rr_txn b ON a.LOAN_NUMBER = b.LOAN_NUMBER 
				INNER JOIN @rr_dates c ON a.LOAN_NUMBER = c.LOAN_NUMBER
			WHERE b.TXN_DATE = c.DATES AND a.TXN_YEAR = (c.TXN_YEAR - 1)

			--RR: ADDRESS USER INPUT, IF ANY, FOR REPLACEMENT RESERVES	
		IF @RR_BB_Latest <> 0 
			BEGIN
				UPDATE @rr_data SET BEG_BAL = @RR_BB_Latest WHERE TXN_YEAR = YEAR(GETDATE())-1 
			END
		IF @RR_BB_Prior <> 0 
			BEGIN
				UPDATE @rr_data SET BEG_BAL = @RR_BB_Prior WHERE TXN_YEAR = YEAR(GETDATE())-2 
			END
		IF @RR_EB_Latest <> 0 
			BEGIN
				UPDATE @rr_data SET END_BAL = @RR_EB_Latest WHERE TXN_YEAR = YEAR(GETDATE())-1
			END
		IF @RR_EB_Prior <> 0 
			BEGIN
				UPDATE @rr_data SET END_BAL = @RR_EB_Prior WHERE TXN_YEAR = YEAR(GETDATE())-2 
			END
		IF @RR_Exp_Latest <> 0 
			BEGIN
				UPDATE @rr_data SET DISBURSALS = -1 * @RR_Exp_Latest WHERE TXN_YEAR = YEAR(GETDATE())-1
			END
		IF @RR_Exp_Prior <> 0 
			BEGIN
				UPDATE @rr_data SET DISBURSALS = -1 * @RR_Exp_Prior WHERE TXN_YEAR = YEAR(GETDATE())-2 
			END
	
			--RR: INCORPORATE R/R DATA INTO FNMA OSAR DATASET
			--Gana: On 3/4/19, included CASE to populate OpStmt ID instead of 0 for MD_STATEMENT_ID - BEGIN
		INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED) 
			(SELECT LOAN_NUMBER, CASE 
					WHEN TXN_YEAR = (SELECT MIN(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN 1
					WHEN TXN_YEAR = (SELECT MAX(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN 0
				END, 50, 'Replacement Reserve Activity', CASE 
					WHEN TXN_YEAR = (SELECT MIN(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN @OpStmtName_Prior
					WHEN TXN_YEAR = (SELECT MAX(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN @OpStmtName_Latest
				END, 10, '', 'Beginning Balance:', 0, 0, BEG_BAL FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR)
			UNION 
			(SELECT LOAN_NUMBER, CASE 
					WHEN TXN_YEAR = (SELECT MIN(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN 1
					WHEN TXN_YEAR = (SELECT MAX(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN 0
				END, 50, 'Replacement Reserve Activity', CASE 
					WHEN TXN_YEAR = (SELECT MIN(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN @OpStmtName_Prior
					WHEN TXN_YEAR = (SELECT MAX(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN @OpStmtName_Latest
				END, 20, '', '  Less: Expenditures:', 0, 0, DISBURSALS FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR)
			UNION
			(SELECT LOAN_NUMBER, CASE 
					WHEN TXN_YEAR = (SELECT MIN(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN 1
					WHEN TXN_YEAR = (SELECT MAX(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN 0
				END, 50, 'Replacement Reserve Activity', CASE 
					WHEN TXN_YEAR = (SELECT MIN(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN @OpStmtName_Prior
					WHEN TXN_YEAR = (SELECT MAX(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN @OpStmtName_Latest
				END, 30, '', '  Plus: Additions:', 0, 0, (END_BAL - DISBURSALS - BEG_BAL) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR)
			UNION
			(SELECT LOAN_NUMBER, CASE 
					WHEN TXN_YEAR = (SELECT MIN(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN 1
					WHEN TXN_YEAR = (SELECT MAX(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN 0
				END, 50, 'Replacement Reserve Activity', CASE 
					WHEN TXN_YEAR = (SELECT MIN(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN @OpStmtName_Prior
					WHEN TXN_YEAR = (SELECT MAX(TXN_YEAR) FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR) THEN @OpStmtName_Latest
				END, 40, '', 'Ending Balance:', 0, 0, END_BAL FROM @rr_data WHERE YEAR(GETDATE()) <> TXN_YEAR)
			--Gana: On 3/4/19, included CASE to populate OpStmt ID instead of 0 for MD_STATEMENT_ID - END
	END
	ELSE
	BEGIN
		INSERT INTO @fnmaOsar
			SELECT @ServicerLoanNumber, 0, 50, 'Replacement Reserve Activity', @OpStmtName_Latest, 10, '', 'Beginning Balance:', 0, 0, 0
			UNION
			SELECT @ServicerLoanNumber, 0, 50, 'Replacement Reserve Activity', @OpStmtName_Latest, 20, '', '  Less: Expenditures:', 0, 0, 0
			UNION
			SELECT @ServicerLoanNumber, 0, 50, 'Replacement Reserve Activity', @OpStmtName_Latest, 30, '', '  Plus: Additions:', 0, 0, 0
			UNION
			SELECT @ServicerLoanNumber, 0, 50, 'Replacement Reserve Activity', @OpStmtName_Latest, 40, '', 'Ending Balance:', 0, 0, 0
			UNION 
			SELECT @ServicerLoanNumber, 1, 50, 'Replacement Reserve Activity', @OpStmtName_Prior, 10, '', 'Beginning Balance:', 0, 0, 0
			UNION
			SELECT @ServicerLoanNumber, 1, 50, 'Replacement Reserve Activity', @OpStmtName_Prior, 20, '', '  Less: Expenditures:', 0, 0, 0
			UNION
			SELECT @ServicerLoanNumber, 1, 50, 'Replacement Reserve Activity', @OpStmtName_Prior, 30, '', '  Plus: Additions:', 0, 0, 0
			UNION
			SELECT @ServicerLoanNumber, 1, 50, 'Replacement Reserve Activity', @OpStmtName_Prior, 40, '', 'Ending Balance:', 0, 0, 0
	END
		--Gana: On 3/4/19, added IF section to short-circuit entire process when there are no reserves collected on a loan -AND- ELSE section to default records in such case - END

-- REPLACEMENT RESERVES - END

-- COMPUTE RATIOS
INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED) 
	SELECT @ServicerLoanNumber, 0, 20, 'Expenses', @OpStmtName_Latest, 980, '' , 'Management Fee % of EGI', (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%man%fee%' AND MD_STATEMENT_ORDER = 0)/(SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 0), 0, (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%man%fee%' AND MD_STATEMENT_ORDER = 0)/(SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 0)
	UNION
	SELECT @ServicerLoanNumber, 1, 20, 'Expenses', @OpStmtName_Prior , 980, '', 'Management Fee % of EGI', (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%man%fee%' AND MD_STATEMENT_ORDER = 0)/(SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 0), 0, (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%man%fee%' AND MD_STATEMENT_ORDER = 1)/(SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 1)
	UNION
	SELECT @ServicerLoanNumber, 0, 20, 'Expenses', @OpStmtName_Latest, 970, '' , 'Expenses % of EGI', (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%exp%' AND MD_STATEMENT_ORDER = 0)/(SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 0), 0, (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%exp%' AND MD_STATEMENT_ORDER = 0)/(SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 0)
	UNION
	SELECT @ServicerLoanNumber, 1, 20, 'Expenses', @OpStmtName_Prior , 970, '', 'Expenses % of EGI', (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%exp%' AND MD_STATEMENT_ORDER = 0)/(SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 0), 0, (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%exp%' AND MD_STATEMENT_ORDER = 1)/(SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 1)
	UNION
	SELECT @ServicerLoanNumber, 0, 20, 'Expenses', @OpStmtName_Latest, 990, '' , 'NOI', (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 0) - (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%exp%' AND MD_STATEMENT_ORDER = 0), 0, (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 0) - (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%exp%' AND MD_STATEMENT_ORDER = 0)
	UNION
	SELECT @ServicerLoanNumber, 1, 20, 'Expenses', @OpStmtName_Prior, 990, '' , 'NOI', (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 1) - (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%exp%' AND MD_STATEMENT_ORDER = 1), 0, (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%eff%gro%inc%' AND MD_STATEMENT_ORDER = 1) - (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%exp%' AND MD_STATEMENT_ORDER = 1)

INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED) 
	SELECT @ServicerLoanNumber, 0, 40, 'Cash Flow Analysis', @OpStmtName_Latest, 10, '' , 'Net Cash Flow: ', (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%noi%' AND MD_STATEMENT_ORDER = 0) - (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%cap%' AND MD_STATEMENT_ORDER = 0), 0, (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%noi%' AND MD_STATEMENT_ORDER = 0) - (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%cap%' AND MD_STATEMENT_ORDER = 0)
	UNION
	SELECT @ServicerLoanNumber, 1, 40, 'Cash Flow Analysis', @OpStmtName_Prior, 10, '' , 'Net Cash Flow: ', (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%noi%' AND MD_STATEMENT_ORDER = 1) - (SELECT REPORTED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%cap%' AND MD_STATEMENT_ORDER = 1), 0, (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%noi%' AND MD_STATEMENT_ORDER = 1) - (SELECT NORMALIZED FROM @fnmaOsar WHERE NOI_CATEGORY LIKE '%tot%cap%' AND MD_STATEMENT_ORDER = 1)

INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED) 
	SELECT @ServicerLoanNumber, 0, 40, 'Cash Flow Analysis', @OpStmtName_Latest, 40, '' , 'DSCR: (NOI / Debt Service - A Note):', (SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%NOI%')/(SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Deb%Serv%A%'), 0, (SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%NOI%')/(SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Deb%Serv%A%')
	UNION
	SELECT @ServicerLoanNumber, 1, 40, 'Cash Flow Analysis', @OpStmtName_Prior, 40, '' , 'DSCR: (NOI / Debt Service - A Note):', (SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%NOI%')/(SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Deb%Serv%A%'), 0,  (SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%NOI%')/(SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Deb%Serv%A%')
	UNION 
	SELECT @ServicerLoanNumber, 0, 40, 'Cash Flow Analysis', @OpStmtName_Latest, 50, '' , 'DSCR: (NOI / Debt Service - A, B Note):', (SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%NOI%')/(SELECT SUM(REPORTED) FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Deb%Serv%'), 0,  (SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%NOI%')/(SELECT SUM(NORMALIZED) FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Deb%Serv%')
	UNION 
	SELECT @ServicerLoanNumber, 1, 40, 'Cash Flow Analysis', @OpStmtName_Prior, 50, '' , 'DSCR: (NOI / Debt Service - A, B Note):', (SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%NOI%')/(SELECT SUM(REPORTED) FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Deb%Serv%'), 0,  (SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%NOI%')/(SELECT SUM(NORMALIZED) FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Deb%Serv%')
	UNION
	SELECT @ServicerLoanNumber, 0, 40, 'Cash Flow Analysis', @OpStmtName_Latest, 60, '' , 'DSCR: (NCF After CapEx / Debt Service - A Note):', (SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Net%Cas%Flo%')/(SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Deb%Serv%A%'), 0,  (SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Net%Cas%Flo%')/(SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Deb%Serv%A%')
	UNION
	SELECT @ServicerLoanNumber, 1, 40, 'Cash Flow Analysis', @OpStmtName_Prior, 60, '' , 'DSCR: (NCF After CapEx / Debt Service - A Note):', (SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Net%Cas%Flo%')/(SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Deb%Serv%A%'), 0,  (SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Net%Cas%Flo%')/(SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Deb%Serv%A%')
	UNION 
	SELECT @ServicerLoanNumber, 0, 40, 'Cash Flow Analysis', @OpStmtName_Latest, 70, '' , 'DSCR: (NCF After CapEx / Debt Service - A, B Note):', (SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Net%Cas%Flo%')/(SELECT SUM(REPORTED) FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Deb%Serv%'), 0,  (SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Net%Cas%Flo%')/(SELECT SUM(NORMALIZED) FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 0 AND NOI_CATEGORY LIKE '%Deb%Serv%')
	UNION 
	SELECT @ServicerLoanNumber, 1, 40, 'Cash Flow Analysis', @OpStmtName_Prior, 70, '' , 'DSCR: (NCF After CapEx / Debt Service - A, B Note):', (SELECT REPORTED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Net%Cas%Flo%')/(SELECT SUM(REPORTED) FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Deb%Serv%'), 0,  (SELECT NORMALIZED FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Net%Cas%Flo%')/(SELECT SUM(NORMALIZED) FROM @fnmaOsar WHERE MD_STATEMENT_ORDER = 1 AND NOI_CATEGORY LIKE '%Deb%Serv%')


-- Gana: Accounting for missing NOI categories - BEGIN
-- ADD NOI CATEGORIES THAT DO NOT HAVE ENTRIES IN THE "LATEST" O/S
INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED)
	SELECT @ServicerLoanNumber, 0, CASE 
			WHEN c.NOICategoryTypeCd_F = 'I' THEN 10
			WHEN c.NOICategoryTypeCd_F = 'O' THEN 20
			WHEN c.NOICategoryTypeCd_F = 'C' THEN 30
		END, CASE 
			WHEN c.NOICategoryTypeCd_F = 'I' THEN 'Income'
			WHEN c.NOICategoryTypeCd_F = 'O' THEN 'Expenses'
			WHEN c.NOICategoryTypeCd_F = 'C' THEN 'Capital Expenditures'
		END, @OpStmtName_Latest, c.OrderKey, (SELECT StatementYear FROM tblOpStatementHeader WHERE OpStatementHeaderId = @OpStmtName_Latest), c.NOICategoryDesc, 0, 0, 0
		FROM @fnmaOsar a 
			RIGHT JOIN (tblzCdNOICatPropType b 
				INNER JOIN tblzCdNOICategory c ON b.NOICategoryCd_F = c.NOICategoryCd AND b.InactiveSw = 0 AND b.PropertyTypeMajorCd_F = (SELECT PropertyTypeMajorCd_F FROM tblProperty WHERE ControlId_F = @ControlId)
				) ON a.NOI_CATEGORY = c.NOICategoryDesc AND a.MD_STATEMENT_ID = @OpStmtName_Latest 
		WHERE a.NOI_CATEGORY IS NULL

-- ADD NOI CATEGORIES THAT DO NOT HAVE ENTRIES IN THE "PRIOR" O/S
INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED)
	SELECT @ServicerLoanNumber, 1, CASE 
			WHEN c.NOICategoryTypeCd_F = 'I' THEN 10
			WHEN c.NOICategoryTypeCd_F = 'O' THEN 20
			WHEN c.NOICategoryTypeCd_F = 'C' THEN 30
		END, CASE 
			WHEN c.NOICategoryTypeCd_F = 'I' THEN 'Income'
			WHEN c.NOICategoryTypeCd_F = 'O' THEN 'Expenses'
			WHEN c.NOICategoryTypeCd_F = 'C' THEN 'Capital Expenditures'
		END, @OpStmtName_Prior, c.OrderKey, (SELECT StatementYear FROM tblOpStatementHeader WHERE OpStatementHeaderId = @OpStmtName_Prior), c.NOICategoryDesc, 0, 0, 0
		FROM @fnmaOsar a 
			RIGHT JOIN (tblzCdNOICatPropType b 
				INNER JOIN tblzCdNOICategory c ON b.NOICategoryCd_F = c.NOICategoryCd AND b.InactiveSw = 0 AND b.PropertyTypeMajorCd_F = (SELECT PropertyTypeMajorCd_F FROM tblProperty WHERE ControlId_F = @ControlId)
				) ON a.NOI_CATEGORY = c.NOICategoryDesc AND a.MD_STATEMENT_ID = @OpStmtName_Prior 
		WHERE a.NOI_CATEGORY IS NULL

-- Gana: Accounting for missing NOI categories - END

-- SSRS DATASET
SELECT * FROM @fnmaOsar ORDER BY LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_ORDER

-- OSAR COMMENTS
--SELECT Comments FROM tblOpStatementHeader WHERE OpStatementHeaderId = @OpStmtName_Latest




