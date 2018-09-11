using System.Windows.Input;

namespace MagicToolBox.LunchTray.Commands {
    /// <summary>
    /// Shows the main window.
    /// </summary>
    public class ShowWindowCommand : CommandBase<ShowWindowCommand> {
        public override void Execute(object parameter) {
            this.GetTaskbarWindow(parameter).Show();
            CommandManager.InvalidateRequerySuggested();
        }
        public override bool CanExecute(object parameter) {
            var win = this.GetTaskbarWindow(parameter);
            return win != null && !win.IsVisible;
        }
    }
    /// <summary>
    /// Hides the main window.
    /// </summary>
    public class HideWindowCommand : CommandBase<HideWindowCommand> {
        public override void Execute(object parameter) {
            this.GetTaskbarWindow(parameter).Hide();
            CommandManager.InvalidateRequerySuggested();
        }
        public override bool CanExecute(object parameter) {
            var win = this.GetTaskbarWindow(parameter);
            return win != null && win.IsVisible;
        }
    }
    /// <summary>
    /// Closes the current window.
    /// </summary>
    public class CloseWindowCommand : CommandBase<CloseWindowCommand> {
        public override void Execute(object parameter) {
            this.GetTaskbarWindow(parameter).Close();
            CommandManager.InvalidateRequerySuggested();
        }
        public override bool CanExecute(object parameter) {
            var win = this.GetTaskbarWindow(parameter);
            return win != null;
        }
    }
}
