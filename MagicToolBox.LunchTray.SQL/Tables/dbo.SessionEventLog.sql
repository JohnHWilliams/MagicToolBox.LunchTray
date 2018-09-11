/*
================================================================================
Create dbo.SessionEventTypes Foreign Key Table 
================================================================================ */
Create Table dbo.SessionEventLog (
  ------------------------------------------------------------------------------
  ID Int Identity Not Null Constraint PK_SessionEventLog_ID Primary Key
 ,EventTypeID Int Not Null Constraint FK_SessionEventLog_EventTypeID Foreign Key References dbo.SessionEventTypes(ID)
 ,Billable Bit Not Null Constraint DF_SessionEventLog_Billable Default(0)
 ,Start DateTime Not Null Constraint DF_SessionEventLog_Start Default(GetDate()) -- Events Will always have start date 
 ,Ended DateTime Null -- Events may not have an end date > start date in which case the EndDate should default to StartDate BUT allow null to provide initial incomplete record inserts with a plan to update and set the EventEnd value when the event ends
 ,Message Text Null
  ------------------------------------------------------------------------------
)
--------------------------------------------------------------------------------