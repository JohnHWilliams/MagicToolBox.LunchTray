/*
================================================================================
Create dbo.SessionEventTypes Foreign Key Table 
================================================================================ */
Create Table dbo.SessionEventTypes (
  ------------------------------------------------------------------------------
  ID Int Identity Not Null Constraint pk_SessionEventTypes_ID Primary Key
 ,Name nVarChar(25) Not Null Constraint uq_SessionEventTypes_Name Unique
 ,Description nVarChar(255) Null
 ,Billable Bit Not Null Constraint DF_SessionEventTypes_Billable Default(0)
  ------------------------------------------------------------------------------
)
--------------------------------------------------------------------------------