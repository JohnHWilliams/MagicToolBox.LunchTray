/*
================================================================================
     Author: John Williams
Create Date: 09/12/2018
Description: This proc will give a summary of the week number provided in @Week


--- Change Log -----------------------------------------------------------------
Date          Author    Description
-----------   -------   ---------------------------------------------------------
09/12/2018     JHW      • Added this stored procedure to show an accounting of time
--------------------------------------------------------------------------------
09/14/2018     JHW      • Changed EventSummary query to match the excel timesheet format
                        • Converted columns limiting their width to display best in text output modefrom
                        • Updated EventSummary to use a new view that was added to simplify the EventSummary query
--------------------------------------------------------------------------------
04/23/2019     JHW      • Added new [PunchOut] column that estimates by adding 8 hours + total breaks and adding them to DayStart
                          This was done to give you an idea as to when your day will end
                        • Changed all references to nChar from Char
--------------------------------------------------------------------------------


Examples:
--------------------------------------------------------------------------------
Declare @ThisWeekNo Int = DatePart(wk, DateAdd(wk,  0, GetDate())) -- Get THIS Weeks Data (  0 )
   Exec rpt.SessionEventLog_SummaryDetail @ThisWeekNo, 2018, 10
--------------------------------------------------------------------------------
Declare @LastWeekNo Int = DatePart(wk, DateAdd(wk, -1, GetDate())) -- Get LAST Weeks Data ( -1 )
   Exec rpt.SessionEventLog_SummaryDetail @LastWeekNo, 2018, 10
--------------------------------------------------------------------------------


================================================================================ */
Create Proc rpt.SessionEventLog_SummaryDetail
  @Week Int = Null
 ,@Year Int = Null
 ,@BreakMin Int = 5 -- Set a threshold for minimum break length 
As
--------------------------------------------------------------------------------
Set NoCount On
--------------------------------------------------------------------------------
Select @Week = IsNull(@Week, DatePart(Week, GetDate()))
      ,@Year = ISNull(@Year, DatePart(Year, GetDate()))
--------------------------------------------------------------------------------
RaisError('@Week: %i; @Year: %i; @BreakMin', 0, 0, @Week, @Year, @BreakMin)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
EventSummary: ------------------------------------------------------------------
--------------------------------------------------------------------------------
Select WeekNum = Convert(nChar(8), DatePart(wk, w.WorkDate))
      ,DayName = Convert(nChar(8), Format(w.WorkDate, 'ddd'))
      ,WorkDate = Convert(nChar(10), Format(w.WorkDate, 'MM/dd/yyyy'))
      ,DayStart = Convert(nChar(10), Format(w.DayStart, 'hh:mm tt'))
      ,DayEnded = Convert(nChar(10), Format(w.DayEnded, 'hh:mm tt'))
       -------------------------------------------------------------------------
      ,PunchOut = Format(
                     Convert(DateTime,
                         Format(Floor(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) / 3600.00), '00:') -- Hours (Add all seconds up / 3600)
                       + Format(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) % 3600.00 / 60, '00')    -- Minutes (Add all seconds up % 3600 / 60)
                     )
                     + DateAdd(Hour, 8, w.DayStart)
                  ,'hh:mm tt')
       -------------------------------------------------------------------------
      ,DayLength = Convert(nChar(10), w.DayLength)
       -------------------------------------------------------------------------
      ,BreaksCount = Count(nb.ID)
       -------------------------------------------------------------------------
      ,BreakTotals = Convert(nChar(10),
                        Format(Floor(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) / 3600.00), '00:') -- Hours (Add all seconds up / 3600)
                      + Format(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) % 3600.00 / 60, '00')    -- Minutes (Add all seconds up % 3600 / 60)
                     )
                     ----------------------------------------------------------
      ,BreakAverage =Convert(nChar(10), 
                        Format(Floor(Avg(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) / 3600.00), '00:') -- Hours (Add all seconds up / 3600)
                      + Format(Avg(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) % 3600.00 / 60, '00')    -- Minutes (Add all seconds up % 3600 / 60)
                     )
                     ----------------------------------------------------------
      ,BreakStDev = Format(StDev(DateDiff(mi, nb.Start, nb.Ended)), '0.00 Minutes')
                     ----------------------------------------------------------
      ,BilledTotal = Convert(nChar(10), 
                        Format(Convert(DateTime, w.DayLength)
                      - Convert(DateTime, Format(Floor(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) / 3600.00), '00:') 
                                        + Format(Sum(IsNull(DateDiff(ss, nb.Start, nb.Ended), 0)) % 3600.00 / 60, '00')
                        ), 'HH:mm')
                     )
--------------------------------------------------------------------------------
  From views.SessionEventLog_WorkDays w
--------------------------------------------------------------------------------
--- Join to find break time totals  ---------------------------------------------
--------------------------------------------------------------------------------
  Left Join dbo.SessionEventLog nb
    On Convert(Date, nb.Start) = w.WorkDate
   And Convert(Date, nb.Ended) = w.WorkDate
   -- 2 minutes here, 4 minutes there aren't really "breaks"
   And Not ( DateDiff(mi, nb.Start, nb.Ended) < IsNull(@BreakMin, 10) ) -- Only Count Breaks > 10 Minutes
   And nb.Billable = 0 -- Anything not Billable is considered a break
--------------------------------------------------------------------------------
 Where Year(w.WorkDate) = @Year          -- The year we want data from
   And DatePart(wk, w.WorkDate) = @Week  -- The Week we want data for
    Or ( @Year = 2019 And @Week = 1 And w.WorkDate = '12/31/2018' ) -- JHW: Got lazy and ran out of ideas about how to handle the week that ends the year so I just hard coded it until next year (When I will likely do the same thing!)
--------------------------------------------------------------------------------
 Group By
       w.WorkDate
      ,w.DayStart
      ,w.DayEnded
      ,w.DayLength
--------------------------------------------------------------------------------
 Order By
       WeekNum Desc
      ,WorkDate
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
                      When DateDiff(mi, e.Start, e.Ended) >= @BreakMin
                       And e.Billable = 0
                      Then 'YES'
                      ----------------------------------------------------------
                      When e.Billable = 1
                      Then 'N/A'
                      ----------------------------------------------------------
                      Else 'NO'
                      ----------------------------------------------------------
                   End
       -------------------------------------------------------------------------
      ,EventType = t.Name
      ,EventStart = Convert(nChar(18), Format(e.Start, 'MM/dd/yyyy HH:mm'))
      ,EventEnded = Convert(nChar(18), Format(e.Ended, 'MM/dd/yyyy HH:mm'))
      ,EventLength = Convert(nChar(10), Format(e.Ended - e.Start, 'HH:mm:ss'))
      ,EventMessage = Convert(nChar(150), e.Message)
--------------------------------------------------------------------------------
  From dbo.SessionEventLog e
--------------------------------------------------------------------------------
  Left Join dbo.SessionEventTypes t
    On t.ID = e.EventTypeID
--------------------------------------------------------------------------------
 Where Year(e.Start) = @Year          -- The year we want data from
   And DatePart(wk, e.Start) = @Week  -- The Week we want data for
    Or ( @Year = 2019 And @Week = 1 And Convert(Date, e.Start) = '12/31/2018' ) -- JHW: Got lazy and ran out of ideas about how to handle the week that ends the year so I just hard coded it until next year (When I will likely do the same thing!)
--------------------------------------------------------------------------------
 Order By
       EventID
--------------------------------------------------------------------------------
GO