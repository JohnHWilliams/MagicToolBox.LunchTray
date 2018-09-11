/*
Post-Deployment Script Template                     
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.      
 Use SQLCMD syntax to include a file in the post-deployment script.
 Example:      :r .\myfile.sql                        
 Use SQLCMD syntax to reference a variable in the post-deployment script.
 Example:      :setvar TableName MyTable                     
               SELECT * FROM [$(TableName)]
--------------------------------------------------------------------------------------
*/
--- Turn ON so that ID = Microsoft.Win32.SessionSwitchReason Enum --------------
Set Identity_Insert dbo.SessionEventTypes On
--------------------------------------------------------------------------------

--- Insert The Event Types -----------------------------------------------------
Insert dbo.SessionEventTypes(ID, Name, Billable, Description)
--------------------------------------------------------------------------------
Values
(5, 'SessionLogOn' , 0, 'Microsoft.Win32.SessionSwitchReason; The user session state changes to SessionLogOn when the workstation logs on'   ),
(6, 'SessionLogOff', 1, 'Microsoft.Win32.SessionSwitchReason; The user session state changes to SessionLogOff when the workstation logs off' ),
(7, 'SessionLock'  , 1, 'Microsoft.Win32.SessionSwitchReason; The user session state changes to SessionLock when the workstation is locked'  ),
(8, 'SessionUnlock', 0, 'Microsoft.Win32.SessionSwitchReason; The user session state changes to SessionLock when the workstation is locked'  )
--------------------------------------------------------------------------------

--- Turn OFF Identity Insert ---------------------------------------------------
Set Identity_Insert dbo.SessionEventTypes Off
--------------------------------------------------------------------------------
GO
