/*
================================================================================
     Author: John Williams
Create Date: 01/01/2012
Description: This function will format/parse text like C# string.Format()             
    Example: Select FormatString = tool.FormatString('Arg0: {0}\NArg1: {1}\NArg2: {2}', 'Zero', 'One', 'Two')
--------------------------------------------------------------------------------

--- Change Log -----------------------------------------------------------------
Date          Author    Description
-----------   -------   ---------------------------------------------------------
01/01/2012    JHW       • Created This Function
================================================================================ */
Create Function tool.FormatString (
  @Format VarChar(Max)
 ,@Arg0 VarChar(Max)
 ,@Arg1 VarChar(Max) = Null
 ,@Arg2 VarChar(MAX) = NULL
)
--------------------------------------------------------------------------------
Returns VarChar(Max)
As
Begin
---------------------------------------------------------------------------------
  Declare @Return VarChar(Max)
  -------------------------------------------------------------------------------
  --- Parse out any .Net style string format variables
  Set @Return = @Format
  Set @Return = Replace(@Return, '{0}', IsNull(@Arg0, ''))
  Set @Return = Replace(@Return, '{1}', IsNull(@Arg1, ''))
  Set @Return = Replace(@Return, '{2}', IsNull(@Arg2, ''))
  -- Return The Results!!
  Set @Return = tool.FormatText(@Return)
  Return @Return
  -------------------------------------------------------------------------------
End