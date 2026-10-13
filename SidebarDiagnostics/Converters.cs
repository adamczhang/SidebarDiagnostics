using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;
using System.Windows.Input;
using SidebarDiagnostics.Windows;

namespace SidebarDiagnostics.Converters
{
    public class IntToStringConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            string _format = (string)parameter;

            if (string.IsNullOrEmpty(_format))
            {
                return value.ToString();
            }
            else
            {
                return string.Format(culture, _format, value);
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            int _return = 0;

            int.TryParse(value.ToString(), out _return);

            return _return;
        }
    }

    public class HotkeyToStringConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            Hotkey _hotkey = (Hotkey)value;

            if (_hotkey == null)
            {
                return "None";
            }

            return
                (_hotkey.AltMod ? "Alt + " : "") +
                (_hotkey.CtrlMod ? "Ctrl + " : "") +
                (_hotkey.ShiftMod ? "Shift + " : "") +
                (_hotkey.WinMod ? "Win + " : "") +
                new KeyConverter().ConvertToString(_hotkey.WinKey);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return null;
        }
    }

    public class PercentConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            double _value = (double)value;

            return string.Format("{0:0}%", _value);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return null;
        }
    }

    public class BoolInverseConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return !(bool)value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return !(bool)value;
        }
    }

    public class MetricWidthConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length < 6 || !(values[0] is string) || !(values[1] is System.Windows.Media.FontFamily)
                || !(values[2] is double) || !(values[3] is FontStyle)
                || !(values[4] is FontWeight) || !(values[5] is FontStretch)) return double.NaN;
            var face = new System.Windows.Media.Typeface((System.Windows.Media.FontFamily)values[1],
                (FontStyle)values[3], (FontWeight)values[4], (FontStretch)values[5]);
            var text = new System.Windows.Media.FormattedText((string)values[0], culture,
                FlowDirection.LeftToRight, face, (double)values[2], System.Windows.Media.Brushes.Black);
            return Math.Ceiling(text.WidthIncludingTrailingWhitespace) + 2;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotSupportedException();
        }
    }

    public class MetricLabelConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            string _value = (string)value;

            return string.Format("{0}:", _value);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return null;
        }
    }

    public class FontToSpaceConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            int _value = (int)value;

            return new Thickness(0, 0, _value * 0.4d, 0);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return null;
        }
    }
}
