USE CRE_ODS
GO


DECLARE @fnmaLoans TABLE (MD_ControlId NVARCHAR (20), MD_PropertyId INT, MD_OpStatementHeaderId INT, 
	isAnnual INT, 
	FNMALoanNumber BIGINT, 
	AssetSeqNum NVARCHAR (3), 
	ServicerLoanNumber BIGINT, 
	FiscalYear INT, 
	FiscalQuarter INT,  
	AM_FNAME NVARCHAR (25),
	AM_LNAME NVARCHAR (25),
	AM_PHONE NVARCHAR (25),
	AM_EMAIL NVARCHAR (50),

	B_GRI MONEY,
	B_VCL MONEY,
	B_BAD MONEY,
	B_ICN MONEY,
	B_OIV MONEY,
	B_ILN MONEY,
	B_CIN MONEY,
	B_IVC MONEY,
	B_OMF MONEY,
	B_OGA MONEY,
	B_OPY MONEY,
	B_OUT MONEY,
	B_WST MONEY,
	B_OAD MONEY,
	B_SC4 MONEY,
	B_OGD MONEY,
	B_ORM MONEY,
	B_OIN MONEY,
	B_RET MONEY,
	B_OTH MONEY,
	B_CRS MONEY,
	B_CEO MONEY,

	B_DS_A MONEY,
	B_DS_B MONEY,
	B_DS_C MONEY,
	B_DS_MEZ MONEY,
	B_CASH_RES MONEY,
	B_LAST_SP MONEY,
	B_RR_BB MONEY,
	B_RR_EXP MONEY,
	B_RR_ADDS MONEY,
	B_RR_EB MONEY,
	
	N_GRI MONEY,
	N_VCL MONEY,
	N_BAD MONEY,
	N_ICN MONEY,
	N_OIV MONEY,
	N_ILN MONEY,
	N_CIN MONEY,
	N_IVC MONEY,

	N_OCC_PCT FLOAT, 
	N_OCC_DT DATE,

	N_OMF MONEY,
	N_OGA MONEY,
	N_OPY MONEY,
	N_OUT MONEY,
	N_WST MONEY,
	N_OAD MONEY,
	N_SC4 MONEY,
	N_OGD MONEY,
	N_ORM MONEY,
	N_OIN MONEY,
	N_RET MONEY,
	N_TAX_EXEMPT INT,
	N_OTH MONEY,
	N_CRS MONEY,
	N_CEO MONEY,

	N_DS_A MONEY,
	N_DS_B MONEY,
	N_DS_C MONEY,
	N_DS_MEZ MONEY,
	N_CASH_RES MONEY,
	N_LAST_SP MONEY,
	N_RR_BB MONEY,
	N_RR_EXP MONEY,
	N_RR_ADDS MONEY,
	N_RR_EB MONEY,

	QA_RR_WAIVED INT,
	COMMENTS NTEXT, 

	WV_REASON INT, 
	WV_COMMENTS NTEXT,

	EM_PM_ID NVARCHAR (20),
	EM_ENERGY_USE_INTENSITY INT,
	EM_SCORE INT,
	EM_DATE DATE,

	STMT_START_DT DATE, 
	STMT_END_DT DATE, 
	IS_ANNUALIZED INT

	)

;WITH loanset AS (
	SELECT b.ControlId_F, b.CompletedDate, b.DeliverableEventTypeCD_F, b.ControlMasterWorkflowId_F, b.SkippedSw
		FROM tblProperty a
			INNER JOIN tblControlMasterDealPhaseTemplateItem b ON a.ControlId_F = b.ControlId_F
		WHERE PropertyTypeMajorCd_F = 'FMM' 
			AND b.DeliverableEventTypeCD_F IN ( 'AMSUBMIT','AMFIN')
	)

INSERT INTO @fnmaLoans (MD_ControlId)
SELECT DISTINCT a.ControlId_F FROM loanset a 
	INNER JOIN loanset b ON a.ControlId_F = b.ControlId_F 
		AND a.ControlMasterWorkflowId_F = b.ControlMasterWorkflowId_F 
		AND a.DeliverableEventTypeCD_F = 'AMSUBMIT' AND a.CompletedDate IS  NULL AND b.SkippedSw <> 1
		AND b.DeliverableEventTypeCD_F = 'AMFIN' AND b.CompletedDate IS NOT NULL
		
UPDATE c 
	SET c.MD_OpstatementHeaderId = OpStatementHeaderId, c.MD_PropertyId = b.PropertyId, 
		c.FiscalYear = YEAR(StatementDate),
		c.FiscalQuarter = (
						CASE 
							WHEN MonthsCovered = 12 THEN 0
							ELSE DATEPART(QUARTER, StatementDate)
						END
						),
		c.isAnnual = (
						CASE 
							WHEN MonthsCovered = 12 THEN 0
							ELSE 1
						END
						),
		c.STMT_START_DT = CONVERT(DATE, a.StartDate), 
		c.STMT_END_DT = CONVERT(DATE, a.StatementDate), 
		c.IS_ANNUALIZED = 0,
		c.AssetSeqNum = '001',
		-- Gana: added 2/25/19 - BEGIN
		c.N_OCC_PCT = ISNULL(a.Occupancy * 100, 0), 
		c.N_OCC_DT = CONVERT(DATE, a.StatementDate),
		c.N_TAX_EXEMPT = 0,
		c.N_DS_A = a.AnnualDebtService,
		c.N_RR_EXP = a.CashAndReserves,
		-- Gana: added 2/25/19 - END
		--Gana: changed 3/1/19 to handle NULL comments - BEGIN
		c.COMMENTS = ISNULL(a.Comments, '')
		--Gana: changed 3/1/19 to handle NULL comments - END
	FROM tblOpStatementHeader a 
	--Gana: Changed 3/1/19 to handle different MAX(statement dates) by individual property/op stmt - BEGIN
		INNER JOIN tblProperty b ON PropertyId_F = b.PropertyId 
			AND a.StatementDate = (SELECT MAX(StatementDate) FROM tblOpStatementHeader d INNER JOIN tblProperty e ON d.PropertyId_F = b.PropertyId WHERE d.OpStatementTypeCd_F IN ('ANN2', 'ANN1', 'ANNQ')) 
		INNER JOIN @fnmaLoans c ON c.MD_ControlId = b.ControlId_F
	--Gana: Changed 3/1/19 to handle different MAX(statement dates) by individual property/op stmt - END

UPDATE a
	SET ServicerLoanNumber = c.ServicerLoanNumber
	FROM @fnmaLoans a INNER JOIN tblNote b ON MD_ControlId = b.ControlId_F INNER JOIN tblNoteExp c ON c.NoteId_F = b.NoteId

UPDATE a
	SET a.AM_FNAME = d.FirstName, 
		a.AM_LNAME = d.LastName, 
		a.AM_PHONE = ISNULL(FORMAT(CAST(d.BusinessPhone AS NUMERIC), '##########'),'2063897750'), 
		a.AM_EMAIL = d.EmailAddress 
	FROM @fnmaLoans a INNER JOIN tblControlMaster b ON a.MD_ControlId = b.ControlId
	INNER JOIN tblSecUser c ON b.AssetManager_UserId_F = c.UserId
	INNER JOIN tblContact d ON c.ContactId_F = d.ContactId

DECLARE @OpDetail TABLE (OpStatementHeaderId_F INT, NOICategoryCd_F NVARCHAR (10), Borrower MONEY, Normalized MONEY) 

INSERT INTO @OpDetail
	SELECT OpStatementHeaderId_F, NOICategoryCd_F, SUM(ItemAmount) AS Borrower, SUM(ItemAmountAfterAdjustment) AS Normalized FROM tblOpStatementDetail a INNER JOIN @fnmaLoans ON OpStatementHeaderId_F = MD_OpStatementHeaderId GROUP BY OpStatementHeaderId_F, NOICategoryCd_F

UPDATE @fnmaLoans SET 
	B_GRI = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'GRI'), 0),
	B_VCL = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'VCL'), 0),
	B_BAD = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'BAD'), 0),
	B_ICN = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'ICN'), 0),
	B_OIV = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OIV'), 0),
	B_ILN = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'ILN'), 0),
	B_CIN = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'CIN'), 0),
	B_IVC = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'IVC'), 0),
	B_OMF = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OMF'), 0),
	B_OGA = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OGA'), 0),
	B_OPY = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OPY'), 0),
	B_OUT = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OUT'), 0),
	B_WST = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'WST'), 0),
	B_OAD = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OAD'), 0),
	B_SC4 = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'SC4'), 0),
	B_OGD = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OGD'), 0),
	B_ORM = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'ORM'), 0),
	B_OIN = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OIN'), 0),
	B_RET = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'RET'), 0),
	B_OTH = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OTH'), 0),
	B_CRS = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'CRS'), 0),
	B_CEO = ISNULL((SELECT IIF(Borrower < 0, -1 * Borrower, Borrower) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'CEO'), 0),
	N_GRI = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'GRI'), 0),
	N_VCL = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'VCL'), 0),
	N_BAD = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'BAD'), 0),
	N_ICN = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'ICN'), 0),
	N_OIV = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OIV'), 0),
	N_ILN = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'ILN'), 0),
	N_CIN = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'CIN'), 0),
	N_IVC = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'IVC'), 0),
	N_OMF = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OMF'), 0),
	N_OGA = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OGA'), 0),
	N_OPY = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OPY'), 0),
	N_OUT = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OUT'), 0),
	N_WST = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'WST'), 0),
	N_OAD = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OAD'), 0),
	N_SC4 = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'SC4'), 0),
	N_OGD = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OGD'), 0),
	N_ORM = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'ORM'), 0),
	N_OIN = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OIN'), 0),
	N_RET = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'RET'), 0),
	N_OTH = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'OTH'), 0),
	N_CRS = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'CRS'), 0),
	N_CEO = ISNULL((SELECT IIF(Normalized < 0, -1 * Normalized, Normalized) FROM @OpDetail WHERE OpStatementHeaderId_F = MD_OpStatementHeaderId AND NOICategoryCd_F = 'CEO'), 0), 
	N_CASH_RES = 0,
	N_LAST_SP = 0,
	B_CASH_RES = 0,
	B_LAST_SP = 0, 
	--Gana: Added 3/1/19 to handle defaults - BEGIN
	--Gana: On 3/4/19, removed defaults to WV_REASON, EM_ENERGY_USE_INTENSITY, EM_SCORE, & EM_DATE - BEGIN
	QA_RR_WAIVED = 1,
	WV_COMMENTS = '',
	EM_PM_ID = ''
	--Gana: On 3/4/19, removed defaults to WV_REASON, EM_ENERGY_USE_INTENSITY, EM_SCORE, & EM_DATE - END
	--Gana: Added 3/1/19 to handle defaults - END

-- REPLACEMENT RESERVE ACTIVITY PROCESSING - BEGIN

DECLARE @rr_txn TABLE (ROW_NUM INT, LOAN_NUMBER BIGINT, ESCROW_SEQ INT, BEG_BAL MONEY, DDA_AC_NUM BIGINT, TXN_CODE NVARCHAR (4), TXN_DESC NVARCHAR (25), TXN_DATE DATE, PAID_DATE DATE)

;WITH rr_cte AS(
	SELECT
		ROW_NUMBER() OVER (PARTITION BY [LOAN NUMBER] ORDER BY CONVERT(DATE, [TRANSACTION DATE])) AS ROW_NUM,
		*
		FROM (
		SELECT DISTINCT 
			[LOAN NUMBER],
			[ESCROW #],
			[BEGINNING BALANCE],
			[D.D.A. #],
			[TRANSACTION CODE],
			[FULL DESC],
			CONVERT(DATE, [TRANSACTION DATE]) AS [TRANSACTION DATE],
			CONVERT(DATE, [PAID FOR DATE]) AS [PAID FOR DATE]

			FROM HSB_HIST.REPLACEMENT_RESERVES WHERE [LOAN NUMBER] IN (SELECT DISTINCT ServicerLoanNumber FROM @fnmaLoans) AND YEAR(CONVERT(DATE, [DATE LAST POSTED])) = YEAR(GETDATE()) AND (YEAR(CONVERT(DATE, [TRANSACTION DATE])) IN (YEAR(GETDATE()) - 1 , YEAR(GETDATE()))) 
			AND [D.D.A. #] IN (
				SELECT DISTINCT [D.D.A. #] FROM HSB_HIST.REPLACEMENT_RESERVES WHERE [LOAN NUMBER] IN (SELECT DISTINCT ServicerLoanNumber FROM @fnmaLoans) AND YEAR(CONVERT(DATE, [PAID FOR DATE])) IN (YEAR(GETDATE()), YEAR(GETDATE()) - 1)
				)
			) as A 
	)
INSERT INTO @rr_txn
	SELECT * FROM rr_cte

DECLARE @rr_data TABLE (LOAN_NUMBER BIGINT, BEG_BAL MONEY, END_BAL MONEY, DISBURSALS MONEY, TXN_YEAR INT)

INSERT INTO @rr_data (TXN_YEAR, LOAN_NUMBER)
	SELECT DISTINCT YEAR(TXN_DATE), LOAN_NUMBER FROM @rr_txn

	-- Gana: Changed 3/1/19 to fix JOIN issue leading to inaccurate disbursals computed - BEGIN
;WITH rr_exp_cte AS ( 											
	SELECT SUM(DIFF) AS DISBURSALS, LOAN_NUMBER, YEAR(TXN_DATE) AS TXN_YEAR FROM (
		SELECT ISNULL((b.[BEG_BAL] - a.[BEG_BAL]), 0) AS [DIFF], a.* FROM @rr_txn a INNER JOIN @rr_txn b ON a.ROW_NUM + 1 = b.ROW_NUM AND a.LOAN_NUMBER = b.LOAN_NUMBER --AND a.[DDA_AC_NUM] = b.[DDA_AC_NUM]  
		) AS B
	WHERE B.TXN_DESC LIKE '%DIS%' AND YEAR(B.TXN_DATE) IN (YEAR(GETDATE()) - 1) --AND LOAN_NUMBER = LOAN_NUMBER --AND TXN_YEAR = YEAR(TXN_DATE) 
	GROUP BY LOAN_NUMBER, YEAR(B.TXN_DATE)
	)


UPDATE a SET
	a.DISBURSALS = b.DISBURSALS
	FROM @rr_data a INNER JOIN rr_exp_cte b ON a.LOAN_NUMBER = b.LOAN_NUMBER AND b.TXN_YEAR = a.TXN_YEAR
	
	-- Gana: Changed 3/1/19 to fix JOIN issue leading to inaccurate disbursals computed - END
																	

DECLARE @rr_dates TABLE (DATES DATE, TXN_YEAR INT, LOAN_NUMBER BIGINT)

INSERT INTO @rr_dates
	SELECT MIN(TXN_DATE) AS DATES, YEAR(TXN_DATE) AS TXN_YEAR, LOAN_NUMBER FROM @rr_txn GROUP BY LOAN_NUMBER, YEAR(TXN_DATE)

	--Gana: Changed 3/1/19 to remove "unwanted" update to DISBURSALS - BEGIN
UPDATE a SET 
	a.BEG_BAL = b.BEG_BAL
	FROM @rr_data a INNER JOIN @rr_txn b ON a.LOAN_NUMBER = b.LOAN_NUMBER 
		INNER JOIN @rr_dates c ON a.LOAN_NUMBER = c.LOAN_NUMBER
	WHERE b.TXN_DATE = c.DATES AND a.TXN_YEAR = c.TXN_YEAR
	--Gana: Changed 3/1/19 to remove "unwanted" update to DISBURSALS - END

UPDATE a SET 
	a.END_BAL = ISNULL(b.BEG_BAL, 0)
	FROM @rr_data a INNER JOIN @rr_txn b ON a.LOAN_NUMBER = b.LOAN_NUMBER 
		INNER JOIN @rr_dates c ON a.LOAN_NUMBER = c.LOAN_NUMBER
	WHERE b.TXN_DATE = c.DATES AND a.TXN_YEAR = (c.TXN_YEAR - 1)

UPDATE a SET
		a.B_RR_BB = 0
		, a.B_RR_EXP = 0
		, a.B_RR_EB = 0
		, a.B_RR_ADDS = 0
		, a.N_RR_BB = ISNULL(b.BEG_BAL, 0)
		-- Gana: Changed to accommodate a forced R/R Expense value from Op Stmt on Backshop UI - BEGIN
		-- Gana: changed 3/1/19 to represent disbursals as POSITIVE - BEGIN
		, a.N_RR_EXP = (CASE 
							WHEN N_RR_EXP IS NULL THEN ABS(ISNULL(b.DISBURSALS, 0))
							ELSE ABS(ISNULL(N_RR_EXP, 0))
						END
		)
		-- Gana: Changed to accommodate a forced R/R Expense value from Op Stmt on Backshop UI - END
		, a.N_RR_EB = ISNULL(b.END_BAL, 0)
		, a.N_RR_ADDS = (ISNULL(b.END_BAL, 0) - ISNULL(b.BEG_BAL, 0) - ISNULL(b.DISBURSALS, 0))
	--Gana: Changed 3/1/19 to LEFT JOIN to handle loans that do NOT have R/R collected - BEGIN
	FROM @fnmaLoans a LEFT JOIN @rr_data b ON a.ServicerLoanNumber = b.LOAN_NUMBER AND b.TXN_YEAR = (YEAR(GETDATE()) - 1)
	--Gana: Changed 3/1/19 to LEFT JOIN to handle loans that do NOT have R/R collected - END

-- REPLACEMENT RESERVE ACTIVITY PROCESSING - END 

-- DEBT SERVICE AMOUNTS - BEGIN


DECLARE @eom TABLE (dates DATE)
DECLARE @cntr INT = 1
DECLARE @Liens TABLE (FirstLien BIGINT, SecondLiens BIGINT, LienOrder INT, DSYear INT, DSAmount MONEY) 

WHILE @cntr <= 12
	BEGIN
		INSERT INTO @eom 
			SELECT EOMONTH(DATEFROMPARTS(YEAR(GETDATE())-1, @cntr, @cntr)) -- THIS PART OF SQL MUST BE CHANGED TO INCLUDE "YEAR(GETDATE())-2" WHEN ALL DEBT SERVICE AMOUNTS ARE IN ODS
		SET @cntr = @cntr + 1
	END

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
		WHERE d.ServicerLoanNumber IN (SELECT DISTINCT ServicerLoanNumber FROM @fnmaLoans)
	UNION 
	SELECT a.ServicerLoanNumber, a.ServicerLoanNumber,
		CASE
			WHEN b.LienPositionCd_F = 'F' THEN 1
			ELSE 2	
		END AS OrderKey 
		FROM tblNote b
			INNER JOIN tblNoteExp a ON a.NoteId_F = b.NoteId
		WHERE a.ServicerLoanNumber IN (SELECT DISTINCT ServicerLoanNumber FROM @fnmaLoans)


;WITH ds_cte AS (
	SELECT YEAR(DATA_EFFDATE) AS [YEAR], a.LOANNBR, SUM(a.[PAYMENT-P&I_AMT]) AS [DS_AMOUNT], b.FirstLien, b.LienOrder 
		FROM HSB_HIST.STRATEGY_EXTRACT a
			INNER JOIN @Liens b ON a.LOANNBR = b.SecondLiens
		WHERE DATA_EFFDATE IN ( 
				SELECT dates FROM @eom
			)
		GROUP BY a.LOANNBR, b.FirstLien, LienOrder, YEAR(DATA_EFFDATE) 
	)

UPDATE a SET
		a.DSAmount = b.DS_AMOUNT,
		a.DSYear = b.YEAR
	FROM @Liens a INNER JOIN ds_cte b ON a.SecondLiens = b.LOANNBR

UPDATE @fnmaLoans SET
		--Gana: Changed to accommodate corrections forced via Backshop Op Stmt UI - BEGIN
		N_DS_A = (CASE
					WHEN N_DS_A IS NULL THEN ISNULL((SELECT DSAmount FROM @Liens WHERE ServicerLoanNumber = FirstLien AND LienOrder = 1), 0)
					ELSE N_DS_A
				END
					)
		--Gana: Changed to accommodate corrections forced via Backshop Op Stmt UI - END
		, N_DS_B = ISNULL((SELECT DSAmount FROM @Liens WHERE ServicerLoanNumber = FirstLien AND LienOrder = 2), 0)
		, N_DS_C = 0
		, N_DS_MEZ = 0
		, B_DS_A = 0
		, B_DS_B = 0
		, B_DS_C = 0
		, B_DS_MEZ = 0

-- DEBT SERVICE AMOUNTS - END

-- FNMA Loan Number update using DEBT SERVICE - BEGIN

	--Gana: Changed 3/1/19 to handle missing FNMA MAMP Extract data - BEGIN
UPDATE a SET
		a.FNMALoanNumber = ISNULL(b.[FM Loan #/CUSIP#/Deal ID], 0)
	FROM @fnmaLoans a LEFT JOIN HSB_HIST.DEBT_SERVICE b ON a.ServicerLoanNumber = b.[Lender/Servicer Loan #]
	--Gana: Changed 3/1/19 to handle missing FNMA MAMP Extract data - END

-- FNMA Loan Number update using DEBT SERVICE - END

SELECT * FROM @fnmaLoans