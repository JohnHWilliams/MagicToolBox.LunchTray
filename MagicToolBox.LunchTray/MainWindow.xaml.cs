using Microsoft.Win32;

using System;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Threading;

// Custom Alias Usings
using cfg = System.Configuration.ConfigurationManager;

namespace MagicToolBox.LunchTray {
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window {

        #region " Types "
            private class SessionEvent {
                public int ID { set; get; }
                public SessionSwitchReason EventTypeID { set; get; }
                public DateTime Start { set; get; }
                public DateTime Ended { set; get; }
                public string Message { set; get; }
            }
            public class TextBoxTraceListener : TraceListener {
                private readonly TextBoxBase tbTraceOutput;
                public TextBoxTraceListener(TextBoxBase TB) {
                    this.Name = "Trace";
                    this.tbTraceOutput = TB;
                }
                public override void Write(string message) {
                    this.tbTraceOutput.AppendText(message);
                }
                public override void WriteLine(string message) {
                    this.Write(message + Environment.NewLine);
                }
            }
        #endregion

        #region " Proerties "
            internal DateTime AppStart { get; private set; }
            internal DateTime? PunchIn { get; private set; }
            internal DateTime? SysLocked { get; private set; }
            internal DateTime? SysUnLock { get; private set; }
            internal DateTime? SysLogOn { get; private set; }
            internal DateTime? SysLogOff { get; private set; }
            private string _TraceFileName;
            private string TraceFileName {
                get {
                    if (string.IsNullOrEmpty(this._TraceFileName)) {
                        // TraceFileName Is Unique Per Day
                        this._TraceFileName = string.Format(cfg.AppSettings["TraceFileNameFormat"], DateTime.Now);
                    }
                    return this._TraceFileName;
                }
            }            
            private SessionEvent ActiveEvent { set; get; }
            private TimeSpan tsWorking { set; get; } = new TimeSpan();
            private TimeSpan tsOnBreak { set; get; } = new TimeSpan();
            DispatcherTimer tmrWorking = new DispatcherTimer() { Interval = new TimeSpan(0, 0, 1) };
            DispatcherTimer tmrOnBreak = new DispatcherTimer() { Interval = new TimeSpan(0, 0, 1) };
        #endregion

        #region " Constructors "
            public MainWindow() {
                // Initialize Property Values
                this.AppStart = DateTime.Now;
                this.SysUnLock = DateTime.Now;  // Set this to Now to keep the logic simple later

                // Add Event Handlers
                SystemEvents.SessionSwitch += this.SystemEvents_SessionSwitch;
                this.tmrWorking.Tick += this.tmrWorking_Tick;
                this.tmrOnBreak.Tick += this.tmrOnBreak_Tick;                

                // Initialize Timers
                this.tsWorking = new TimeSpan();
                this.tsOnBreak = new TimeSpan();

                // Start the Working timer
                this.tmrWorking.Start();

                // Set the current event start to indicate we're beginning a period where the workstation is unlocked (Actively Working/At Workstation/NOT on break)
                this.ActiveEvent = new SessionEvent() { Start = this.AppStart };
            }
        #endregion

        #region " Events"
            private void wpfMainWindow_Loaded(object sender, RoutedEventArgs e) {
                // Initialize Tracing
                this.Tracing_Init();
                // Show "App Started" Notification Message
                var msg = new NotificationMessage() { BalloonText = $"LunchTray Started: {DateTime.Now:HH:mm:ss}" };
                this.TrayIcon.ShowCustomBalloon(msg, PopupAnimation.Slide, 7000);

                // Go ahead and create a login event to the database
                this.ActiveEvent.EventTypeID = SessionSwitchReason.SessionLogon;
                this.ActiveEvent.Start = DateTime.Now;
                this.ActiveEvent.Ended = DateTime.Now;
                this.ActiveEvent.Message = $@"{DateTime.Now:MM/dd/yyyy ddd - HH:mm:ss}; #LoggedIn";

                // Save the Event to the database and it will create a new open ended event 
                this.SessionEventLog_Insert(this.ActiveEvent);                

                // Hide the form
                this.ShowInTaskbar = false;
                this.Visibility = Visibility.Hidden;
                this.Hide();
            }
            private void wpfMainWindow_Closing(object sender, CancelEventArgs e) {
                // Hide The Window
                this.ShowInTaskbar = false;
                this.Visibility = Visibility.Hidden;
                this.Hide();
                // Verify if the user really wants to close the app or more likely just minimize/hide it
                switch (MessageBox.Show("Would you like to keep the app running in the background?", "", MessageBoxButton.YesNo)) {
                    case MessageBoxResult.Yes:  // Keep the app running
                        e.Cancel = true; // Cancel the event
                        return;
                    case MessageBoxResult.No: // App will be closing therefore we want to end the work done and create the audit record
                        this.CloseApp();
                        break;
                }
            }
            private void wpfMainWindow_Closed(object sender, EventArgs e) {
                // Remove the notification icon
                this.TrayIcon.Dispose();
            }
            private void TrayIcon_TrayContextMenuOpen(object sender, RoutedEventArgs e) {

            }
            private void TrayIcon_PreviewTrayContextMenuOpen(object sender, RoutedEventArgs e) {

            }
            private void tbTraceOutput_TextChanged(object sender, TextChangedEventArgs e) {
                this.tbTraceOutput.ScrollToEnd();
            }
            private void SystemEvents_SessionSwitch(object sender, SessionSwitchEventArgs e) {
                switch (e.Reason) {
                    case SessionSwitchReason.SessionLogoff:
                        this.CloseApp(); // The code in here will write the events
                        break;
                    case SessionSwitchReason.SessionLock:
                        // Update relative DateTime properties                        
                        this.SysLocked = DateTime.Now;
                        
                        // Stop the Working timer
                        this.tmrWorking.Stop();

                        // Start the OnBreak Timer
                        this.tmrOnBreak.Start();

                        // We're ending a period where the workstation was unlocked ( NOT on break )
                        this.ActiveEvent.EventTypeID = e.Reason;
                        this.ActiveEvent.Ended = DateTime.Now;
                        this.ActiveEvent.Message = $@"{DateTime.Now:MM/dd/yyyy HH:mm:ss}; Starting Break; Time Worked: {this.tsWorking:dd\:hh\:mm\:ss}; [{e.Reason.ToString()}]";

                        // Save the Event to the database
                        this.SessionEventLog_Insert(this.ActiveEvent);
                        
                        break;
                    case SessionSwitchReason.SessionLogon:  // HACK: Capturing LogON UNLIKELY as the app will only be able to start AFTER logging on soooo..... (??)
                    case SessionSwitchReason.SessionUnlock:
                        // Update the UnLock variable
                        this.SysUnLock = DateTime.Now;

                        // Stop the break timer
                        this.tmrOnBreak.Stop();  // Break Over

                        // Check the two values to determine if the workstation has been locked a day or more (overnight or over the weekend) meaning that it would be today's Punch In and not a break
                        if (this.SysUnLock.Value.Date > this.SysLocked.Value.Date) {
                            // This indicates the first UnLock of the day which means that we need to reset the tsWorking & tsOnBreak TimeSpans for the day
                            this.tsWorking = new TimeSpan();
                            this.tsOnBreak = new TimeSpan();

                            // Start the Working timer
                            this.tmrWorking.Start();

                            // Update the PunchIn time for today
                            this.PunchIn = DateTime.Now; 

                            // Go ahead and write the punch in event to the database
                            this.ActiveEvent.EventTypeID = SessionSwitchReason.SessionLogon;
                            this.ActiveEvent.Start = this.SysUnLock.Value;
                            this.ActiveEvent.Ended = this.SysUnLock.Value;
                            this.ActiveEvent.Message = $@"{DateTime.Now:MM/dd/yyyy ddd - HH:mm:ss}; #PunchIn";

                            // Save the Event to the database
                            this.SessionEventLog_Insert(this.ActiveEvent);

                            // Show "Welcome Back From Break" Notification Message
                            var msg = new NotificationMessage() { BalloonText = $"Punching In: {DateTime.Now:HH:mm:ss}" };
                            this.TrayIcon.ShowCustomBalloon(msg, PopupAnimation.Slide, 7000);
                        } else {
                            // We're ending a period where the workstation was locked today ( On Break )
                            this.tmrWorking.Start(); // UnPause the timer

                            // Just get the time away for THIS break and leave tsOnBreak for total for the day
                            var tsAway = (this.SysUnLock.Value - this.SysLocked.Value);

                            // Set the remaining event information
                            this.ActiveEvent.EventTypeID = e.Reason;
                            this.ActiveEvent.Ended = DateTime.Now;
                            this.ActiveEvent.Message = $@"{DateTime.Now:MM/dd/yyyy HH:mm:ss}; Starting Work; Time Away: {tsAway:dd\:hh\:mm\:ss}; [{e.Reason.ToString()}]";

                            // Save the Event to the database and start the next ActiveEvent
                            this.SessionEventLog_Insert(this.ActiveEvent);

                            // Show "Welcome Back From Break" Notification Message
                            var msg = new NotificationMessage() { BalloonText = $@"Time OnBreak: {tsAway:hh\:mm\:ss}<newline/>Time Working: {this.tsWorking:hh\:mm\:ss}" };
                            this.TrayIcon.ShowCustomBalloon(msg, PopupAnimation.Slide, 7000);
                        }
                        break;
                }
            }
            private void tmrWorking_Tick(object sender, EventArgs e) {
                this.tsWorking = this.tsWorking.Add(this.tmrWorking.Interval);
                this.TrayIcon.ToolTipText = $@"Time Worked: {this.tsWorking:hh\:mm\:ss}; Total Breaks: {this.tsOnBreak:dd\:hh\:mm\:ss}";
            }
            private void tmrOnBreak_Tick(object sender, EventArgs e) {
                this.tsOnBreak = this.tsOnBreak.Add(this.tmrOnBreak.Interval);
            }
        #endregion

        #region " Methods "
            /// <summary>
            /// Sets <see cref="Window.WindowStartupLocation"/> and
            /// <see cref="Window.Owner"/> properties of a dialog that
            /// is about to be displayed.
            /// </summary>
            /// <param name="window">The processed window.</param>
            private void ShowDialog(Window window) {
                window.Owner = this;
                window.WindowStartupLocation = WindowStartupLocation.CenterOwner;
                window.ShowDialog();
            }
            private void CloseApp() {
                // Work Stops
                this.tmrWorking.Stop();

                // Update relative DateTime properties
                this.SysLogOff = DateTime.Now;
                var tsWork = (this.SysLogOff.Value - (this.SysUnLock ?? this.AppStart));

                // App will be closing therefore we want to end the work done and create the audit record
                // We're ending a period where the workstation was unlocked ( NOT on break )
                this.ActiveEvent.EventTypeID = SessionSwitchReason.SessionLogoff;
                this.ActiveEvent.Ended = this.SysLogOff.Value;
                this.ActiveEvent.Message = $@"{this.SysLogOff.Value:MM/dd/yyyy HH:mm:ss}; Logging Off; Time Worked: {tsWork:dd\:hh\:mm\:ss}; {this.ActiveEvent.EventTypeID}";

                // Save the Event to the database
                this.SessionEventLog_Insert(this.ActiveEvent);

                // Hide & Close Everything Out
                this.ShowInTaskbar = false;
                this.Visibility = Visibility.Hidden;
                this.Hide();
            }
            private void Tracing_Init() {
                // Add Trace Listener To Update TextBox / Notification
                using (var tw = new TextBoxTraceListener(this.tbTraceOutput)) {
                    Trace.Listeners.Add(tw);
                }
                // Add Trace Listner To Update the Text File
                using (var tw = new TextWriterTraceListener($@"{cfg.AppSettings["TracePath"]}{this.TraceFileName}", "DefaultFile")) {
                    Trace.Listeners.Add(tw);
                }
                // Save file after every Trace.Write
                Trace.AutoFlush = true;
                // Write the first line of the trace to indicate application has started
                Trace.WriteLine($@"{DateTime.Now:MM/dd/yyyy HH:mm:ss} Starting App;", "SessionLaunch");
            }
            private void SessionEventLog_Insert(SessionEvent e) {
                using (var DB = new SqlConnection(cfg.ConnectionStrings["App.SQL"].ToString())) {
                    DB.Open();
                    using (var CMD = new SqlCommand("dbo.SessionEventLog_Insert", DB)) {
                        // Identify that it's a procedure otherwise you'll get a syntax error bitching about not having "Exec " in front which is just, well.. INELEGANT!!
                        CMD.CommandType = CommandType.StoredProcedure;
                        CMD.Parameters.AddWithValue("@EventTypeID", e.EventTypeID);
                        CMD.Parameters.AddWithValue("@Start", e.Start);
                        CMD.Parameters.AddWithValue("@Ended", e.Ended);
                        CMD.Parameters.AddWithValue("@Message", e.Message);
                        // Setup Output / ReturnValue Parameters to get the newly inserted ID value
                        CMD.Parameters.Add("@NewID", SqlDbType.Int).Direction = ParameterDirection.Output;
                        CMD.Parameters.Add("ReturnValue", SqlDbType.Int).Direction = ParameterDirection.ReturnValue;
                        try {
                            CMD.ExecuteNonQuery();
                            this.ActiveEvent.ID = (int)CMD.Parameters["@NewID"].Value;
                        }
                        catch (SqlException x) {
                            Trace.WriteLine(x.ToString());
                        }
                        catch (Exception x) {
                            Trace.WriteLine(x.ToString());
                        }
                    }
                    DB.Close();
                }
                // Trace the event to the text file
                Trace.WriteLine(e.Message);
                // Start the next event
                this.ActiveEvent = new SessionEvent() { Start = e.Ended };
            }

        #endregion
        
    }
}
