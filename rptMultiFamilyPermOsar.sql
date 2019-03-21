
USE CRE_ODS
GO

DECLARE @ServicerLoanNumber BIGINT = 600101593; --600101246 900100415 900100632 439119 
DECLARE @debtService FLOAT
DECLARE @startDate DATE = '2017-02-15', @endDate DATE = '2018-06-15';
	

-- HEADER SETUP
--SELECT a.PropertyName, b.ServicerLoanNumber, d.PropertyTypeMajorDesc
--	FROM tblProperty a INNER JOIN tblNote c ON a.ControlId_F = c.ControlId_F INNER JOIN tblNoteExp b ON b.NoteId_F = c.NoteId AND b.ServicerLoanNumber = @ServicerLoanNumber 
--		INNER JOIN tblzCdPropertyTypeMajor d ON a.PropertyTypeMajorCd_F = d.PropertyTypeMajorCd



-- PERIOD DATES TO COMPUTE DEBT SERVICE - SETUP AS A SEPARATE DATASET IN SSRS - BEGIN
DECLARE @eom TABLE (dates DATE)
DECLARE @cntr DATE = EOMONTH(@startDate)

WHILE @cntr <= @endDate
	BEGIN
		PRINT @cntr
		INSERT INTO @eom 
			SELECT EOMONTH(@cntr)
		SET @cntr = DATEADD(m, 1, @cntr)
	END
-- PERIOD DATES TO COMPUTE DEBT SERVICE - SETUP AS A SEPARATE DATASET IN SSRS - END

-- DEBT SERVICE - BEGIN - SETUP AS A SEPARATE DATASET IN SSRS
DECLARE @Liens TABLE (FirstLien BIGINT, SecondLiens BIGINT, LienOrder INT, DSAmount MONEY) 

	-- DS: SETUP A & B NOTES FOR 2 YEARS
INSERT INTO @Liens (FirstLien, SecondLiens, LienOrder)
	SELECT d.ServicerLoanNumber, a.ServicerLoanNumber, 
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
	SELECT a.ServicerLoanNumber, @ServicerLoanNumber, 
		CASE
			WHEN b.LienPositionCd_F = 'F' THEN 1
			ELSE 2	
		END AS OrderKey
		FROM tblNote b
			INNER JOIN tblNoteExp a ON a.NoteId_F = b.NoteId
		WHERE a.ServicerLoanNumber = @ServicerLoanNumber

	-- DS: RETRIEVE DS DATA
;WITH ds_cte AS (
	SELECT a.LOANNBR, SUM(a.[PAYMENT-P&I_AMT]) AS [DS_AMT], b.LienOrder 
		FROM HSB_HIST.STRATEGY_EXTRACT a
			INNER JOIN (SELECT DISTINCT LienOrder, SecondLiens FROM @Liens ) AS b ON a.LOANNBR = b.SecondLiens
		WHERE DATA_EFFDATE IN ( 
				SELECT dates FROM @eom
			)
		GROUP BY a.LOANNBR, LienOrder
	)

	
	-- DS: CONSOLIDATE DS DATASET

UPDATE a SET 
		a.DSAmount = b.DS_AMT
	FROM @Liens a INNER JOIN ds_cte b ON a.SecondLiens = b.LOANNBR 

	SELECT @debtService = SUM(DSAmount) FROM @Liens

	-- DEBT SERVICE - END - THIS WILL BE INCORPORATED INTO REPORT IN ANOTHER DATASET


-- FOUNDATION SETUP
-- SSRS Parameter @OpStmtList captures Op Stmt Header Id of selected Op Stmts. Remove hard-coded Op Stmt Header Id's from below SQL and UNCOMMENT @OpStmtList
DECLARE @OpStmts TABLE (
	LOAN_NUMBER BIGINT, 
	MD_STMT_ID INT, 
	STMT_NAME NVARCHAR (100), 
	STMT_ENDDATE DATE, 
	MD_STMT_ORDER INT
	)

INSERT INTO @OpStmts
	SELECT @ServicerLoanNumber, OpStatementHeaderId, StatementYear, CONVERT(DATE, StatementDate), ROW_NUMBER() OVER (ORDER BY StatementDate DESC)
		FROM tblOpStatementHeader a 
		WHERE OpStatementHeaderId IN ( --@OpStmtList)
58,
59,
60,
61,
108
)
		
		

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
    h.MD_STMT_ORDER, 
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
	INNER JOIN @OpStmts h ON h.MD_STMT_ID = a.OpStatementHeaderId_F
GROUP BY 
	b.OpStatementHeaderId, h.MD_STMT_ORDER, b.StatementYear, f.NOICategoryTypeCd_F, f.NOICategoryDesc, g.OrderKey, f.OrderKey
ORDER BY 
	b.OpStatementHeaderId, g.OrderKey, f.OrderKey


INSERT INTO @fnmaOsar (MD_STATEMENT_ID, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_ORDER, MD_NOI_CAT_TYPE_NAME, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, NORMALIZED) 
	(SELECT OpStatementHeaderId_F, 10, 9000,'Income', StatementYear, 'Effective Gross Income', SUM(ItemAmount), SUM(ItemAmountAfterAdjustment) FROM tblOpStatementDetail 
		INNER JOIN tblOpStatementHeader ON OpStatementHeaderId = OpStatementHeaderId_F
		INNER JOIN tblzCdNOICategory b ON NOICategoryCd = NOICategoryCd_F
		WHERE OpStatementHeaderId_F IN (SELECT MD_STMT_ID FROM @OpStmts)
			AND NOICategoryTypeCd_F = 'I'
		GROUP BY OpStatementHeaderId_F, StatementYear)
	UNION 
	(SELECT OpStatementHeaderId_F, 20, 9000,'Expenses', StatementYear, 'Total Expenses', SUM(ItemAmount), SUM(ItemAmountAfterAdjustment) FROM tblOpStatementDetail 
		INNER JOIN tblOpStatementHeader ON OpStatementHeaderId = OpStatementHeaderId_F
		INNER JOIN tblzCdNOICategory b ON NOICategoryCd = NOICategoryCd_F
		WHERE OpStatementHeaderId_F IN  (SELECT MD_STMT_ID FROM @OpStmts)
			AND NOICategoryTypeCd_F = 'O'
		GROUP BY OpStatementHeaderId_F, StatementYear)
	UNION
	(SELECT OpStatementHeaderId_F, 30, 9000,'Capital Expenditures', StatementYear, 'Total Capital', SUM(ItemAmount), SUM(ItemAmountAfterAdjustment) FROM tblOpStatementDetail 
		INNER JOIN tblOpStatementHeader ON OpStatementHeaderId = OpStatementHeaderId_F
		INNER JOIN tblzCdNOICategory b ON NOICategoryCd = NOICategoryCd_F
		WHERE OpStatementHeaderId_F IN  (SELECT MD_STMT_ID FROM @OpStmts)
			AND NOICategoryTypeCd_F = 'C'
		GROUP BY OpStatementHeaderId_F, StatementYear)
	UNION
	(SELECT OpStatementHeaderId_F, 40, 9960,'Cash Flow Analysis', StatementYear, 'Total Expense & Replacement Reserve', SUM(ItemAmount), SUM(ItemAmountAfterAdjustment) FROM tblOpStatementDetail 
		INNER JOIN tblOpStatementHeader ON OpStatementHeaderId = OpStatementHeaderId_F
		INNER JOIN tblzCdNOICategory b ON NOICategoryCd = NOICategoryCd_F
		WHERE OpStatementHeaderId_F IN  (SELECT MD_STMT_ID FROM @OpStmts)
			AND NOICategoryTypeCd_F IN ('C', 'O')
		GROUP BY OpStatementHeaderId_F, StatementYear)
	

UPDATE a SET a.LOANNUMBER = b.LOAN_NUMBER, a.MD_STATEMENT_ORDER = b.MD_STMT_ORDER	
	FROM @fnmaOsar a INNER JOIN @OpStmts b ON a.MD_STATEMENT_ID = b.MD_STMT_ID 

INSERT INTO @fnmaOsar (MD_STATEMENT_ID, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_ORDER, MD_NOI_CAT_TYPE_NAME, STATEMENT_YEAR, NOI_CATEGORY, REPORTED) 
	SELECT OpStatementHeaderId, 10, 900,'Income', StatementYear, 'Physical Occupancy', (Occupancy) FROM tblOpStatementHeader WHERE OpStatementHeaderId IN (SELECT MD_STMT_ID FROM @OpStmts)


UPDATE a SET a.LOANNUMBER = b.LOAN_NUMBER, a.MD_STATEMENT_ORDER = b.MD_STMT_ORDER	
	FROM @fnmaOsar a INNER JOIN @OpStmts b ON a.MD_STATEMENT_ID = b.MD_STMT_ID 

	

	-- DS: INCORPORATE DS DATA INTO FOUNDATION - BEGIN
INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED) 
	SELECT DISTINCT a.LOANNUMBER, b.MD_STMT_ORDER, 40, 'Cash Flow Analysis', b.MD_STMT_ID, 9980, b.STMT_NAME, 'Debt Service - All Notes ', 0, 0, @debtService FROM @fnmaOsar a INNER JOIN @OpStmts b ON a.LOANNUMBER = b.LOAN_NUMBER
	-- DS: INCORPORATE DS DATA INTO FOUNDATION - END

-- COMPUTE AGGREGATES
	-- NOI & NCF
INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, NORMALIZED) 
	SELECT 
		LOANNUMBER, MD_STATEMENT_ORDER, 40 AS MD_NOI_CAT_TYPE_ORDER, 'Cash Flow Analysis' AS MD_NOI_CAT_TYPE_NAME , MD_STATEMENT_ID, 9950 AS MD_NOI_CAT_ORDER, STATEMENT_YEAR,
		'Net Operating Income' AS NOI_CATEGORY,
		SUM(CASE WHEN NOI_CATEGORY = 'Effective Gross Income' THEN REPORTED END) - SUM(CASE WHEN NOI_CATEGORY = 'Total Expenses' THEN REPORTED END) AS REPORTED, 
		SUM(CASE WHEN NOI_CATEGORY = 'Effective Gross Income' THEN NORMALIZED END) - SUM(CASE WHEN NOI_CATEGORY = 'Total Expenses' THEN NORMALIZED END) AS NORMALIZED
	FROM 
		@fnmaOsar 
	GROUP BY LOANNUMBER, MD_STATEMENT_ORDER, MD_STATEMENT_ID, STATEMENT_YEAR
	UNION
	SELECT 
		LOANNUMBER, MD_STATEMENT_ORDER, 40, 'Cash Flow Analysis' , MD_STATEMENT_ID, 9970, STATEMENT_YEAR,
		'Net Cash Flow',
		SUM(CASE WHEN NOI_CATEGORY = 'Effective Gross Income' THEN REPORTED END) - SUM(CASE WHEN NOI_CATEGORY = 'Total Expense & Replacement Reserve' THEN REPORTED END), 
		SUM(CASE WHEN NOI_CATEGORY = 'Effective Gross Income' THEN NORMALIZED END) - SUM(CASE WHEN NOI_CATEGORY = 'Total Expense & Replacement Reserve' THEN NORMALIZED END)
	FROM 
		@fnmaOsar 
	GROUP BY LOANNUMBER, MD_STATEMENT_ORDER, MD_STATEMENT_ID, STATEMENT_YEAR

 -- DSCR on NOI
;WITH dscr_noi_cte AS (
	SELECT LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, STATEMENT_YEAR, MD_STATEMENT_ID, NOI_CATEGORY, NORMALIZED, 
		LAG(NORMALIZED) OVER (ORDER BY MD_STATEMENT_ID, MD_NOI_CAT_ORDER) AS NOI
		FROM @fnmaOsar WHERE (NOI_CATEGORY LIKE '%debt%service%' OR NOI_CATEGORY LIKE '%income%') 
		AND MD_NOI_CAT_TYPE_ORDER = 40
	)

INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, NORMALIZED) 
	SELECT LOANNUMBER, MD_STATEMENT_ORDER, 40, 'Cash Flow Analysis', MD_STATEMENT_ID, 9990, STATEMENT_YEAR, 'DSCR - NOI', NOI/NULLIF(NORMALIZED, 0) AS [DSCR-NOI] FROM dscr_noi_cte WHERE NOI_CATEGORY LIKE '%debt%'

 -- DSCR on NCF
;WITH dscr_ncf_cte AS (
	SELECT LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, STATEMENT_YEAR, MD_STATEMENT_ID, NOI_CATEGORY, NORMALIZED, 
		LAG(NORMALIZED) OVER (ORDER BY MD_STATEMENT_ID, MD_NOI_CAT_ORDER) AS NCF
		FROM @fnmaOsar WHERE (NOI_CATEGORY LIKE '%debt%service%' OR NOI_CATEGORY LIKE '%Net Cash Flow%') 
		AND MD_NOI_CAT_TYPE_ORDER = 40
	)

INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, NORMALIZED) 
	SELECT LOANNUMBER, MD_STATEMENT_ORDER, 40, 'Cash Flow Analysis', MD_STATEMENT_ID, 9995, STATEMENT_YEAR, 'DSCR - NCF', NCF/NULLIF(NORMALIZED, 0) AS [DSCR-NOI] FROM dscr_ncf_cte WHERE NOI_CATEGORY LIKE '%debt%'


		
-- Gana: Accounting for missing NOI categories - BEGIN

	DECLARE @tmpOpId INT 
	DECLARE op_cursor CURSOR FOR
		SELECT MD_STMT_ID FROM @OpStmts;

	OPEN op_cursor;

	FETCH NEXT FROM op_cursor INTO @tmpOpId

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		INSERT INTO @fnmaOsar (LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_TYPE_NAME, MD_STATEMENT_ID, MD_NOI_CAT_ORDER, STATEMENT_YEAR, NOI_CATEGORY, REPORTED, ADJUSTMENTS, NORMALIZED)
			SELECT @ServicerLoanNumber, d.MD_STMT_ORDER, CASE 
					WHEN c.NOICategoryTypeCd_F = 'I' THEN 10
					WHEN c.NOICategoryTypeCd_F = 'O' THEN 20
					WHEN c.NOICategoryTypeCd_F = 'C' THEN 30
				END, CASE 
					WHEN c.NOICategoryTypeCd_F = 'I' THEN 'Income'
					WHEN c.NOICategoryTypeCd_F = 'O' THEN 'Expenses'
					WHEN c.NOICategoryTypeCd_F = 'C' THEN 'Capital Expenditures'
				END, @tmpOpId, c.OrderKey, d.STMT_NAME, c.NOICategoryDesc, 0, 0, 0
				FROM @fnmaOsar a 
					RIGHT JOIN (tblzCdNOICatPropType b 
						INNER JOIN tblzCdNOICategory c ON b.NOICategoryCd_F = c.NOICategoryCd AND b.InactiveSw = 0 AND b.PropertyTypeMajorCd_F = (SELECT PropertyTypeMajorCd_F FROM tblProperty WHERE ControlId_F = @ControlId)
						) ON a.NOI_CATEGORY = c.NOICategoryDesc AND a.MD_STATEMENT_ID = @tmpOpId
					INNER JOIN @OpStmts d ON d.MD_STMT_ID = @tmpOpId
				WHERE a.NOI_CATEGORY IS NULL AND b.InactiveSw = 0 AND b.TemplateSW = 1

		FETCH NEXT FROM op_cursor INTO @tmpOpId
	END

	CLOSE op_cursor
	DEALLOCATE op_cursor


-- Gana: Accounting for missing NOI categories - END

-- SSRS DATASET
SELECT * FROM @fnmaOsar ORDER BY LOANNUMBER, MD_STATEMENT_ORDER, MD_NOI_CAT_TYPE_ORDER, MD_NOI_CAT_ORDER

-- OSAR COMMENTS
--SELECT TOP 1 Comments FROM tblOpStatementHeader WHERE OpStatementHeaderId IN (@OpStmtList) ORDER BY StatementDate DESC
