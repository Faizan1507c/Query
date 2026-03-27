-- =============================================
-- DAY END BUSINESS STATUS SUMMARY
-- Database: PushData
-- Description: Deposit Summary (Wallet, Sona Committee, Sahulat Committee, Milli Gold, Gold Booking, Fee)
-- =============================================

USE PushData

DECLARE @FromDate DATE = '2026-03-01'
DECLARE @ToDate DATE = '2026-03-26' 

DROP TABLE IF EXISTS #tbl1, #tbl2, #tbl3, #Purchase, #MGTransactions, #SonaCommittee, #SahulatCommittee, #GoldBooking, #MilliGold, #Wallet, #Fee

-- ========== DEPOSIT SUMMARY ==========

-- SONA COMMITTEE
SELECT 'Sona Committee' [Type], COUNT(DISTINCT Profileid_fk) Customers, SUM(Amount) TotalAmount
INTO #SonaCommittee
FROM tbl_SonaCommittee sc WITH (NOLOCK)
INNER JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
WHERE scs.sourceType IN ('sc')
AND CONVERT(DATE, sc.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate

-- SAHULAT COMMITTEE
SELECT 'Sahulat Committee' [Type], COUNT(DISTINCT sc.Profileid_fk) Customers, SUM(Amount) TotalAmount
INTO #SahulatCommittee
FROM tbl_SonaCommittee sc WITH (NOLOCK)
INNER JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
INNER JOIN tbl_NFCTopUpTransactions nfc WITH (NOLOCK) ON nfc.TransactionId = sc.TransactionId AND nfc.ProfileID_FK = sc.ProfileID_FK
WHERE scs.sourceType IN ('sw')
AND nfc.TransactionType LIKE 'Sahulat Comiti%'
AND CONVERT(DATE, sc.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate

-- GOLD BOOKING
SELECT 'Gold Booking' [Type], COUNT(DISTINCT sc.Profileid_fk) Customers, SUM(Amount) TotalAmount
INTO #GoldBooking
FROM tbl_SonaCommittee sc WITH (NOLOCK)
INNER JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
INNER JOIN tbl_NFCTopUpTransactions nfc WITH (NOLOCK) ON nfc.TransactionId = sc.TransactionId AND nfc.ProfileID_FK = sc.ProfileID_FK
WHERE scs.sourceType IN ('sw')
AND nfc.TransactionType = 'goldbooking'
AND CONVERT(DATE, sc.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate

-- MILLI GOLD
SELECT 'Milli Gold' [Type], COUNT(DISTINCT sc.Profileid_fk) Customers, SUM(Amount) TotalAmount
INTO #MilliGold
FROM tbl_SonaCommittee sc WITH (NOLOCK)
INNER JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
INNER JOIN tbl_NFCTopUpTransactions nfc WITH (NOLOCK) ON nfc.TransactionId = sc.TransactionId AND nfc.ProfileID_FK = sc.ProfileID_FK
WHERE scs.sourceType IN ('sw', 'mg')
AND nfc.TransactionType = 'MilliGold' 
AND sc.Remarks = 'Credit MilliGold Account'
AND CONVERT(DATE, sc.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate

-- WALLET (Exclude Direct Purchase Wallet TopUp)
-- First get all purchases to exclude
SELECT sc.profileid_fk, sc.TransactionID
INTO #Purchase
FROM tbl_SonaCommittee sc WITH (NOLOCK)
LEFT JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
LEFT JOIN tbl_SourceKeyAssociation ska WITH (NOLOCK) ON sc.SourceKeyAssociationID_FK = ska.id
LEFT JOIN tbl_ValueBackAssociation vba WITH (NOLOCK) ON sc.ValueBackAssociationID_FK = vba.id
LEFT JOIN tbl_Branches b WITH (NOLOCK) ON ska.BranchID_FK = b.id
LEFT JOIN tbl_Venders v WITH (NOLOCK) ON b.VendorID_FK = v.id 
WHERE scs.SourceType IN ('pur')
AND v.VenderName != 'Easy Paisa'
AND ISNULL(vba.producttypeCode, '') NOT IN ('1081', '1199', '1054') 
AND sc.TransactionStatus = 1
AND CONVERT(DATE, sc.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate

-- Get MilliGold transactions to exclude
SELECT nfc.ProfileID_FK, nfc.TransactionType, nfc.TransactionID
INTO #MGTransactions
FROM tbl_NFCTopUpTransactions nfc WITH (NOLOCK)
WHERE LOWER(nfc.TransactionType) = LOWER('MilliGold')

-- Get Wallet transactions with MG count
SELECT sc.profileid_fk, sc.Amount, sc.TransactionID,
    ISNULL(mg.Counts, 0) AS Counts
INTO #tbl1
FROM tbl_SonaCommittee sc WITH (NOLOCK)
INNER JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
INNER JOIN tbl_NFCTopUpTransactions nfc WITH (NOLOCK) ON nfc.TransactionId = sc.TransactionId AND nfc.ProfileID_FK = sc.ProfileID_FK
LEFT JOIN (
    SELECT ProfileID_FK, TransactionID, COUNT(*) AS Counts 
    FROM #MGTransactions 
    GROUP BY ProfileID_FK, TransactionID
) mg ON mg.ProfileID_FK = sc.ProfileID_FK AND mg.TransactionID = sc.TransactionID
WHERE scs.sourceType IN ('sw') 
AND sc.TransactionStatus = 1
AND LOWER(nfc.TransactionType) = LOWER('Wallet') 
AND LOWER(scs.SourceName) NOT IN (LOWER('Registration Fee NFC'))
AND CONVERT(DATE, sc.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate

SELECT 'Wallet' [Type], COUNT(DISTINCT profileid_fk) Customers, SUM(Amount) TotalAmount
INTO #Wallet
FROM #tbl1 
WHERE Counts = 0
AND TransactionID NOT IN (SELECT TransactionID FROM #Purchase WHERE TransactionID IS NOT NULL)

-- FEE TRANSACTIONS
SELECT sc.profileid_fk, sc.Amount, sc.TransactionID
INTO #tbl2
FROM tbl_SonaCommittee sc WITH (NOLOCK)
INNER JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
INNER JOIN tbl_NFCTopUpTransactions nfc WITH (NOLOCK) ON nfc.TransactionId = sc.TransactionId AND nfc.ProfileID_FK = sc.ProfileID_FK
WHERE scs.sourceType IN ('sw') 
AND sc.TransactionStatus = 1
AND LOWER(nfc.TransactionType) = LOWER('Wallet') 
AND LOWER(scs.SourceName) IN (LOWER('Registration Fee NFC'))
AND CONVERT(DATE, sc.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate

SELECT sc.profileid_fk, sc.Amount, sc.TransactionID
INTO #tbl3
FROM tbl_SonaCommittee sc WITH (NOLOCK)
LEFT JOIN tbl_SoanCommitteSource scs WITH (NOLOCK) ON sc.SoanCommitteSourceID_FK = scs.SoanCommitteSourceID
LEFT JOIN tbl_SourceKeyAssociation ska WITH (NOLOCK) ON sc.SourceKeyAssociationID_FK = ska.id
LEFT JOIN tbl_ValueBackAssociation vba WITH (NOLOCK) ON sc.ValueBackAssociationID_FK = vba.id
WHERE scs.SourceType IN ('pur')
AND vba.producttypeCode IN ('1081', '1199', '1054') 
AND sc.TransactionStatus = 1
AND CONVERT(DATE, sc.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate

;WITH AllFeeData AS (
    SELECT profileid_fk, Amount, TransactionID FROM #tbl2
    UNION
    SELECT profileid_fk, Amount, TransactionID FROM #tbl3
)
SELECT 'Fee' [Type], COUNT(DISTINCT profileid_fk) Customers, SUM(Amount) TotalAmount 
INTO #Fee
FROM AllFeeData

-- ========== FINAL DEPOSIT SUMMARY OUTPUT ==========
;WITH Deposits AS (
    SELECT * FROM #SonaCommittee
    UNION SELECT * FROM #SahulatCommittee
    UNION SELECT * FROM #GoldBooking
    UNION SELECT * FROM #MilliGold
    UNION SELECT * FROM #Wallet
    UNION SELECT * FROM #Fee
)
SELECT [Type], Customers, TotalAmount, 
    CASE WHEN Customers > 0 THEN TotalAmount / Customers ELSE 0 END AS AvgAmount
FROM Deposits 
ORDER BY [Type] DESC

-- Cleanup
DROP TABLE IF EXISTS #tbl1, #tbl2, #tbl3, #Purchase, #MGTransactions, #SonaCommittee, #SahulatCommittee, #GoldBooking, #MilliGold, #Wallet, #Fee

--RETURN;

-- ========== SALES SUMMARY ==========
-- PURCHASE:
 EXEC sp_GetAllSWPurchaseDataDirectWalletSummary @FromDate, @ToDate

-- ========== CLAIM SUMMARY ==========
-- CLAIM:
 EXEC sp_GetAllSWClaimDataSummary @FromDate, @ToDate