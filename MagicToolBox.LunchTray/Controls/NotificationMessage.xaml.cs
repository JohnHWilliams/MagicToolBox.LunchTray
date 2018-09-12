using System;
using System.Windows;
using System.Windows.Input;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;

using Hardcodet.Wpf.TaskbarNotification;

namespace MagicToolBox.LunchTray {
    /// <summary>
    /// Interaction logic for NotificationMessage.xaml
    /// </summary>
    public partial class NotificationMessage : UserControl {
        private bool isClosing = false;

        #region " BalloonText dependency property "
            /// <summary>
            /// BaloonText
            /// </summary>
            public static readonly DependencyProperty BalloonTextProperty =
                DependencyProperty.Register("BalloonText",
                    typeof(string),
                    typeof(NotificationMessage),
                    new FrameworkPropertyMetadata("")
                );
            /// <summary>
            /// A property wrapper for the <see cref="BalloonTextProperty"/>
            /// dependency property:<br/>
            /// Description
            /// </summary>
            public string BalloonText {
                get { return (string)this.GetValue(BalloonTextProperty); }
                set { this.SetValue(BalloonTextProperty, value); }
            }
        #endregion

        #region " Constructor "
            public NotificationMessage() {
                InitializeComponent();
            }
        #endregion

        #region " Events "
            /// <summary>
            /// By subscribing to the <see cref="TaskbarIcon.BalloonClosingEvent"/>
            /// and setting the "Handled" property to true, we suppress the popup
            /// from being closed in order to display the custom fade-out animation.
            /// </summary>
            private void OnBalloonClosing(object sender, RoutedEventArgs e) {
                e.Handled = true; //suppresses the popup from being closed immediately
                this.isClosing = true;
            }
            /// <summary>
            /// Resolves the <see cref="TaskbarIcon"/> that displayed
            /// the balloon and requests a close action.
            /// </summary>
            private void imgClose_MouseDown(object sender, MouseButtonEventArgs e) {
                //the tray icon assigned this attached property to simplify access
                var taskbarIcon = TaskbarIcon.GetParentTaskbarIcon(this);
                taskbarIcon.CloseBalloon();
            }
            /// <summary>
            /// If the users hovers over the balloon, we don't close it.
            /// </summary>
            private void grid_MouseEnter(object sender, MouseEventArgs e) {
                //if we're already running the fade-out animation, do not interrupt anymore
                //(makes things too complicated for the sample)
                if (this.isClosing) return;

                //the tray icon assigned this attached property to simplify access
                var taskbarIcon = TaskbarIcon.GetParentTaskbarIcon(this);
                taskbarIcon.ResetBalloonCloseTimer();
            }
            private void me_MouseLeave(object sender, MouseEventArgs e) {
                this.imgClose.Visibility = Visibility.Visible;
                //this.Visibility = Visibility.Hidden;
                //the tray icon assigned this attached property to simplify access
                var taskbarIcon = TaskbarIcon.GetParentTaskbarIcon(this);
                taskbarIcon.CloseBalloon();
            }
            /// <summary>
            /// Closes the popup once the fade-out animation completed.
            /// The animation was triggered in XAML through the attached
            /// BalloonClosing event.
            /// </summary>
            private void OnFadeOutCompleted(object sender, EventArgs e) {
                try {
                    var pp = (Popup)this.Parent;
                    pp.IsOpen = false;
                }
                catch { }
            }
        #endregion

    }
}
