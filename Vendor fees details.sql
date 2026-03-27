-- =============================================
-- BRANCH WISE FEE PAYMENT REPORT (BATCH PROCESSING)
-- Function call in batches to avoid timeout
-- =============================================

SET NOCOUNT ON
DECLARE @VendorID INT = 11854
DECLARE @BatchSize INT = 10000
DECLARE @Offset INT = 0
DECLARE @TotalRows INT

-- Cleanup
DROP TABLE IF EXISTS #VendorProfiles, #FinalReport

-- ========== STEP 1: Get vendor-specific ProfileIDs ==========
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY p.ProfileID) AS RowNum,
    p.ProfileID,
    b.BranchName,
    p.SahulatMilestonePlan,
    p.SahulatMileStonePercentage
INTO #VendorProfiles
FROM PushData..tbl_SonaCommittee sc WITH(NOLOCK)
INNER JOIN PushData..tbl_Profile p WITH(NOLOCK) ON sc.ProfileID_FK = p.ProfileID
INNER JOIN PushData..tbl_SourceKeyAssociation ska WITH(NOLOCK) ON sc.SourceKeyAssociationID_FK = ska.id
INNER JOIN PushData..tbl_Branches b WITH(NOLOCK) ON ska.BranchID_FK = b.id
INNER JOIN PushData..tbl_Venders v WITH(NOLOCK) ON b.VendorID_FK = v.id
WHERE v.id = @VendorID

SELECT @TotalRows = COUNT(*) FROM #VendorProfiles
PRINT 'Step 1 Done: Total Profiles - ' + CAST(@TotalRows AS VARCHAR)

-- ========== STEP 2: Create empty result table ==========
CREATE TABLE #FinalReport (
    BranchName NVARCHAR(200),
    ProfileID BIGINT,
    SahulatMilestonePlan NVARCHAR(100),
    SahulatMileStonePercentage DECIMAL(18,2),
    Name NVARCHAR(100),
    CellNo NVARCHAR(100),
    TotalCardFee INT,
    TotalMonthlyFee INT,
    TotalCardFeePaid INT,
    TotalMonthlyFeePaid INT,
    CardFeeDue INT,
    MonthlyFeeDue INT,
    FeeStatus VARCHAR(20)
)

-- ========== STEP 3: Process in batches ==========
WHILE @Offset < @TotalRows
BEGIN
    INSERT INTO #FinalReport
    SELECT 
        vp.BranchName,
        vp.ProfileID,
        vp.SahulatMilestonePlan,
        vp.SahulatMileStonePercentage,
        f.Name,
        f.CellNo,
        CAST(f.TotalCardFee AS INT),
        CAST(f.TotalMonthlyFee AS INT),
        CAST(f.TotalCardFeePaid AS INT),
        CAST(f.TotalMonthlyFeePaid AS INT),
        CAST(f.CardFeeDue AS INT),
        CAST(f.MonthlyFeeDue AS INT),
        CASE WHEN f.TotalCardFeePaid > 0 OR f.TotalMonthlyFeePaid > 0 THEN 'Paid' ELSE 'Not Paid' END
    FROM #VendorProfiles vp
    CROSS APPLY dbo.fn_CustomerFeePaid_DueFee(vp.ProfileID) f
    WHERE vp.RowNum > @Offset AND vp.RowNum <= @Offset + @BatchSize
    
    SET @Offset = @Offset + @BatchSize
    PRINT 'Processed: ' + CAST(@Offset AS VARCHAR) + ' / ' + CAST(@TotalRows AS VARCHAR)
END

PRINT 'Step 3 Done: All batches processed'

-- ========== REPORT 1: BRANCH WISE SUMMARY (Paid vs Not Paid) ==========
SELECT 
    BranchName,
    SUM(CASE WHEN FeeStatus = 'Paid' THEN 1 ELSE 0 END) AS [Paid Customer],
    SUM(CASE WHEN FeeStatus = 'Paid' THEN TotalCardFeePaid + TotalMonthlyFeePaid ELSE 0 END) AS [Paid Amount],
    SUM(CASE WHEN FeeStatus = 'Not Paid' THEN 1 ELSE 0 END) AS [Not Paid Customer],
    SUM(CASE WHEN FeeStatus = 'Not Paid' THEN CardFeeDue + MonthlyFeeDue ELSE 0 END) AS [Not Paid Amount]
FROM #FinalReport
GROUP BY BranchName
ORDER BY BranchName

-- ========== OVERALL SUMMARY ==========
SELECT 
    'TOTAL' AS BranchName,
    SUM(CASE WHEN FeeStatus = 'Paid' THEN 1 ELSE 0 END) AS [Paid Customer],
    SUM(CASE WHEN FeeStatus = 'Paid' THEN TotalCardFeePaid + TotalMonthlyFeePaid ELSE 0 END) AS [Paid Amount],
    SUM(CASE WHEN FeeStatus = 'Not Paid' THEN 1 ELSE 0 END) AS [Not Paid Customer],
    SUM(CASE WHEN FeeStatus = 'Not Paid' THEN CardFeeDue + MonthlyFeeDue ELSE 0 END) AS [Not Paid Amount]
FROM #FinalReport

-- ========== REPORT 2: MILESTONE WISE SUMMARY ==========
SELECT 
    ISNULL(SahulatMilestonePlan, 'No Plan') AS MilestonePlan,
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN FeeStatus = 'Paid' THEN 1 ELSE 0 END) AS FeePaidCustomers,
    SUM(CASE WHEN FeeStatus = 'Not Paid' THEN 1 ELSE 0 END) AS FeeNotPaidCustomers,
    SUM(TotalCardFee) AS TotalCardFee,
    SUM(TotalMonthlyFee) AS TotalMonthlyFee,
    SUM(TotalCardFeePaid) AS TotalCardFeePaid,
    SUM(TotalMonthlyFeePaid) AS TotalMonthlyFeePaid,
    SUM(CardFeeDue) AS CardFeeDue,
    SUM(MonthlyFeeDue) AS MonthlyFeeDue
FROM #FinalReport
GROUP BY SahulatMilestonePlan
ORDER BY MilestonePlan

-- ========== REPORT 3: BRANCH + MILESTONE WISE ==========
SELECT 
    BranchName,
    ISNULL(SahulatMilestonePlan, 'No Plan') AS MilestonePlan,
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN FeeStatus = 'Paid' THEN 1 ELSE 0 END) AS FeePaidCustomers,
    SUM(CASE WHEN FeeStatus = 'Not Paid' THEN 1 ELSE 0 END) AS FeeNotPaidCustomers,
    SUM(CardFeeDue) AS CardFeeDue,
    SUM(MonthlyFeeDue) AS MonthlyFeeDue
FROM #FinalReport
GROUP BY BranchName, SahulatMilestonePlan
ORDER BY BranchName, MilestonePlan

-- ========== REPORT 4: CUSTOMERS NOT PAID (Due > 0) ==========
SELECT 
    BranchName,
    SahulatMilestonePlan,
    Name AS CustomerName,
    CellNo,
    TotalCardFee,
    TotalMonthlyFee,
    TotalCardFeePaid,
    TotalMonthlyFeePaid,
    CardFeeDue,
    MonthlyFeeDue
FROM #FinalReport
WHERE CardFeeDue > 0 OR MonthlyFeeDue > 0
ORDER BY BranchName, Name

-- Cleanup
DROP TABLE IF EXISTS #VendorProfiles, #FinalReport