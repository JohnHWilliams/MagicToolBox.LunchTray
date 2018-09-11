/*
================================================================================
Author: John Williams
Create Date: 08/28/2018
Description: Inserts A Record To dbo.SessionEventLog and returns Scope_Identity()
--------------------------------------------------------------------------------

--- Change Log -----------------------------------------------------------------
Date          Author    Description
-----------   -------   ---------------------------------------------------------
08/28/2018    JHW       • Created This Stored Procedure
09/07/2018    JHW       • Added Billable column to capture default from types
                          but allow override to mark a break as billable (Meeting, etc) 
================================================================================ */
Create Proc dbo.SessionEventLog_Insert
  @EventTypeID Int
 ,@Start DateTime
 ,@Ended DateTime = Null
 ,@Message Text = Null
 ,@NewID Int = Null Out
As
--------------------------------------------------------------------------------
Insert dbo.SessionEventLog(EventTypeID, Billable, Start, Ended, Message)
--------------------------------------------------------------------------------
Select EventTypeID = t.ID
      ,Billable = t.Billable
      ,Start = @Start
      ,Ended = @Ended
      ,Message = @Message
--------------------------------------------------------------------------------
  From dbo.SessionEventTypes t
--------------------------------------------------------------------------------
 Where t.ID = @EventTypeID
--------------------------------------------------------------------------------
Select @NewID = Scope_Identity()
Return @NewID
--------------------------------------------------------------------------------
