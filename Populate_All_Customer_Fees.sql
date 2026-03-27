-- =============================================
-- POPULATE ALL CUSTOMER FEES INTO PERMANENT TABLE
-- =============================================

SET NOCOUNT ON

DECLARE @VendorID INT = 11854

-- ========== STEP 1: Create permanent table ==========
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_AllCustomerFees')
BEGIN
    CREATE TABLE dbo.tbl_AllCustomerFees (
        ProfileID BIGINT PRIMARY KEY,
        TotalCardFee DECIMAL(18,3),
        TotalMonthlyFee DECIMAL(18,3),
        TotalMonthlyFeePaid DECIMAL(18,3),
        TotalCardFeePaid DECIMAL(18,3),
        CardFeeDue DECIMAL(18,3),
        MonthlyFeeDue DECIMAL(18,3),
        Name NVARCHAR(100),
        CellNo NVARCHAR(100),
        LastUpdated DATETIME DEFAULT GETDATE()
    )

    CREATE INDEX IX_ACF_CellNo ON dbo.tbl_AllCustomerFees(CellNo)
    PRINT 'Table created: tbl_AllCustomerFees'
END

-- ========== STEP 2: Truncate ==========
TRUNCATE TABLE dbo.tbl_AllCustomerFees
PRINT 'Table truncated'

-- ========== STEP 3: Batch Processing ==========
DECLARE @BatchSize INT = 5000
DECLARE @Offset INT = 0
DECLARE @TotalRows INT
DECLARE @StartTime DATETIME = GETDATE()
DECLARE @MaxYears INT = 30

DROP TABLE IF EXISTS #UniqueProfiles

SELECT
    sc.ProfileID_FK AS ProfileID,
    ROW_NUMBER() OVER (ORDER BY sc.ProfileID_FK) AS RN
INTO #UniqueProfiles
FROM (
    SELECT DISTINCT
        sc.ProfileID_FK
    FROM PushData..tbl_SonaCommittee sc WITH(NOLOCK)
    LEFT JOIN PushData..tbl_SoanCommitteSource scs WITH(NOLOCK)
        ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
    LEFT JOIN PushData..tbl_SourceKeyAssociation ska WITH(NOLOCK)
        ON sc.SourceKeyAssociationID_FK = ska.id
    LEFT JOIN PushData..tbl_Branches b WITH(NOLOCK)
        ON ska.BranchID_FK = b.id
    LEFT JOIN PushData..tbl_Venders v WITH(NOLOCK)
        ON b.VendorID_FK = v.id
    WHERE
        LOWER(scs.SourceType) IN ('ereg','card','reg')
        AND sc.TransactionStatus = 1
        AND sc.InsertedDateTime <= CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
        AND v.id = @VendorID
) sc;

CREATE INDEX IX_UQ_RN ON #UniqueProfiles(RN) INCLUDE (ProfileID)

SELECT @TotalRows = COUNT(*) FROM #UniqueProfiles

PRINT 'Total Profiles: ' + CAST(@TotalRows AS VARCHAR) + ' | Started: ' + CONVERT(VARCHAR, @StartTime, 108)

-- SET-BASED POPULATION (same logic as fn_CustomerFeePaid_DueFee)
;WITH YearNumbers AS (
    SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
    UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
    UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24
    UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29
    UNION ALL SELECT 30
),
Profiles AS (
    SELECT
        uq.ProfileID,
        CAST(p.InsertedDateTime AS DATE) AS RegDate,
        p.Name,
        p.CellNo
    FROM #UniqueProfiles uq
    INNER JOIN PushData..tbl_Profile p WITH(NOLOCK)
        ON p.ProfileID = uq.ProfileID
),
ProfileYears AS (
    SELECT
        pr.ProfileID,
        DATEADD(YEAR, yn.n, pr.RegDate) AS FeeDate
    FROM Profiles pr
    INNER JOIN YearNumbers yn
        ON yn.n <= @MaxYears
    WHERE DATEADD(YEAR, yn.n, pr.RegDate) <= GETDATE()
),
CardFeeByProfile AS (
    SELECT
        py.ProfileID,
        SUM(cf.RegFee + cf.FeeValueAtRedemption) AS TotalCardFee
    FROM ProfileYears py
    INNER JOIN PushData..tbl_CardRegistrationFee cf WITH(NOLOCK)
        ON cf.PrintedCardTypeID_FK = 1
        AND py.FeeDate BETWEEN cf.StartDate AND ISNULL(cf.EndDate, GETDATE())
    GROUP BY py.ProfileID
),
MonthlyFeeByProfile AS (
    SELECT
        pr.ProfileID,
        SUM(
            CASE
                WHEN DATEDIFF(MONTH,
                    CASE WHEN pr.RegDate > mf.StartDate THEN pr.RegDate ELSE mf.StartDate END,
                    ISNULL(mf.EndDate, GETDATE())
                ) < 0 THEN 0
                ELSE DATEDIFF(MONTH,
                    CASE WHEN pr.RegDate > mf.StartDate THEN pr.RegDate ELSE mf.StartDate END,
                    ISNULL(mf.EndDate, GETDATE())
                ) * mf.MonthlyFee
            END
        ) AS TotalMonthlyFee
    FROM Profiles pr
    CROSS JOIN PushData..tbl_MonthlyFeeDeduction mf WITH(NOLOCK)
    GROUP BY pr.ProfileID
)
INSERT INTO dbo.tbl_AllCustomerFees
(
    ProfileID,
    TotalCardFee,
    TotalMonthlyFee,
    TotalMonthlyFeePaid,
    TotalCardFeePaid,
    CardFeeDue,
    MonthlyFeeDue,
    Name,
    CellNo
)
SELECT
    pr.ProfileID,
    ISNULL(cbp.TotalCardFee, 0) AS TotalCardFee,
    ISNULL(mbp.TotalMonthlyFee, 0) AS TotalMonthlyFee,
    ISNULL(mfp.MonthlyFeePaid, 0) AS TotalMonthlyFeePaid,
    ISNULL(cfp.SWCardFee, 0) AS TotalCardFeePaid,
    CASE WHEN ISNULL(cfp.SWCardFee, 0) < ISNULL(cbp.TotalCardFee, 0)
         THEN ISNULL(cbp.TotalCardFee, 0) - ISNULL(cfp.SWCardFee, 0) ELSE 0 END AS CardFeeDue,
    CASE WHEN ISNULL(mfp.MonthlyFeePaid, 0) < ISNULL(mbp.TotalMonthlyFee, 0)
         THEN ISNULL(mbp.TotalMonthlyFee, 0) - ISNULL(mfp.MonthlyFeePaid, 0) ELSE 0 END AS MonthlyFeeDue,
    pr.Name,
    pr.CellNo
FROM Profiles pr
LEFT JOIN CardFeeByProfile cbp
    ON cbp.ProfileID = pr.ProfileID
LEFT JOIN MonthlyFeeByProfile mbp
    ON mbp.ProfileID = pr.ProfileID
LEFT JOIN PushData..tbl_MonthlyFee_Customer_New mfp WITH(NOLOCK)
    ON mfp.ProfileID = pr.ProfileID
LEFT JOIN PushData..tbl_CardFee_Customer_New cfp WITH(NOLOCK)
    ON cfp.ProfileID_FK = pr.ProfileID

PRINT 'DONE! Total: ' + CAST(@TotalRows AS VARCHAR) + 
      ' | Duration: ' + CAST(DATEDIFF(MINUTE, @StartTime, GETDATE()) AS VARCHAR) + ' min'

-- VERIFY
SELECT TOP 10 * FROM dbo.tbl_AllCustomerFees

DROP TABLE IF EXISTS #UniqueProfiles

-- Paid
SELECT CellNo,Name,TotalMonthlyFeePaid,TotalCardFeePaid,CardFeeDue,MonthlyFeeDue FROM dbo.tbl_AllCustomerFees
Where TotalMonthlyFeePaid > 0 and TotalCardFeePaid > 0 and CardFeeDue = 0 and MonthlyFeeDue = 0

-- Not Paid
SELECT CellNo,Name,TotalMonthlyFeePaid,TotalCardFeePaid,CardFeeDue,MonthlyFeeDue FROM dbo.tbl_AllCustomerFees
Where TotalMonthlyFeePaid = 0 and TotalCardFeePaid = 0 and CardFeeDue > 0 and MonthlyFeeDue > 0


