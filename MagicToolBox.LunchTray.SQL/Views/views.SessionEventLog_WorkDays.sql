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
MM/dd/2018    JHW       • Added this view to make the comparison between billable & break hours
================================================================================ */
Create View views.SessionEventLog_WorkDays
As
--------------------------------------------------------------------------------
Select WorkDate = Convert(Date, e.Start)
      ,DayStart = Min(e.Start)
      ,DayEnded = Max(e.Ended)
      ,DayLength = Format(Max(e.Ended) - Min(e.Start), 'HH:mm')
--------------------------------------------------------------------------------
  From dbo.SessionEventLog e
--------------------------------------------------------------------------------
 Where DateDiff(Day, e.Start, e.Ended) = 0  -- Excludes overnight periods from counting towards breaktime
--------------------------------------------------------------------------------
   And e.Billable = 1
--------------------------------------------------------------------------------
 Group By
       Convert(Date, e.Start)
--------------------------------------------------------------------------------
GO