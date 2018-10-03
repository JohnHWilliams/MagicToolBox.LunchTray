/*
================================================================================
     Author: John Williams
Create Date: 09/12/2018
Description: This proc will give a summary of the week number provided in @Week
    Example: Declare @ThisWeekNo Int = DatePart(wk, DateAdd(wk,  0, GetDate())) -- Get THIS Weeks Data (  0 )
                    ,@LastWeekNo Int = DatePart(wk, DateAdd(wk, -1, GetDate())) -- Get LAST Weeks Data ( -1 )
             Exec rpt.SessionEventLog_SummaryDetail @ThisWeekNo, 2018, 10
             Exec rpt.SessionEventLog_SummaryDetail @LastWeekNo, 2018, 10
--------------------------------------------------------------------------------

--- Change Log -----------------------------------------------------------------
Date          Author    Description
-----------   -------   ---------------------------------------------------------
09/12/2018     JHW      • Added this stored procedure to show an accounting of time
09/14/2018     JHW      • Changed EventSummary query to match the excel timesheet format
                        • Converted columns limiting their width to display best in text output modefrom
                        • Updated EventSummary to use a new view that was added to simplify the EventSummary query
================================================================================ */
Create Proc rpt.SessionEventLog_SummaryDetail
  @Week Int
 ,@Year Int = 2018
 ,@BreakMin Int = 10 -- Set a threshold for minimum break length 
As
--------------------------------------------------------------------------------
Set NoCount On
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
EventSummary: ------------------------------------------------------------------
--------------------------------------------------------------------------------
Select WeekNum = Convert(Char(8), @Week)
      ,DayName = Convert(Char(8), Format(w.WorkDate, 'ddd'))
      ,WorkDate = Convert(Char(12), w.WorkDate)
       -------------------------------------------------------------------------
      ,DayStart = Format(w.DayStart, 'HH:mm')
      ,DayEnded = Format(w.DayEnded, 'HH:mm')
      ,w.DayLength
       -------------------------------------------------------------------------
      ,BreaksTotal = Format(Floor(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) / 3600.00), '00:') -- Hours (Add all seconds up / 3600)
                   + Format(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) % 3600.00 / 60, '00')       -- Minutes (Add all seconds up % 3600 / 60)
      ,BilledTotal = Format(Convert(DateTime, w.DayLength)
                   - Convert(DateTime, Format(Floor(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) / 3600.00), '00:') 
                                     + Format(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) % 3600.00 / 60, '00')
                     ), 'HH:mm')
--------------------------------------------------------------------------------
  From views.SessionEventLog_WorkDays w
--------------------------------------------------------------------------------
--- Join to find break time totals ---------------------------------------------
--------------------------------------------------------------------------------
  Left Join dbo.SessionEventLog nb
    On Convert(Date, nb.Start) = w.WorkDate
   And Convert(Date, nb.Ended) = w.WorkDate
   And Not ( DateDiff(mi, nb.Start, nb.Ended) < @BreakMin )-- Only Count Breaks > 10 Minutes
   And nb.Billable = 0 -- Anything not Billable is considered a break
--------------------------------------------------------------------------------
 Where Year(w.WorkDate) = @Year          -- The year we want data from
   And DatePart(wk, w.WorkDate) = @Week  -- The Week we want data for
--------------------------------------------------------------------------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              --------------------------------------------------------------------------------
 Group By
       w.WorkDate
      ,w.DayStart
      ,w.DayEnded
      ,w.DayLength
--------------------------------------------------------------------------------
 Order By
       w.WorkDate
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
EventDetails: ------------------------------------------------------------------
--------------------------------------------------------------------------------
Select EventID = e.ID
       -------------------------------------------------------------------------
      ,WorkType = Case(e.Billable)
                    ------------------------------------------------------------
                    When 1 Then Convert(nChar(10), 'WorkTime')
                    When 0 Then Convert(nChar(10), 'BreakTime')
                    ------------------------------------------------------------
                  End
       -------------------------------------------------------------------------
      ,ValidBreak = Case
                      ----------------------------------------------------------
                      When e.Billable = 0
                       And Not ( DateDiff(mi, e.Start, e.Ended) < @BreakMin )
                      Then 'YES'
                      ----------------------------------------------------------
                      When e.Billable = 1
                      Then ''
                      ----------------------------------------------------------
                      Else 'NO'
                      ----------------------------------------------------------
                   End
       -------------------------------------------------------------------------
      ,EventStart = Convert(Char(18), Format(e.Start, 'MM/dd/yyyy HH:mm'))
      ,EventEnded = Convert(Char(18), Format(e.Ended, 'MM/dd/yyyy HH:mm'))
      ,EventLength = Convert(Char(3), Format(Format(e.Ended - e.Start, 'dd') - 1, '00:'))
                   + Convert(Char(10), Format(e.Ended - e.Start, 'HH:mm:ss'))
      ,EventMessage = Convert(Char(80), e.Message)
--------------------------------------------------------------------------------
  From dbo.SessionEventLog e
--------------------------------------------------------------------------------
  Left Join dbo.SessionEventTypes t
    On t.ID = e.EventTypeID
--------------------------------------------------------------------------------
 Where DatePart(wk, e.Start) = @Week  -- Get data for the selected week
   --And ( e.Billable = 0 And Not ( DateDiff(mi, e.Start, e.Ended) < @BreakMin )-- Only Count Breaks > 10 Minutes
   --   Or e.Billable = 1
   --)
--------------------------------------------------------------------------------
 Order By
       EventID
--------------------------------------------------------------------------------
GO