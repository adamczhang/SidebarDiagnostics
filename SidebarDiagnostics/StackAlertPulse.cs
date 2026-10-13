using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using SidebarDiagnostics.Monitoring;

namespace SidebarDiagnostics
{
    public static class StackAlertPulse
    {
        public static readonly DependencyProperty EnabledProperty = DependencyProperty.RegisterAttached(
            "Enabled", typeof(bool), typeof(StackAlertPulse), new PropertyMetadata(false, Changed));
        public static void SetEnabled(DependencyObject target, bool value) { target.SetValue(EnabledProperty, value); }
        public static bool GetEnabled(DependencyObject target) { return (bool)target.GetValue(EnabledProperty); }
        private static void Changed(DependencyObject target, DependencyPropertyChangedEventArgs args)
        {
            if ((bool)args.NewValue) new Subscription((FrameworkElement)target);
        }
        private sealed class Subscription
        {
            private readonly FrameworkElement root;
            private readonly List<BaseMetric> metrics = new List<BaseMetric>();
            private bool pending;
            public Subscription(FrameworkElement element)
            {
                root = element;
                root.Loaded += (s, e) => Bind();
                root.Unloaded += (s, e) => Unbind();
                root.DataContextChanged += (s, e) => { if (root.IsLoaded) Bind(); };
            }
            private void Unbind()
            {
                foreach (var metric in metrics) metric.PropertyChanged -= OnMetricChanged;
                metrics.Clear();
            }
            private void Bind()
            {
                Unbind();
                var monitor = root.DataContext as BaseMonitor;
                if (monitor == null || monitor.Metrics == null) return;
                metrics.AddRange(monitor.Metrics.OfType<BaseMetric>());
                foreach (var metric in metrics) metric.PropertyChanged += OnMetricChanged;
            }
            private void OnMetricChanged(object sender, PropertyChangedEventArgs args)
            {
                if (args.PropertyName != "IsActivityAlert" || !((BaseMetric)sender).IsActivityAlert) return;
                // Batch simultaneous transitions within a monitor into one pulse.
                if (pending) return;
                pending = true;
                root.Dispatcher.BeginInvoke(new Action(() =>
                {
                    pending = false;
                    if (root.IsLoaded) Animate(root);
                }));
            }
        }
        internal static ObjectAnimationUsingKeyFrames CreatePulse(Color normal, Color alert)
        {
        var animation = new ObjectAnimationUsingKeyFrames
        {
            Duration = TimeSpan.FromSeconds(1.5), FillBehavior = FillBehavior.Stop
        };
        // Three soft color pulses. Stopping the animation restores the live binding,
        // including the configured alert color on any reading still in alert.
        for (int step = 0; step <= 30; step++)
        {
            double amount = Math.Pow(Math.Sin(Math.PI * step / 10d), 2);
            var color = Color.FromArgb(normal.A,
                (byte)(normal.R + (alert.R - normal.R) * amount),
                (byte)(normal.G + (alert.G - normal.G) * amount),
                (byte)(normal.B + (alert.B - normal.B) * amount));
            animation.KeyFrames.Add(new DiscreteObjectKeyFrame(new SolidColorBrush(color),
                KeyTime.FromTimeSpan(TimeSpan.FromMilliseconds(step * 50))));
        }
            return animation;
        }

        private static void Animate(DependencyObject node)
        {
            DependencyProperty property = node is TextBlock ? TextBlock.ForegroundProperty :
                node is Control ? Control.ForegroundProperty : node is Shape ? Shape.FillProperty : null;
            if (property != null && node is FrameworkElement)
            {
                var brush = node.GetValue(property) as SolidColorBrush;
                if (brush != null)
                {
                    var normal = brush.Color;
                    // A newly alerting heading already has its sustained color by this point.
                    // Start its pulse from the user's normal heading color, then restore its binding.
                    if (node is Label || node is Shape)
                        normal = (Color)ColorConverter.ConvertFromString(Framework.Settings.Instance.EffectiveHeadingColor);
                    var alert = (Color)ColorConverter.ConvertFromString(Framework.Settings.Instance.AlertFontColor);
                    var animation = CreatePulse(normal, alert);
                    ((FrameworkElement)node).BeginAnimation(property, animation);
                }
            }
            for (int i = 0; i < VisualTreeHelper.GetChildrenCount(node); i++) Animate(VisualTreeHelper.GetChild(node, i));
        }
    }
}
