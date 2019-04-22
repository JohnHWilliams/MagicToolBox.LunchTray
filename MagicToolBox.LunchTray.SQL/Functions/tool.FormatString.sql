/*
================================================================================
     Author: John Williams
Create Date: 01/01/2012
Description: Interpolates a string that uses C# style indexed placeholders i.e. Full_Name = tool.FormatString
    Example: Print tool.FormatString('Arg0: {0}\NArg1: {1}\NArg2: {2}', 'Zero', 'One', 'Two')
             Yields:
               Arg0: Zero
               Arg1: One
               Arg2: Two
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
 ,@Arg2 VarChar(Max) = Null
)
--------------------------------------------------------------------------------
Returns VarChar(Max)
As
Begin
---------------------------------------------------------------------------------
   Declare @Return VarChar(Max)
   -----------------------------------------------------------------------------
   --- Utilizes familiar .Net style placeholders -------------------------------
   Select @Return = @Format
   Select @Return = Replace(@Return, '{0}', IsNull(@Arg0, ''))
   Select @Return = Replace(@Return, '{1}', IsNull(@Arg1, ''))
   Select @Return = Replace(@Return, '{2}', IsNull(@Arg2, ''))
   -----------------------------------------------------------------------------
   -- Return The Results!!
   Return tool.FormatText(@Return)
   -------------------------------------------------------------------------------
End
---------------------------------------------------------------------------------