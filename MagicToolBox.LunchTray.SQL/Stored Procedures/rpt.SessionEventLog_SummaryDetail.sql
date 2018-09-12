/*
================================================================================
     Author: John Williams
Create Date: 09/12/2018
Description: This proc will give a summary of the week number provided in @WeekOfYear
    Example: Declare @WeekNo Int = DatePart(wk, DateAdd(wk,  0, GetDate())) -- Get THIS Weeks Data (  0 )
             Exec rpt.SessionEventLog_SummaryDetail @WeekNo
             Declare @LastWeekNo = DatePart(wk, DateAdd(wk, -1, GetDate())) -- Get LAST Weeks Data (  0 )
             Exec rpt.SessionEventLog_SummaryDetail @WeekNo
--------------------------------------------------------------------------------

--- Change Log -----------------------------------------------------------------
Date          Author    Description
-----------   -------   ---------------------------------------------------------
09/12/2018    JHW       • Added this stored procedure
================================================================================ */
Create Proc rpt.SessionEventLog_SummaryDetail
  @WeekOfYear Int
As
--------------------------------------------------------------------------------
--- Event Summary --------------------------------------------------------------
--------------------------------------------------------------------------------
Select WorkDate = Convert(Date, e.Start)
       -------------------------------------------------------------------------
      ,WorkType = Case(e.Billable)
                    ------------------------------------------------------------
                    When 1 Then 'WorkTime'
                    When 0 Then 'BreakTime'
                    ------------------------------------------------------------
                  End
       -------------------------------------------------------------------------
      ,DayStart = ( Select Format(Min(x.Start), 'HH:mm')
                      From dbo.SessionEventLog x
                     Where Convert(Date, x.Start) = Convert(Date, e.Start)
       )
       -------------------------------------------------------------------------
      ,DayEnded = ( Select Format(Max(x.Ended), 'HH:mm')
                      From dbo.SessionEventLog x
                     Where Convert(Date, x.Ended) = Convert(Date, e.Start)
       )
       -------------------------------------------------------------------------
      ,DayLength = Format(
                   (Select Max(x.Ended) From dbo.SessionEventLog x Where Convert(Date, x.Ended) = Convert(Date, e.Ended))
                 - (Select Min(x.Start) From dbo.SessionEventLog x Where Convert(Date, x.Start) = Convert(Date, e.Start))
                 , 'HH:mm')
       -------------------------------------------------------------------------
      ,EventLen = Format(Sum(DateDiff(mi, e.Start, e.Ended)) / 60, '00:') -- Hours (Add All Minutes Up)
                + Format(Sum(DateDiff(mi, e.Start, e.Ended)) % 60, '00' ) -- Minutes (Leftover minutes not included in hours total above)
--------------------------------------------------------------------------------
  From dbo.SessionEventLog e
--------------------------------------------------------------------------------
 Inner Join dbo.SessionEventTypes t
    On t.ID = e.EventTypeID
--------------------------------------------------------------------------------
 Where DateDiff(dd, e.Start, e.Ended) = 0 -- Start & Ended On the Same Day (This excludes overnight hours from the break total Lock @ 5pm - Unlock @ 8am Next Day LOOKS like a 15 hour break)
   And DatePart(wk, e.Start) = @WeekOfYear  -- Get The Week we want data for
   And ( e.Billable = 0 And Not ( DateDiff(mi, e.Start, e.Ended) < 1 )-- Only Count Breaks Longer 15 Minutes
      Or e.Billable = 1
   )
--------------------------------------------------------------------------------
 Group By
       Convert(Date, e.Start)
      ,Convert(Date, e.Ended)
       -------------------------------------------------------------------------
      ,e.Billable
--------------------------------------------------------------------------------
 Order By
       WorkDate
      ,WorkType Desc
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--- Event Details --------------------------------------------------------------
--------------------------------------------------------------------------------
Select EventID = e.ID
       -------------------------------------------------------------------------
      ,WorkType = Case(e.Billable)
                    ------------------------------------------------------------
                    When 1 Then 'WorkTime'
                    When 0 Then 'BreakTime'
                    ------------------------------------------------------------
                  End
       -------------------------------------------------------------------------
      ,EventStart = Format(e.Start, 'MM/dd/yyyy HH:mm')
      ,EventEnded = Format(e.Ended, 'MM/dd/yyyy HH:mm')
      ,EventLength = Format(Format(e.Ended - e.Start, 'dd') - 1, '00:')
                   + Format(e.Ended - e.Start, 'HH:mm:ss')
      ,EventMessage = e.Message
--------------------------------------------------------------------------------
  From dbo.SessionEventLog e
--------------------------------------------------------------------------------
  Left Join dbo.SessionEventTypes t
    On t.ID = e.EventTypeID
--------------------------------------------------------------------------------
 Where DatePart(wk, e.Start) = @WeekOfYear  -- Get data for the selected week
   And ( e.Billable = 0 And Not ( DateDiff(mi, e.Start, e.Ended) < 1 )-- Only Count Breaks Longer 15 Minutes
      Or e.Billable = 1
   )
--------------------------------------------------------------------------------
 Order By
       EventID
--------------------------------------------------------------------------------