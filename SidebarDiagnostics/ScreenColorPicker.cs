using System;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media.Imaging;

namespace SidebarDiagnostics
{
    // Capture once, then sample the original pixels rather than the overlay or cursor.
    internal sealed class ScreenColorPicker : Window
    {
        [StructLayout(LayoutKind.Sequential)]
        private struct Point { public int X; public int Y; }
        [DllImport("user32.dll")] private static extern int GetSystemMetrics(int index);
        [DllImport("user32.dll")] private static extern bool GetCursorPos(out Point point);
        [DllImport("user32.dll")] private static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int width, int height, uint flags);

        private ScreenColorPicker(Bitmap capture, int left, int top)
        {
            WindowStyle = WindowStyle.None;
            ResizeMode = ResizeMode.NoResize;
            ShowInTaskbar = false;
            Topmost = true;
            Cursor = Cursors.Cross;
            var source = new BitmapImage();
            using (var stream = new MemoryStream())
            {
                capture.Save(stream, System.Drawing.Imaging.ImageFormat.Png);
                stream.Position = 0;
                source.BeginInit();
                source.CacheOption = BitmapCacheOption.OnLoad;
                source.StreamSource = stream;
                source.EndInit();
                source.Freeze();
            }
            Content = new System.Windows.Controls.Image { Source = source, Stretch = System.Windows.Media.Stretch.Fill };
            SourceInitialized += (sender, args) => SetWindowPos(new WindowInteropHelper(this).Handle,
                new IntPtr(-1), left, top, capture.Width, capture.Height, 0x0040);
            PreviewKeyDown += (sender, args) => { if (args.Key == Key.Escape) { args.Handled = true; Close(); } };
            PreviewMouseRightButtonDown += (sender, args) => { args.Handled = true; Close(); };
            PreviewMouseLeftButtonDown += (sender, args) =>
            {
                args.Handled = true;
                Point point;
                if (!GetCursorPos(out point)) return;
                int x = point.X - left, y = point.Y - top;
                if (x < 0 || y < 0 || x >= capture.Width || y >= capture.Height) return;
                var color = capture.GetPixel(x, y);
                SelectedColor = string.Format("#{0:X2}{1:X2}{2:X2}", color.R, color.G, color.B);
                DialogResult = true;
            };
        }

        public string SelectedColor { get; private set; }

        public static string Pick()
        {
            // Virtual desktop includes monitors to the left/above the primary display.
            int left = GetSystemMetrics(76), top = GetSystemMetrics(77);
            int width = GetSystemMetrics(78), height = GetSystemMetrics(79);
            using (var capture = new Bitmap(width, height))
            {
                using (var graphics = Graphics.FromImage(capture))
                    graphics.CopyFromScreen(left, top, 0, 0, capture.Size, CopyPixelOperation.SourceCopy);
                var picker = new ScreenColorPicker(capture, left, top);
                return picker.ShowDialog() == true ? picker.SelectedColor : null;
            }
        }
    }
}

