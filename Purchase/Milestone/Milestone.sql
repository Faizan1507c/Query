DECLARE @VendorID INT = 11854;

DECLARE @FromDate DATE = '2026-03-01'
DECLARE @ToDate DATE = '2026-03-27' 

;WITH VendorCustomers AS
(
    SELECT DISTINCT tbl_SonaCommittee.ProfileID_FK
   FROM  tbl_SonaCommittee left JOIN
		tbl_Profile on tbl_SonaCommittee.ProfileID_FK = tbl_Profile.ProfileID left JOIN
		tbl_SoanCommitteSource on tbl_SonaCommittee.SoanCommitteSourceID_FK = tbl_SoanCommitteSource.SoanCommitteSourceID left JOIN
		tbl_SourceKeyAssociation on tbl_SonaCommittee.SourceKeyAssociationID_FK = tbl_SourceKeyAssociation.id	left JOIN
		tbl_Branches ON tbl_SourceKeyAssociation.BranchID_FK = tbl_Branches.id left JOIN
		tbl_Venders ON tbl_Branches.VendorID_FK = tbl_Venders.id 
		WHERE (lower(tbl_SoanCommitteSource.SourceType) in ('ereg','card','reg')) and tbl_SonaCommittee.TransactionStatus = 1
		--and (convert(date,tbl_SonaCommittee.InsertedDateTime,102) >= @FromDate and convert(date,tbl_SonaCommittee.InsertedDateTime,102) <= @ToDate)
		AND CONVERT(DATE, tbl_SonaCommittee.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate
        and tbl_Venders.id  = @VendorID
)


SELECT
    s.SahulatMilestonePlan,

    COUNT(DISTINCT s.ProfileID_FK) AS [Unique Customers],
    SUM(s.PurchaseAmount)          AS [Total Purchases],

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

FROM VendorCustomers vc  WITH(NOLOCK)
left JOIN PushData..tbl_SaveGoldMileStoneCustomersummary s 
    ON vc.ProfileID_FK = s.ProfileID_FK
WHERE s.SahulatMilestonePlan > 0
GROUP BY s.SahulatMilestonePlan
ORDER BY s.SahulatMilestonePlan;