using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using Microsoft.Win32;
using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using CefSharp;
using Path = System.IO.Path;

namespace LexosWindows
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public Process MainProcess { get; set; }
        public string AnacondaExePath { get; set; }
        public string LexosPyLocation { get; set; }
        public string LexosRequirementLocation { get; set; }

        readonly string anacondaPythonRegKeyPath = @"SOFTWARE\Python\ContinuumAnalytics\Anaconda35-64\InstallPath";
        readonly string lexosInfoRegKeyPath = @"SOFTWARE\Lexos";


        public MainWindow()
        {
            InitializeComponent();

        }

        private async void MainWindow_ContentRendered(object sender, EventArgs eventArgs)
        {
            try
            {
                // find lexos.py file path
                InfomationTextBlock.Text = "Finding Lexos Path...";
                GetLexosLocation();

                // find anaconda 
                InfomationTextBlock.Text = "Finding Anaconda Path...";
                GetAnacondaLocation();

                // intall required modules 
                InfomationTextBlock.Text = "checking and installing requirements...";
                await Task.Run(() => InstallPythonModule());

                // starting python
                InfomationTextBlock.Text = "Starting Python...";
                StartMainProcess();

                // wait until localhost:5000 is live
                InfomationTextBlock.Text = "Initiallizing...";
                await Task.Run(() => TestConnectionHelper());

                // display elements
                ErrorGrid.Visibility = Visibility.Collapsed;
                LoadingGrid.Visibility = Visibility.Collapsed;
                AppGrid.Visibility = Visibility.Visible;
            }
            catch (Exception e)
            {
                AppGrid.Visibility = Visibility.Collapsed;
                LoadingGrid.Visibility = Visibility.Collapsed;
                ErrorGrid.Visibility = Visibility.Visible;
                ErrorDetailTextBlock.Text = $"{e.GetType()}: {e.Message}";
            }
            

        }

        private void MainWindow_OnClosing(object sender, CancelEventArgs e)
        {
            MainProcess?.Kill();
        }

        private void ChromiumBack_OnClick(object sender, RoutedEventArgs e)
        {
            if (LexosBrowser.CanGoBack)
            {
                LexosBrowser.Back();
            }
        }

        private void HyperLink_OpenInBrowser(object sender, RequestNavigateEventArgs e)
        {
            Process.Start(new ProcessStartInfo(e.Uri.AbsoluteUri));
            e.Handled = true;
        }

        private void GetLexosLocation()
        {
            var ApplicationDataFolder = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            var defaultLexosLocation = Path.Combine(ApplicationDataFolder, "lexos", "scr");
            LexosPyLocation = Path.Combine(defaultLexosLocation, "lexos.py");
            LexosRequirementLocation = Path.Combine(defaultLexosLocation, "requirement.txt");

            // get the anaconda executable path
            try
            {
                var lexosInfoKey = Registry.CurrentUser.OpenSubKey(lexosInfoRegKeyPath);
                LexosPyLocation = (string)lexosInfoKey.GetValue("LexosPyLocation");
                LexosRequirementLocation = (string)lexosInfoKey.GetValue("LexosReqLocation");
            }
            catch (Exception)
            {
                Console.WriteLine("using the default Lexos path");
            }


        }

        private void GetAnacondaLocation()
        {
            var homefolderPath = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            var defaultAnacondaPath = Path.Combine(homefolderPath, "Anaconda3", "python.exe");

            try
            {
                var anacondaKey = Registry.LocalMachine.OpenSubKey(anacondaPythonRegKeyPath);
                AnacondaExePath = (string)anacondaKey.GetValue("ExecutablePath");
            }
            catch (Exception)
            {
                Console.WriteLine("using the default Anaconda path");
            }

        }


        private void InstallPythonModule()
        {
            var pipProcess = new Process()
            {
                StartInfo =
                {
                    FileName = AnacondaExePath,
                    Arguments = $"-m pip install -r {LexosRequirementLocation}",
                    CreateNoWindow = true,
                    RedirectStandardOutput = true,
                    UseShellExecute = false,
                }
            };

            pipProcess.Start();
            pipProcess.WaitForExit();

        }

        private void TestConnectionHelper()
        {

            var connectionSuccessful = false;

            while (!connectionSuccessful)
            {
                Socket s = new Socket(AddressFamily.InterNetwork,
                    SocketType.Stream,
                    ProtocolType.Tcp);

                if (MainProcess.HasExited)
                {
                    throw new HttpListenerException(1, "the main python process has exited");
                }

                try
                {
                    s.Connect("127.0.0.1", 5000);
                    connectionSuccessful = true;
                }
                catch
                {

                }
            }

        }

        private void StartMainProcess ()
        {
             MainProcess = new Process
            {
                StartInfo =
                {
                    FileName = AnacondaExePath,
                    Arguments = LexosPyLocation,
                    CreateNoWindow = true,
                    RedirectStandardOutput = true,
                    UseShellExecute = false
                }
            };

            MainProcess.Start();
        }

    }
}
