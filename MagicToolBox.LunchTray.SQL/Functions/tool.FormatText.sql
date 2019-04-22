/*
================================================================================
      Author: John Williams
 Create Date: 01/01/2012
 Description: This function will format/parse text and replace c# escape characters with proper sql characters
              i.e. \r\n is carriage return+line feed in C# but is Char(13)+Char(10) in T-SQL
     Example: Select tool.FormatText('E=MC\178') will return E=MC²
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
--------------------------------------------------------------------------------
Declare @Return VarChar(4000) = @Format
--------------------------------------------------------------------------------
--- Loop Iteration Variables ---------------------------------------------------
Declare @ix Int, @Code Int, @Char Char(4)
--------------------------------------------------------------------------------
-- Parse out any C# style escape characters ------------------------------------
If PatIndex('%\[TtNnRrQq%]', @Return) > 0
Begin
   -----------------------------------------------------------------------------
   Select @Return = Replace(@Return, '\T', Char(9))  -- Tab
   Select @Return = Replace(@Return, '\N', Char(10)) -- Line Feed
   Select @Return = Replace(@Return, '\R', Char(13)) -- Carriage Return
   -----------------------------------------------------------------------------
   --- \Q Is NOT a valid C# escape character
   Select @Return = Replace(@Return, '\Q', Char(39)) -- Single quote
   -----------------------------------------------------------------------------
End
-------------------------------------------------------------------------------
-- Initialize Loop ------------------------------------------------------------
-- Look for any instances ascii character codes defined explicitly using \000 format
-------------------------------------------------------------------------------
Select @ix = PatIndex('%\[0-9][0-9][0-9] %', @Return)
-------------------------------------------------------------------------------
 While @ix > 0
 ------------------------------------------------------------------------------
 Begin
    ---------------------------------------------------------------------------
    Select @Char = SubString(@Return, @ix, 4)
    Select @Code = Right(@Char, 3)
    -- Do the replacement(s) for any valid Ascii Code 
    Select @Return = Replace(@Return, @Char, Char(@Code))
     Where @Code <= 255
    -- Iterate Loop Next
    Select @ix = PatIndex('%[\][0-9][0-9][0-9] %', @Return)
    ---------------------------------------------------------------------------
 End
-------------------------------------------------------------------------------
Return @Return
-------------------------------------------------------------------------------
End
GO
--Select Theory = tool.FormatText('E=MC\253')