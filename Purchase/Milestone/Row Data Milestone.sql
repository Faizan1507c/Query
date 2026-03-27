DECLARE @VendorID INT = 350;

DECLARE @FromDate DATE = '2026-03-01'
DECLARE @ToDate DATE = '2026-03-28' 

;WITH VendorCustomers AS
(
    SELECT DISTINCT tbl_SonaCommittee.ProfileID_FK,o.orderid,tbl_Profile.CellNo
   FROM  tbl_SonaCommittee left JOIN
		tbl_Profile on tbl_SonaCommittee.ProfileID_FK = tbl_Profile.ProfileID left JOIN
		tbl_SoanCommitteSource on tbl_SonaCommittee.SoanCommitteSourceID_FK = tbl_SoanCommitteSource.SoanCommitteSourceID left JOIN
		tbl_SourceKeyAssociation on tbl_SonaCommittee.SourceKeyAssociationID_FK = tbl_SourceKeyAssociation.id	left JOIN
		tbl_Branches ON tbl_SourceKeyAssociation.BranchID_FK = tbl_Branches.id left JOIN
		tbl_Venders ON tbl_Branches.VendorID_FK = tbl_Venders.id 
        Left join tbl_Orders o on tbl_Profile.ProfileId = o.ProfileID_FK
		WHERE (lower(tbl_SoanCommitteSource.SourceType) not in ('ereg','card','reg')) and tbl_SonaCommittee.TransactionStatus = 1
		--and (convert(date,tbl_SonaCommittee.InsertedDateTime,102) >= @FromDate and convert(date,tbl_SonaCommittee.InsertedDateTime,102) <= @ToDate)
		AND CONVERT(DATE, tbl_SonaCommittee.InsertedDateTime, 102) BETWEEN @FromDate AND @ToDate
        and (tbl_SourceKeyAssociation.OutletCode like '%.web%'
		or tbl_SourceKeyAssociation.OutletCode like '%.pk%')
        and tbl_Venders.id  = @VendorID
)


SELECT
    s.SahulatMilestonePlan,

    s.ProfileID_FK AS [Unique Customers],
    vc.orderid,
    vc.CellNo,
    s.PurchaseAmount         AS [Total Purchases],

    -- Balance (image-style)
    s.FirstMilestoneBalance   AS [Balance Gold],
    s.Balance70per            AS [Balance Silver],
    s.Balance30per            AS [Balance Platinum],
    (s.FirstMilestoneBalance + s.Balance70per + s.Balance30per) AS [Balance Totals],

    s.mgs3                    AS [Save Gold],
    (s.mg_pkr1 + s.mg_pkr3) AS [Virtual Created],
    (s.GoldValue_Physcial_PKR1 + s.GoldValue_Physcial_PKR3) AS [Physical Instant Created],
    (s.PhyscialInstantGold_PKR1 + s.PhyscialInstantGold_PKR3) AS [Instant Collected],
    (s.ARYCOin3 + s.ARYCOin1) AS [Coins ARY Coins]

FROM VendorCustomers vc  WITH(NOLOCK)
left JOIN PushData..tbl_SaveGoldMileStoneCustomersummary s 
    ON vc.ProfileID_FK = s.ProfileID_FK
WHERE s.SahulatMilestonePlan > 0
--GROUP BY s.SahulatMilestonePlan
ORDER BY s.SahulatMilestonePlan;