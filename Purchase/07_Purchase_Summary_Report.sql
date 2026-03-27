-- =============================================
-- PURCHASE SUMMARY / AGGREGATED REPORTS
-- Database: PushData + PushDataArchive1 + PushDataArchive2
-- Description: Overall purchase statistics and KPIs with ARYCoin, MG, SaveGold
-- =============================================

DECLARE @FromDate DATE = '2026-03-01'
DECLARE @ToDate DATE = '2026-03-09'

-- MGPP Campaign Data
SELECT f.Profileid_fk, f.TransactionID, f.CreatedOnAMountOf
INTO #MGPP FROM tbl_FreshOneMGPPCampaignCustomers f WITH(NOLOCK) WHERE TransactionStatus = 1

-- Combined data from all databases
;WITH cte AS (
    SELECT tbl_SonaCommittee.SoanCommitteeID AS TRXNID,
        CASE WHEN tbl_Profile.MagneticStripNo IS NULL THEN 'E-Member' ELSE 'Card Member' END AS CardStatus,
        tbl_SonaCommittee.profileid_fk, tbl_Profile.Name, tbl_Profile.InsertedDateTime AS CustomerRegistrationDate,
        tbl_SonaCommittee.Amount, tbl_SonaCommittee.GoldRate, tbl_SonaCommittee.InsertedDateTime,
        tbl_Venders.VenderName, tbl_SonaCommittee.TransactionID, tbl_Branches.BranchName,
        tbl_ValueBackAssociation.ProductName, tbl_SoanCommitteSource.SourceType,
        CASE WHEN tbl_SonaCommittee.TransactionStatus = 1 THEN 'Active Transaction' ELSE 'Reversed Transaction' END AS TransactionStatus,
        tbl_Profile.City,
        tbl_Profile.SahulatMilestonePlan,
        tbl_Profile.SahulatMileStonePercentage
        , Case When ProductName = 'Grocery' Then 3 When ProductName = 'Noon Food' Then 5 Else tbl_ValueBackAssociation.ARYMargin End ARYMargin
    FROM tbl_SonaCommittee WITH(NOLOCK)
    LEFT JOIN tbl_Profile WITH(NOLOCK) ON tbl_SonaCommittee.ProfileID_FK = tbl_Profile.ProfileID
    LEFT JOIN tbl_SoanCommitteSource WITH(NOLOCK) ON tbl_SonaCommittee.SoanCommitteSourceID_FK = tbl_SoanCommitteSource.SoanCommitteSourceID
    LEFT JOIN tbl_SourceKeyAssociation WITH(NOLOCK) ON tbl_SonaCommittee.SourceKeyAssociationID_FK = tbl_SourceKeyAssociation.id
    LEFT JOIN tbl_ValueBackAssociation WITH(NOLOCK) ON tbl_SonaCommittee.ValueBackAssociationID_FK = tbl_ValueBackAssociation.id
    LEFT JOIN tbl_Branches WITH(NOLOCK) ON tbl_SourceKeyAssociation.BranchID_FK = tbl_Branches.id
    LEFT JOIN tbl_Venders WITH(NOLOCK) ON tbl_Branches.VendorID_FK = tbl_Venders.id
    WHERE tbl_SoanCommitteSource.SourceType IN ('pur','vb','mg') AND tbl_SonaCommittee.TransactionStatus = 1
        AND VenderName != 'Easy Paisa' AND ISNULL(tbl_ValueBackAssociation.producttypeCode,'') NOT IN ('1081','1199','1054')
        AND CONVERT(DATE, tbl_SonaCommittee.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate
    UNION
    SELECT tbl_SonaCommittee.SoanCommitteeID AS TRXNID,
        CASE WHEN tbl_Profile.MagneticStripNo IS NULL THEN 'E-Member' ELSE 'Card Member' END AS CardStatus,
        tbl_SonaCommittee.profileid_fk, tbl_Profile.Name, tbl_Profile.InsertedDateTime AS CustomerRegistrationDate,
        tbl_SonaCommittee.Amount, tbl_SonaCommittee.GoldRate, tbl_SonaCommittee.InsertedDateTime,
        tbl_Venders.VenderName, tbl_SonaCommittee.TransactionID, tbl_Branches.BranchName,
        tbl_ValueBackAssociation.ProductName, tbl_SoanCommitteSource.SourceType,
        CASE WHEN tbl_SonaCommittee.TransactionStatus = 1 THEN 'Active Transaction' ELSE 'Reversed Transaction' END AS TransactionStatus,
        tbl_Profile.City,
        0,
        0
        , Case When ProductName = 'Grocery' Then 3 When ProductName = 'Noon Food' Then 5 Else tbl_ValueBackAssociation.ARYMargin End ARYMargin
    FROM PushDataArchive1..tbl_SonaCommittee WITH(NOLOCK)
    LEFT JOIN PushDataArchive1..tbl_Profile WITH(NOLOCK) ON tbl_SonaCommittee.ProfileID_FK = tbl_Profile.ProfileID
    LEFT JOIN PushDataArchive1..tbl_SoanCommitteSource WITH(NOLOCK) ON tbl_SonaCommittee.SoanCommitteSourceID_FK = tbl_SoanCommitteSource.SoanCommitteSourceID
    LEFT JOIN PushDataArchive1..tbl_SourceKeyAssociation WITH(NOLOCK) ON tbl_SonaCommittee.SourceKeyAssociationID_FK = tbl_SourceKeyAssociation.id
    LEFT JOIN PushDataArchive1..tbl_ValueBackAssociation WITH(NOLOCK) ON tbl_SonaCommittee.ValueBackAssociationID_FK = tbl_ValueBackAssociation.id
    LEFT JOIN PushDataArchive1..tbl_Branches WITH(NOLOCK) ON tbl_SourceKeyAssociation.BranchID_FK = tbl_Branches.id
    LEFT JOIN PushDataArchive1..tbl_Venders WITH(NOLOCK) ON tbl_Branches.VendorID_FK = tbl_Venders.id
    WHERE tbl_SoanCommitteSource.SourceType IN ('pur','vb','mg') AND tbl_SonaCommittee.TransactionStatus = 1
        AND VenderName != 'Easy Paisa' AND ISNULL(tbl_ValueBackAssociation.producttypeCode,'') NOT IN ('1081','1199','1054')
        AND CONVERT(DATE, tbl_SonaCommittee.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate
    UNION
    SELECT tbl_SonaCommittee.SoanCommitteeID AS TRXNID,
        CASE WHEN tbl_Profile.MagneticStripNo IS NULL THEN 'E-Member' ELSE 'Card Member' END AS CardStatus,
        tbl_SonaCommittee.profileid_fk, tbl_Profile.Name, tbl_Profile.InsertedDateTime AS CustomerRegistrationDate,
        tbl_SonaCommittee.Amount, tbl_SonaCommittee.GoldRate, tbl_SonaCommittee.InsertedDateTime,
        tbl_Venders.VenderName, tbl_SonaCommittee.TransactionID, tbl_Branches.BranchName,
        tbl_ValueBackAssociation.ProductName, tbl_SoanCommitteSource.SourceType,
        CASE WHEN tbl_SonaCommittee.TransactionStatus = 1 THEN 'Active Transaction' ELSE 'Reversed Transaction' END AS TransactionStatus,
        tbl_Profile.City,
        0,
        0
        , Case When ProductName = 'Grocery' Then 3 When ProductName = 'Noon Food' Then 5 Else tbl_ValueBackAssociation.ARYMargin End ARYMargin
    FROM PushDataArchive2..tbl_SonaCommittee WITH(NOLOCK)
    LEFT JOIN PushDataArchive2..tbl_Profile WITH(NOLOCK) ON tbl_SonaCommittee.ProfileID_FK = tbl_Profile.ProfileID
    LEFT JOIN PushDataArchive2..tbl_SoanCommitteSource WITH(NOLOCK) ON tbl_SonaCommittee.SoanCommitteSourceID_FK = tbl_SoanCommitteSource.SoanCommitteSourceID
    LEFT JOIN PushDataArchive2..tbl_SourceKeyAssociation WITH(NOLOCK) ON tbl_SonaCommittee.SourceKeyAssociationID_FK = tbl_SourceKeyAssociation.id
    LEFT JOIN PushDataArchive2..tbl_ValueBackAssociation WITH(NOLOCK) ON tbl_SonaCommittee.ValueBackAssociationID_FK = tbl_ValueBackAssociation.id
    LEFT JOIN PushDataArchive2..tbl_Branches WITH(NOLOCK) ON tbl_SourceKeyAssociation.BranchID_FK = tbl_Branches.id
    LEFT JOIN PushDataArchive2..tbl_Venders WITH(NOLOCK) ON tbl_Branches.VendorID_FK = tbl_Venders.id
    WHERE tbl_SoanCommitteSource.SourceType IN ('pur','vb','mg') AND tbl_SonaCommittee.TransactionStatus = 1
        AND VenderName != 'Easy Paisa' AND ISNULL(tbl_ValueBackAssociation.producttypeCode,'') NOT IN ('1081','1199','1054')
        AND CONVERT(DATE, tbl_SonaCommittee.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate
)
SELECT * INTO #tbl2 FROM cte

-- ARYCoin, MG, SaveGold calculations
SELECT t.ProfileID_FK, t.TransactionID, SUM(t.Amount) AS ARYCoin INTO #Coin FROM #tbl2 t WHERE LOWER(SourceType) = 'vb' GROUP BY t.ProfileID_FK, t.TransactionID
SELECT t.ProfileID_FK, t.TransactionID, SUM(t.Amount) AS MG, AVG(t.GoldRate) AS GoldRate INTO #MG FROM #tbl2 t WHERE LOWER(SourceType) = 'mg' GROUP BY t.ProfileID_FK, t.TransactionID
SELECT t.ProfileID_FK, t.TransactionID, SUM(t.CreatedOnAMountOf) AS CreatedOnAMountOf INTO #MGSS FROM #MGPP t GROUP BY t.ProfileID_FK, t.TransactionID

-- OVERALL PURCHASE SUMMARY WITH KPIs
SELECT  
    'Purchase Summary' AS ReportType,
    COUNT(*) AS TotalTransactions,
    SUM(pur.Amount) AS TotalPurchaseAmount,
    AVG(pur.Amount) AS AvgTransactionAmount,
    MIN(pur.Amount) AS MinAmount,
    MAX(pur.Amount) AS MaxAmount,
    AVG(pur.GoldRate) AS AvgGoldRate,
    MIN(pur.GoldRate) AS MinGoldRate,
    MAX(pur.GoldRate) AS MaxGoldRate,
    COUNT(DISTINCT pur.ProfileID_FK) AS UniqueCustomers,
    COUNT(DISTINCT pur.VenderName) AS TotalVendors,
    COUNT(DISTINCT pur.BranchName) AS TotalBranches,
    SUM(ISNULL(c.ARYCoin, 0)) AS TotalARYCoin,
    SUM(ISNULL(m.MG, 0)) AS TotalMiliGold,
    SUM(ISNULL(ss.CreatedOnAMountOf, 0)) AS TotalSaveGold,
    SUM(CASE WHEN pur.CardStatus = 'E-Member' THEN 1 ELSE 0 END) AS EMembers,
    SUM(CASE WHEN pur.CardStatus = 'Card Member' THEN 1 ELSE 0 END) AS CardMembers,
    SUM(pur.Amount * NULLIF(pur.ARYMargin/100,0)) as Profit
FROM #tbl2 pur
LEFT JOIN #Coin c ON c.ProfileID_FK = pur.ProfileID_FK AND c.TransactionID = pur.TransactionID
LEFT JOIN #MG m ON m.ProfileID_FK = pur.ProfileID_FK AND m.TransactionID = pur.TransactionID
LEFT JOIN #MGSS ss ON ss.ProfileID_FK = pur.ProfileID_FK AND ss.TransactionID = pur.TransactionID
WHERE LOWER(SourceType) = 'pur'

-- DAILY SUMMARY
SELECT CAST(pur.InsertedDateTime AS DATE) AS PurchaseDate, DATENAME(WEEKDAY, pur.InsertedDateTime) AS DayName,
    COUNT(*) AS TotalTransactions, SUM(pur.Amount) AS TotalAmount, AVG(pur.GoldRate) AS AvgGoldRate,
    COUNT(DISTINCT pur.ProfileID_FK) AS UniqueCustomers,
    SUM(ISNULL(c.ARYCoin, 0)) AS TotalARYCoin, SUM(ISNULL(m.MG, 0)) AS TotalMiliGold,
    SUM(ISNULL(ss.CreatedOnAMountOf, 0)) AS TotalSaveGold,
    SUM(pur.Amount * NULLIF(pur.ARYMargin/100,0)) as Profit
FROM #tbl2 pur
LEFT JOIN #Coin c ON c.ProfileID_FK = pur.ProfileID_FK AND c.TransactionID = pur.TransactionID
LEFT JOIN #MG m ON m.ProfileID_FK = pur.ProfileID_FK AND m.TransactionID = pur.TransactionID
LEFT JOIN #MGSS ss ON ss.ProfileID_FK = pur.ProfileID_FK AND ss.TransactionID = pur.TransactionID
WHERE LOWER(SourceType) = 'pur'
GROUP BY CAST(pur.InsertedDateTime AS DATE), DATENAME(WEEKDAY, pur.InsertedDateTime)
ORDER BY PurchaseDate

-- HOURLY DISTRIBUTION (Peak Hours)
SELECT DATEPART(HOUR, pur.InsertedDateTime) AS HourOfDay,
    COUNT(*) AS TotalTransactions, SUM(pur.Amount) AS TotalAmount, AVG(pur.Amount) AS AvgAmount,
     SUM(pur.Amount * NULLIF(pur.ARYMargin/100,0)) as Profit
FROM #tbl2 pur WHERE LOWER(SourceType) = 'pur'
GROUP BY DATEPART(HOUR, pur.InsertedDateTime) ORDER BY HourOfDay

-- WEEKDAY WISE ANALYSIS
SELECT DATENAME(WEEKDAY, pur.InsertedDateTime) AS DayName, DATEPART(WEEKDAY, pur.InsertedDateTime) AS DayNumber,
    COUNT(*) AS TotalTransactions, SUM(pur.Amount) AS TotalAmount, AVG(pur.Amount) AS AvgAmount,
     SUM(pur.Amount * NULLIF(pur.ARYMargin/100,0)) as Profit
FROM #tbl2 pur WHERE LOWER(SourceType) = 'pur'
GROUP BY DATENAME(WEEKDAY, pur.InsertedDateTime), DATEPART(WEEKDAY, pur.InsertedDateTime) ORDER BY DayNumber

-- GOLD RATE TREND
SELECT CAST(pur.InsertedDateTime AS DATE) AS PurchaseDate,
    MIN(pur.GoldRate) AS MinGoldRate, AVG(pur.GoldRate) AS AvgGoldRate, MAX(pur.GoldRate) AS MaxGoldRate,
    SUM(pur.Amount) AS TotalAmount,
     SUM(pur.Amount * NULLIF(pur.ARYMargin/100,0)) as Profit
FROM #tbl2 pur WHERE LOWER(SourceType) = 'pur'
GROUP BY CAST(pur.InsertedDateTime AS DATE) ORDER BY PurchaseDate

-- CARD STATUS BREAKDOWN
SELECT pur.CardStatus, COUNT(*) AS TotalTransactions, SUM(pur.Amount) AS TotalAmount,
    COUNT(DISTINCT pur.ProfileID_FK) AS UniqueCustomers,
     SUM(pur.Amount * NULLIF(pur.ARYMargin/100,0)) as Profit
FROM #tbl2 pur WHERE LOWER(SourceType) = 'pur'
GROUP BY pur.CardStatus

-- Cleanup
DROP TABLE #tbl2, #MGPP, #MGSS, #MG, #Coin
