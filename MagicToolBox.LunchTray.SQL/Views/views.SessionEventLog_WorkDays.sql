/*
================================================================================
Author: John Williams
Create Date: 09/14/2018
Description: This view summarizes the session events to 1 row per date worked
             When the day started, ended, and the difference between them "DayLength"
--------------------------------------------------------------------------------

--- Change Log -----------------------------------------------------------------
Date          Author    Description
-----------   -------   ---------------------------------------------------------
09/14/2018    JHW       • Added this view to make the comparison between billable & break hours
12/28/2018    JHW       • Added Break Time Aggregate Metrics
01/02/2019    JHW       • Added case statement to use the current time as DayEnded and to calculate DayLength if the WorkDate is the current date
================================================================================ */
Create View views.SessionEventLog_WorkDays
As
--------------------------------------------------------------------------------
Select WorkWeek = DatePart(Week, Max(e.Ended))
       -------------------------------------------------------------------------
      ,WorkDate = Convert(Date, e.Start)
       -------------------------------------------------------------------------
      ,DayStart = Min(e.Start)
      ,DayEnded = Case
                    When Convert(Date, Max(e.Ended)) = Convert(Date, GetDate())
                    Then GetDate()
                    Else Max(e.Ended)
                  End
       -------------------------------------------------------------------------
      ,DayLength = Case
                    --- If it's today then just return the current time as the day has yet to end
                    When Convert(Date, Max(e.Ended)) = Convert(Date, GetDate())
                    Then Format(GetDate() - Min(e.Start), 'HH:mm')
                    --- Get the last timestamp from the day of the record
                    Else Format(Max(e.Ended) - Min(e.Start), 'HH:mm')
                  End
       -------------------------------------------------------------------------
      ,[Breaks += 0:10] = FormatMessage('%s Breaks @ %s total each averaging %s'
                                        ,Format(Count(Distinct bo10.ID), '#,##0')
                                        ,Format(Floor(Sum(Distinct IsNull(DateDiff(ss, bo10.Start, bo10.Ended), 0)) / 3600.00), '0') -- Hours (Add all seconds up / 3600)
                                        +Format(Sum(Distinct IsNull(DateDiff(ss, bo10.Start, bo10.Ended), 0)) % 3600.00 / 60, ':00')    -- Minutes (Add all seconds up % 3600 / 60)
                                        ,Format(Floor(Avg(IsNull(DateDiff(ss, bo10.Start, bo10.Ended), 0)) / 3600.00), '0') -- Hours (Add all seconds up / 3600)
                                        +Format(Avg(IsNull(DateDiff(ss, bo10.Start, bo10.Ended), 0)) % 3600.00 / 60, ':00')    -- Minutes (Add all seconds up % 3600 / 60)
                          )
       -------------------------------------------------------------------------
      ,[Breaks <- 0:10] = FormatMessage('%s Breaks @ %s total each averaging %s'
                                        ,Format(Count(Distinct bu10.ID), '#,##0')
                                        ,Format(Floor(Sum(Distinct IsNull(DateDiff(ss, bu10.Start, bu10.Ended), 0)) / 3600.00), '0') -- Hours (Add all seconds up / 3600)
                                        +Format(Sum(Distinct IsNull(DateDiff(ss, bu10.Start, bu10.Ended), 0)) % 3600.00 / 60, ':00')    -- Minutes (Add all seconds up % 3600 / 60)
                                        ,Format(Floor(Avg(IsNull(DateDiff(ss, bu10.Start, bu10.Ended), 0)) / 3600.00), '0') -- Hours (Add all seconds up / 3600)
                                        +Format(Avg(IsNull(DateDiff(ss, bu10.Start, bu10.Ended), 0)) % 3600.00 / 60, ':00')    -- Minutes (Add all seconds up % 3600 / 60)
                          )
--------------------------------------------------------------------------------
  From dbo.SessionEventLog e
--------------------------------------------------------------------------------
--- Join to aggregate break times 10 or minutes in length ----------------------
--------------------------------------------------------------------------------
  Left Join dbo.SessionEventLog bo10
    On bo10.Billable = 0 -- Anything not Billable is considered a break
   And Convert(Date, bo10.Start) = Convert(Date, e.Start)  -- Only match records of the same day as the from records date
   And Convert(Date, bo10.Ended) = Convert(Date, e.Ended)  -- Only match records of the same day as the from records date
   -- 2 minutes here, 4 minutes there aren't really "breaks"
   And Not ( DateDiff(mi, bo10.Start, bo10.Ended) < 10 ) -- Only count breaks over 10 minutes 
--------------------------------------------------------------------------------
--- Join to aggregate break times below 10 minutes in length -------------------
--------------------------------------------------------------------------------
  Left Join dbo.SessionEventLog bu10
    On bu10.Billable = 0 -- Anything not Billable is considered a break
   And Convert(Date, bu10.Start) = Convert(Date, e.Start)  -- Only match records of the same day as the from records date
   And Convert(Date, bu10.Ended) = Convert(Date, e.Ended)  -- Only match records of the same day as the from records date
   -- 2 minutes here, 4 minutes there aren't really "breaks"
   And ( DateDiff(mi, bu10.Start, bu10.Ended) < 10 ) -- Only count breaks over 10 minutes 
--------------------------------------------------------------------------------
 Where DateDiff(Day, e.Start, e.Ended) = 0  -- Excludes overnight periods from counting towards breaktime
--------------------------------------------------------------------------------
   And e.Billable = 1
--------------------------------------------------------------------------------
 Group By
       Convert(Date, e.Start)
--------------------------------------------------------------------------------