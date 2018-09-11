﻿/*
================================================================================
     Author: John Williams
Create Date: 01/01/2012
Description: This function will format/parse text like C# string.Format()             
    Example: Select FormatString = tool.FormatString1('Arg0: {0}, 'Zero')
--------------------------------------------------------------------------------

--- Change Log -----------------------------------------------------------------
Date          Author    Description
-----------   -------   ---------------------------------------------------------
01/01/2012    JHW       • Created This Function
================================================================================ */
Create Function tool.FormatString1 (
  @Format VarChar(Max)
 ,@Arg0 VarChar(Max)
)
--------------------------------------------------------------------------------
Returns VarChar(Max)
As
Begin
---------------------------------------------------------------------------------
-- Make a call to the normal 3 argument formatString
Return tool.FormatString(@Format, @Arg0, Default, Default)
---------------------------------------------------------------------------------
End
---------------------------------------------------------------------------------