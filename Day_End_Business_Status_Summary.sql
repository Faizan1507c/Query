-- =============================================
-- DAY END BUSINESS STATUS SUMMARY (FAST - Single Scan)
-- Database: PushData + PushDataArchive1 + PushDataArchive2
-- =============================================

USE PushData
SET NOCOUNT ON

DECLARE @FromDate DATE = '2026-02-01'
DECLARE @ToDate DATE = '2026-02-28'

DROP TABLE IF EXISTS #DepositBase, #Purchase, #Regs

-- ===========================
-- SECTION 1: DEPOSIT SUMMARY (Single Scan with CASE)
-- ===========================
SELECT sc.Profileid_fk, sc.Amount, sc.TransactionID,
    scs.SourceType, scs.SourceName, sc.Remarks,
    nfc.TransactionType AS NFCType
INTO #DepositBase
FROM tbl_SonaCommittee sc WITH (NOLOCK)
INNER JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
LEFT JOIN tbl_NFCTopUpTransactions nfc WITH (NOLOCK) ON nfc.TransactionId = sc.TransactionId AND nfc.ProfileID_FK = sc.ProfileID_FK
LEFT JOIN tbl_ValueBackAssociation vba WITH (NOLOCK) ON sc.ValueBackAssociationID_FK = vba.id
WHERE sc.TransactionStatus = 1
AND sc.InsertedDateTime >= @FromDate AND sc.InsertedDateTime < DATEADD(DAY, 1, @ToDate)
AND (
    scs.SourceType = 'sc'
    OR (scs.SourceType = 'sw' AND nfc.TransactionType IS NOT NULL)
    OR (scs.SourceType IN ('sw','mg') AND nfc.TransactionType = 'MilliGold')
    OR (scs.SourceType = 'pur' AND vba.producttypeCode IN ('1081','1199','1054'))
)

SELECT [Type], COUNT(DISTINCT Profileid_fk) AS Customers, SUM(Amount) AS TotalAmount,
    CASE WHEN COUNT(DISTINCT Profileid_fk) > 0 THEN SUM(Amount) / COUNT(DISTINCT Profileid_fk) ELSE 0 END AS AvgAmount
FROM (
    SELECT Profileid_fk, Amount,
        CASE 
            WHEN SourceType = 'sc' THEN 'Sona Committee'
            WHEN SourceType = 'sw' AND NFCType LIKE 'Sahulat Comiti%' THEN 'Sahulat Committee'
            WHEN SourceType = 'sw' AND NFCType = 'goldbooking' THEN 'Gold Booking'
            WHEN SourceType IN ('sw','mg') AND NFCType = 'MilliGold' AND Remarks = 'Credit MilliGold Account' THEN 'Milli Gold'
            WHEN SourceType = 'sw' AND LOWER(NFCType) = 'wallet' AND LOWER(SourceName) = 'registration fee nfc' THEN 'Fee'
            WHEN SourceType = 'sw' AND LOWER(NFCType) = 'wallet' AND LOWER(SourceName) != 'registration fee nfc' THEN 'Wallet'
            WHEN SourceType = 'pur' THEN 'Fee'
        END AS [Type]
    FROM #DepositBase
) d WHERE [Type] IS NOT NULL
GROUP BY [Type]
ORDER BY CASE [Type] WHEN 'Wallet' THEN 1 WHEN 'Sona Committee' THEN 2 WHEN 'Sahulat Committee' THEN 3 WHEN 'Milli Gold' THEN 4 WHEN 'Gold Booking' THEN 5 WHEN 'Fee' THEN 6 END

-- ========================
-- SECTION 2: SALES SUMMARY
-- ========================
SELECT sc.profileid_fk, sc.CellNo, sc.Amount, sc.TransactionID, scs.SourceType,
    CASE WHEN vba.ProductName = 'Grocery' THEN 3 WHEN vba.ProductName = 'Noon Food' THEN 5 ELSE vba.ARYMargin END AS ARYMargin,
    ISNULL(mgpp.CreatedOnAMountOf, 0) AS SaveGold
INTO #Purchase
FROM tbl_SonaCommittee sc WITH (NOLOCK)
LEFT JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
LEFT JOIN tbl_SourceKeyAssociation ska WITH (NOLOCK) ON sc.SourceKeyAssociationID_FK = ska.id
LEFT JOIN tbl_ValueBackAssociation vba WITH (NOLOCK) ON sc.ValueBackAssociationID_FK = vba.id
LEFT JOIN tbl_Branches b WITH (NOLOCK) ON ska.BranchID_FK = b.id
LEFT JOIN tbl_Venders v WITH (NOLOCK) ON b.VendorID_FK = v.id
LEFT JOIN tbl_FreshOneMGPPCampaignCustomers mgpp WITH (NOLOCK) ON mgpp.Profileid_fk = sc.profileid_fk AND mgpp.TransactionID = sc.TransactionID AND mgpp.TransactionStatus = 1
WHERE scs.SourceType IN ('pur', 'vb', 'mg') AND sc.TransactionStatus = 1
AND ISNULL(v.VenderName, '') != 'Easy Paisa' AND ISNULL(vba.producttypeCode, '') NOT IN ('1081', '1199', '1054')
AND sc.InsertedDateTime >= @FromDate AND sc.InsertedDateTime < DATEADD(DAY, 1, @ToDate)

UNION ALL

SELECT sc.profileid_fk, sc.CellNo, sc.Amount, sc.TransactionID, scs.SourceType,
    CASE WHEN vba.ProductName = 'Grocery' THEN 3 WHEN vba.ProductName = 'Noon Food' THEN 5 ELSE vba.ARYMargin END,
    ISNULL(mgpp.CreatedOnAMountOf, 0)
FROM PushDataArchive1..tbl_SonaCommittee sc WITH (NOLOCK)
LEFT JOIN PushDataArchive1..tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
LEFT JOIN PushDataArchive1..tbl_SourceKeyAssociation ska WITH (NOLOCK) ON sc.SourceKeyAssociationID_FK = ska.id
LEFT JOIN PushDataArchive1..tbl_ValueBackAssociation vba WITH (NOLOCK) ON sc.ValueBackAssociationID_FK = vba.id
LEFT JOIN PushDataArchive1..tbl_Branches b WITH (NOLOCK) ON ska.BranchID_FK = b.id
LEFT JOIN PushDataArchive1..tbl_Venders v WITH (NOLOCK) ON b.VendorID_FK = v.id
LEFT JOIN tbl_FreshOneMGPPCampaignCustomers mgpp WITH (NOLOCK) ON mgpp.Profileid_fk = sc.profileid_fk AND mgpp.TransactionID = sc.TransactionID AND mgpp.TransactionStatus = 1
WHERE scs.SourceType IN ('pur', 'vb', 'mg') AND sc.TransactionStatus = 1
AND ISNULL(v.VenderName, '') != 'Easy Paisa' AND ISNULL(vba.producttypeCode, '') NOT IN ('1081', '1199', '1054')
AND sc.InsertedDateTime >= @FromDate AND sc.InsertedDateTime < DATEADD(DAY, 1, @ToDate)

UNION ALL

SELECT sc.profileid_fk, sc.CellNo, sc.Amount, sc.TransactionID, scs.SourceType,
    CASE WHEN vba.ProductName = 'Grocery' THEN 3 WHEN vba.ProductName = 'Noon Food' THEN 5 ELSE vba.ARYMargin END,
    ISNULL(mgpp.CreatedOnAMountOf, 0)
FROM PushDataArchive2..tbl_SonaCommittee sc WITH (NOLOCK)
LEFT JOIN PushDataArchive2..tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
LEFT JOIN PushDataArchive2..tbl_SourceKeyAssociation ska WITH (NOLOCK) ON sc.SourceKeyAssociationID_FK = ska.id
LEFT JOIN PushDataArchive2..tbl_ValueBackAssociation vba WITH (NOLOCK) ON sc.ValueBackAssociationID_FK = vba.id
LEFT JOIN PushDataArchive2..tbl_Branches b WITH (NOLOCK) ON ska.BranchID_FK = b.id
LEFT JOIN PushDataArchive2..tbl_Venders v WITH (NOLOCK) ON b.VendorID_FK = v.id
LEFT JOIN tbl_FreshOneMGPPCampaignCustomers mgpp WITH (NOLOCK) ON mgpp.Profileid_fk = sc.profileid_fk AND mgpp.TransactionID = sc.TransactionID AND mgpp.TransactionStatus = 1
WHERE scs.SourceType IN ('pur', 'vb', 'mg') AND sc.TransactionStatus = 1
AND ISNULL(v.VenderName, '') != 'Easy Paisa' AND ISNULL(vba.producttypeCode, '') NOT IN ('1081', '1199', '1054')
AND sc.InsertedDateTime >= @FromDate AND sc.InsertedDateTime < DATEADD(DAY, 1, @ToDate)

-- Registrations (Direct purchases)
SELECT DISTINCT sc.TransactionID
INTO #Regs
FROM tbl_SonaCommittee sc WITH (NOLOCK)
INNER JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
INNER JOIN tbl_NFCTopUpTransactions nfc WITH (NOLOCK) ON nfc.TransactionId = sc.TransactionId AND nfc.ProfileID_FK = sc.ProfileID_FK
WHERE scs.sourceType = 'sw' AND nfc.TransactionType = 'Wallet' AND scs.SourceName != 'Registration Fee NFC'
AND sc.InsertedDateTime >= @FromDate AND sc.InsertedDateTime < DATEADD(DAY, 1, @ToDate)

SELECT 
    CASE WHEN r.TransactionID IS NULL THEN 'Wallet Purchase' ELSE 'Direct Purchase' END AS [Type],
    COUNT(DISTINCT p.ProfileID_FK) AS Customers, 
    SUM(CASE WHEN LOWER(p.SourceType) = 'pur' THEN p.Amount ELSE 0 END) AS Amount,
    SUM(CASE WHEN LOWER(p.SourceType) = 'vb' THEN p.Amount ELSE 0 END) AS Coins,
    SUM(CASE WHEN LOWER(p.SourceType) = 'pur' THEN p.SaveGold ELSE 0 END) AS SaveGold,
    SUM(CAST(ISNULL(JSON_VALUE(g.JSONString, '$."Instant Gold"'), 0) AS DECIMAL(18,3))) AS InstantGold,
    SUM(CASE WHEN LOWER(p.SourceType) = 'pur' THEN p.Amount * NULLIF(p.ARYMargin / 100, 0) ELSE 0 END) AS Profit
FROM #Purchase p
LEFT JOIN #Regs r ON p.TransactionID = r.TransactionID
LEFT JOIN tbl_PhysicalGoldLogs g WITH (NOLOCK) ON p.CellNo = g.CellNo AND p.TransactionID = g.TransactionID AND g.JSONString != ''
GROUP BY CASE WHEN r.TransactionID IS NULL THEN 'Wallet Purchase' ELSE 'Direct Purchase' END

-- =========================
-- SECTION 3: CLAIM SUMMARY
-- =========================
SELECT ct.ClaimTypeName AS [Type], COUNT(DISTINCT c.ProfileID_FK) AS Customers,
    SUM(CAST(ISNULL(c.ClaimPaidValueAmount, 0) AS DECIMAL)) AS Amount,
    SUM(CAST(ISNULL(c.ClaimPaidValueGold, 0) AS DECIMAL)) AS GoldInMG
FROM tbl_Claim c WITH (NOLOCK)
INNER JOIN tbl_ClaimType ct WITH (NOLOCK) ON ct.ClaimTypeid = c.ClaimTypeID_FK
WHERE c.ClaimPaymentDateTime >= @FromDate AND c.ClaimPaymentDateTime < DATEADD(DAY, 1, @ToDate)
GROUP BY ct.ClaimTypeName ORDER BY ct.ClaimTypeName

-- Cleanup
DROP TABLE IF EXISTS #DepositBase, #Purchase, #Regs
