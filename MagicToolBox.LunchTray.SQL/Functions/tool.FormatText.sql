/*
================================================================================
Author: John Williams
Create Date: 01/01/2012
Description: This function will format/parse text and replace c# escape characters with proper sql characters
             i.e. \r\n is carriage return+line feed in C# but is Char(13)+Char(10) in T-SQL
--------------------------------------------------------------------------------

--- Change Log -----------------------------------------------------------------
Date          Author    Description
-----------   -------   ---------------------------------------------------------
01/01/2012    JHW       • Created This Proc
================================================================================ */
Create Function tool.FormatText (
  @Format nVarChar(3000)
)
--------------------------------------------------------------------------------
Returns nVarChar(4000)
As
Begin
-------------------------------------------------------------------------------
Declare @Return VarChar(4000)
-- Loop Iteration Variables
Declare @ix Int, @Code Int, @Char Char(4)
-- Set Default Output Value
Set @Return = @Format
-------------------------------------------------------------------------------
-- Parse out any C# style escape characters
If PatIndex('%\TtNnRrQq%', @Return) > 0
Begin
  Set @Return = Replace(@Return, '\T', Char(9))  -- Tab
  Set @Return = Replace(@Return, '\N', Char(10)) -- New Line
  Set @Return = Replace(@Return, '\R', Char(13)) -- Carriage Return
  -- \Q is custom for this routine only. It's not a valid C# escape character 
  Set @Return = Replace(@Return, '\Q', Char(39)) -- Single quote
End
-------------------------------------------------------------------------------
-- Initialize Loop 
-- Look for any instances ascii character codes defined explicitly using \000 format
Set @ix = PatIndex('%\0-90-90-9 %', @Return)
While @ix > 0
Begin
   Set @Char = SubString(@Return, @ix, 4)
   Set @Code = Right(@Char, 3)
   -- Valid Ascii Code ?
   If ( @Code <= 255 )
   Set @Return = Replace(@Return, @Char, Char(@Code))
   -- Iterate Loop Next
   Set @ix = PatIndex('%\0-90-90-9 %', @Return)
End
-------------------------------------------------------------------------------
Return @Return
-------------------------------------------------------------------------------
End
