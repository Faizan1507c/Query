DECLARE @VendorID INT = 11854;

DECLARE @FromDate DATE = '2026-03-01'
DECLARE @ToDate DATE = '2026-03-26' 

;WITH VendorCustomers AS
(
    SELECT
        sc.ProfileID_FK AS ProfileID,
        v.id AS VendorID,
        v.VenderName
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
        AND CONVERT(DATE, sc.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate
        AND (@VendorID IS NULL OR v.id = @VendorID)
),
VendorCustomersDistinct AS
(
    SELECT
        ProfileID,
        VendorID AS VendorID,
        VenderName AS VenderName
    FROM VendorCustomers
    GROUP BY ProfileID
),

SELECT
    vc.VendorID,
    vc.VenderName,
    s.SahulatMilestonePlan,

    COUNT(DISTINCT vc.ProfileID) AS [Unique Customers],
    SUM(s.PurchaseAmount)        AS [Total Purchases],

    -- Balance (image-style)
    SUM(s.FirstMilestoneBalance)   AS [Balance Gold],
    SUM(s.Balance70per)            AS [Balance Silver],
    SUM(s.Balance30per)            AS [Balance Platinum],
    (SUM(s.FirstMilestoneBalance) + SUM(s.Balance70per) + SUM(s.Balance30per)) AS [Balance Totals],

    SUM(s.mgs3)                    AS [Save Gold],
    (SUM(s.mg_pkr1) + SUM(s.mg_pkr3)) AS [Virtual Created],
    (SUM(s.GoldValue_Physcial_PKR1) + SUM(s.GoldValue_Physcial_PKR3)) AS [Physical Instant Created],
    (SUM(s.PhyscialInstantGold_PKR1) + SUM(s.PhyscialInstantGold_PKR3)) AS [Instant Collected],
    (SUM(s.ARYCOin3) + SUM(s.ARYCOin1)) AS [Coins ARY Coins]

FROM VendorCustomersDistinct vc
WHERE s.SahulatMilestonePlan > 0
GROUP BY
    vc.VendorID,
    vc.VenderName,
    s.SahulatMilestonePlan
ORDER BY
    vc.VenderName,
    s.SahulatMilestonePlan;