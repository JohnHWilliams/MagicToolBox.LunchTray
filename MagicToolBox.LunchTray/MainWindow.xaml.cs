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
            private TimeSpan tsWorking { set; get; }
            private TimeSpan tsOnBreak { set; get; }
            DispatcherTimer tmrWork = new DispatcherTimer() { Interval = new TimeSpan(0, 0, 1), IsEnabled = true };
            DispatcherTimer tmrBreak = new DispatcherTimer() { Interval = new TimeSpan(0, 0, 1), IsEnabled = true };
        #endregion

        #region " Constructors "
            public MainWindow() {
                this.InitializeComponent();

                // Initialize Property Values
                this.AppStart = DateTime.Now;
                this.SysUnLock = DateTime.Now;  // Set this to Now to keep the logic simple later

                // Add Event Handlers
                SystemEvents.SessionSwitch += this.SystemEvents_SessionSwitch;
                this.tmrWork.Tick += this.tmrWork_Tick;
                this.tmrBreak.Tick += this.tmrBreak_Tick;
                
                // Set the current event start to indicate we're beginning a period where the workstation is unlocked (Actively Working/At Workstation/NOT on break)
                this.ActiveEvent = new SessionEvent() { Start = this.AppStart };

                // Start Working Timer
                this.tmrWork.Start();
            }
        #endregion

        #region " Events"
            private void wpfMainWindow_Loaded(object sender, RoutedEventArgs e) {
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
                    case SessionSwitchReason.SessionLock:
                    case SessionSwitchReason.SessionLogoff:
                        // Work Stops & Break Begins
                        this.tmrWork.Stop();  // Work Stops
                        this.tmrBreak.Start(); // Break Begins

                        // Update relative DateTime properties
                        this.SysLocked = DateTime.Now;
                        if (e.Reason == SessionSwitchReason.SessionLogoff) this.SysLogOff = DateTime.Now;
                        var tsWork = (this.SysLocked.Value - this.SysUnLock.Value); // Initialized UnLock DateTime Value on construct so it's safe to use this and not worry about logic to figure it out

                        // We're ending a period where the workstation was unlocked ( NOT on break )
                        this.ActiveEvent.EventTypeID = e.Reason;
                        this.ActiveEvent.Ended = DateTime.Now;
                        this.ActiveEvent.Message = $@"{DateTime.Now:MM/dd/yyyy HH:mm:ss}; Starting Break; Time Worked: {tsWork:dd\:hh\:mm\:ss}; {e.Reason.ToString()}";

                        // Save the Event to the database
                        this.SessionEventLog_Insert(this.ActiveEvent);
                        
                        break;
                    case SessionSwitchReason.SessionUnlock:
                    case SessionSwitchReason.SessionLogon:  // TODO: Capturing LogON UNLIKELY as the app will only be able to start AFTER logging on soooo..... (??)
                        // Work Starts & Break Ends
                        this.tmrBreak.Stop();  // Break Over
                        this.tmrWork.Start();  // Work Begins

                        // Update relative DateTime properties
                        this.SysUnLock = DateTime.Now;
                        var tsAway = (this.SysUnLock.Value - this.SysLocked.Value);

                        // We're ending a period where the workstation was locked ( WAS ON break )
                        this.ActiveEvent.EventTypeID = e.Reason;
                        this.ActiveEvent.Ended = DateTime.Now;
                        this.ActiveEvent.Message = $@"{DateTime.Now:MM/dd/yyyy HH:mm:ss}; Starting Work; Time Away: {tsAway:dd\:hh\:mm\:ss}; {e.Reason.ToString()}";

                        // Save the Event to the database
                        this.SessionEventLog_Insert(this.ActiveEvent);

                        // Show Notification 
                        var msg = new NotificationMessage() { BalloonText = $"Time Away: {tsAway.ToString(@"hh\:mm\:ss")}" };
                        this.TrayIcon.ShowCustomBalloon(msg, PopupAnimation.Slide, 7000);

                        break;
                }
            }
            private void tmrWork_Tick(object sender, EventArgs e) {
                // Refresh the working timespan
                this.tsWorking = (DateTime.Now - this.SysUnLock.Value);
                this.TrayIcon.ToolTipText = $@"Time Worked: {tsWorking:dd\:hh\:mm\:ss}";
            }
            private void tmrBreak_Tick(object sender, EventArgs e) {
                // Refresh the on break timespan
                this.tsOnBreak = this.SysLocked.HasValue ? (DateTime.Now - this.SysLocked.Value) : (DateTime.Now - DateTime.Now);
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
                this.tmrWork.Stop();

                // Update relative DateTime properties
                this.SysLogOff = DateTime.Now;
                var tsWork = (this.SysLogOff.Value - this.SysUnLock.Value);

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
                Trace.WriteLine(this.ActiveEvent.Message);
                // Start the next event
                this.ActiveEvent = new SessionEvent() { Start = e.Ended };
            }

        #endregion
        
    }
}
