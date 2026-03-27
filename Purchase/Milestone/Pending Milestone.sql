DECLARE @VendorID INT = 350;

;WITH VendorCustomers AS
(
    SELECT DISTINCT
        sc.ProfileID_FK AS ProfileID,
        b.BranchName
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
        scs.SourceType IN ('ereg','card','reg')
        AND sc.TransactionStatus = 1
        AND sc.InsertedDateTime <= CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
        AND v.id = @VendorID
),
MilestoneData AS
(
    SELECT
        s.ProfileID_FK AS ProfileID,
        CAST(s.RegisteredDate AS DATE) AS RegisteredDate,
        CASE WHEN ISNULL(s.SahulatMilestonePlan, 0) = 0 THEN 10000 ELSE s.SahulatMilestonePlan END AS TargetMilestone,
        ISNULL(s.PurchaseAmount, 0) AS PurchaseAmount,
        ISNULL(s.FirstMilestoneBalance, 0) AS FirstMilestoneBalance,
        ISNULL(s.Balance70per, 0) AS Balance70per,
        ISNULL(s.Balance30per, 0) AS Balance30per
    FROM PushData..tbl_SaveGoldMileStoneCustomersummary s WITH(NOLOCK)
    WHERE CAST(s.RegisteredDate AS DATE) <= CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
)
SELECT
    vc.BranchName,
    vc.ProfileID,
    p.Name,
    p.CellNo,
    md.RegisteredDate,
    md.TargetMilestone,
    (md.FirstMilestoneBalance + md.Balance70per + md.Balance30per) AS AchievedAmount,
    (md.TargetMilestone - (md.FirstMilestoneBalance + md.Balance70per + md.Balance30per)) AS RemainingAmount,
    md.PurchaseAmount
FROM VendorCustomers vc
INNER JOIN PushData..tbl_Profile p WITH(NOLOCK)
    ON p.ProfileID = vc.ProfileID
LEFT JOIN MilestoneData md
    ON md.ProfileID = vc.ProfileID
WHERE(md.FirstMilestoneBalance + md.Balance70per + md.Balance30per) < md.TargetMilestone
ORDER BY vc.BranchName, p.Name;