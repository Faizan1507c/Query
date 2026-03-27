DECLARE @VendorID INT = 350;

DECLARE @FromDate DATE = DATEADD(YEAR, -1, CAST(GETDATE() AS DATE));
DECLARE @ToDate   DATE = CAST(GETDATE() AS DATE);

;WITH VendorCustomers AS
(
    SELECT DISTINCT
        sc.ProfileID_FK AS ProfileID,
        MAX(b.BranchName) OVER (PARTITION BY sc.ProfileID_FK) AS BranchName
    FROM PushData..tbl_SonaCommittee sc WITH(NOLOCK)
    LEFT JOIN PushData..tbl_SourceKeyAssociation ska WITH(NOLOCK)
        ON sc.SourceKeyAssociationID_FK = ska.id
    LEFT JOIN PushData..tbl_Branches b WITH(NOLOCK)
        ON ska.BranchID_FK = b.id
    LEFT JOIN PushData..tbl_Venders v WITH(NOLOCK)
        ON b.VendorID_FK = v.id
    WHERE v.id = @VendorID
)
SELECT
    vc.BranchName,
    s.ProfileID_FK AS ProfileID,
    s.Name,
    s.CellNo,
    s.RegisteredDate,

    -- GOLD
    s.SahulatMilestonePlan AS Target_Gold,
    ISNULL(s.FirstMilestoneBalance,0) AS Pending_Gold,
    (s.SahulatMilestonePlan - ISNULL(s.FirstMilestoneBalance,0)) AS Achieved_Gold,

    -- SILVER 70%
    ISNULL(s.Milestone70Per,0) AS Target_Silver,
    ISNULL(s.Balance70per,0)   AS Pending_Silver,
    (ISNULL(s.Milestone70Per,0) - ISNULL(s.Balance70per,0)) AS Achieved_Silver,

    -- PLATINUM 30%
    ISNULL(s.Milestone30Per,0) AS Target_Platinum,
    ISNULL(s.Balance30per,0)   AS Pending_Platinum,
    (ISNULL(s.Milestone30Per,0) - ISNULL(s.Balance30per,0)) AS Achieved_Platinum
FROM PushData..tbl_SaveGoldMileStoneCustomersummary s WITH(NOLOCK)
INNER JOIN VendorCustomers vc
    ON vc.ProfileID = s.ProfileID_FK
WHERE
    CAST(s.RegisteredDate AS DATE) >= @FromDate
    AND CAST(s.RegisteredDate AS DATE) <= @ToDate
    AND (ISNULL(s.FirstMilestoneBalance,0) > 0
      OR ISNULL(s.Balance70per,0) > 0
      OR ISNULL(s.Balance30per,0) > 0)
ORDER BY s.RegisteredDate DESC, vc.BranchName, s.Name;