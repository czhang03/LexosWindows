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

        readonly string anacondaPythonRegKey = @"SOFTWARE\Python\ContinuumAnalytics\Anaconda35-64\InstallPath";

        public MainWindow()
        {
            InitializeComponent();

        }

        private async void MainWindow_ContentRendered(object sender, EventArgs eventArgs)
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
            LoadingGrid.Visibility = Visibility.Collapsed;
            AppGrid.Visibility = Visibility.Visible;

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

        private void GetLexosLocation()
        {
            var programFilePath = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
            var defaultLexosLocation = Path.Combine(programFilePath, "lexos", "lexos.py");
            LexosPyLocation = @"C:\Users\zcsxo\GithubRepos\Lexos\lexos.py";
            LexosRequirementLocation = @"C:\Users\zcsxo\GithubRepos\Lexos\requirement.txt";
        }

        public void GetAnacondaLocation()
        {
            var homefolderPath = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            var defaultAnacondaPath = Path.Combine(homefolderPath, "Anaconda3", "python.exe");

            // get the anaconda executable path
            AnacondaExePath = defaultAnacondaPath;
            try
            {
                var anacondaKey = Registry.LocalMachine.OpenSubKey(anacondaPythonRegKey);
                AnacondaExePath = (string)anacondaKey.GetValue("ExecutablePath");
            }
            catch (Exception)
            {
                Console.WriteLine("using the default anaconda path");
            }

        }


        public void InstallPythonModule()
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
