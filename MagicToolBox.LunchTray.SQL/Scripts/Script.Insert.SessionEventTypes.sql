--- Turn ON so that ID = Microsoft.Win32.SessionSwitchReason Enum --------------
Set Identity_Insert dbo.SessionEventTypes On
--------------------------------------------------------------------------------

--- Insert The Event Types -----------------------------------------------------
Insert dbo.SessionEventTypes(ID, Name, Billable, Description)
--------------------------------------------------------------------------------
Values
(5, 'SessionLogOn' , 1, 'Microsoft.Win32.SessionSwitchReason; The user session state changes to SessionLogOn when the workstation logs on'   ),
(6, 'SessionLogOff', 1, 'Microsoft.Win32.SessionSwitchReason; The user session state changes to SessionLogOff when the workstation logs off' ),
(7, 'SessionLock'  , 1, 'Microsoft.Win32.SessionSwitchReason; The user session state changes to SessionLock when the workstation is locked'  ),
(8, 'SessionUnlock', 0, 'Microsoft.Win32.SessionSwitchReason; The user session state changes to SessionLock when the workstation is locked'  )
--------------------------------------------------------------------------------

--- Turn OFF Identity Insert ---------------------------------------------------
Set Identity_Insert dbo.SessionEventTypes Off
--------------------------------------------------------------------------------