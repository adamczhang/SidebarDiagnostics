param([string]$OutputDirectory = (Join-Path $PSScriptRoot '../SidebarDiagnostics/bin/Release'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
[void][Reflection.Assembly]::LoadFrom((Join-Path $OutputDirectory 'Newtonsoft.Json.dll'))
[void][Reflection.Assembly]::LoadFrom((Join-Path $OutputDirectory 'SidebarDiagnostics.DynamicHud.exe'))
function Assert($condition, $message) { if (!$condition) { throw $message } }
$legacy = [Newtonsoft.Json.JsonConvert]::DeserializeObject('{}', [SidebarDiagnostics.Framework.Settings])
Assert (!$legacy.HorizontalMode) 'Existing settings must remain vertical.'
$legacy.HorizontalMode = $true
$json = [Newtonsoft.Json.JsonConvert]::SerializeObject($legacy)
$restored = [Newtonsoft.Json.JsonConvert]::DeserializeObject($json, [SidebarDiagnostics.Framework.Settings])
Assert ($restored.HorizontalMode) 'Horizontal mode must survive a settings round trip.'
$app = [SidebarDiagnostics.App]::new()
$app.InitializeComponent()
$settings = [SidebarDiagnostics.Framework.Settings]::Instance
$settings.AutoBGColor = $false
$settings.BGColor = '#123456'
$settings.BGOpacity = 0.45
$hostGrid = [Windows.Controls.Grid]::new()
$background = [Windows.Controls.Grid]::new()
$background.Style = $app.FindResource('SidebarBackground')
[void]$hostGrid.Children.Add($background)
$scroll = [Windows.Controls.ScrollViewer]::new()
$scroll.Style = $app.FindResource('ContentView')
[void]$background.Children.Add($scroll)
$groups = [Windows.Controls.StackPanel]::new()
$groups.Style = $app.FindResource('OrientationPanel')
$scroll.Content = $groups
function Check-Layout($horizontal, $count, $width, $scale) {
    $settings.HorizontalMode = $horizontal
    $groups.Children.Clear()
    for ($i=0; $i -lt $count; $i++) {
        $group = [Windows.Controls.StackPanel]::new()
        $group.Style = $app.FindResource('GroupPanel')
        $row = [Windows.Controls.Border]::new()
        $row.Width = 120
        $row.Height = 100
        [void]$group.Children.Add($row)
        [void]$groups.Children.Add($group)
    }
    $hostGrid.LayoutTransform = [Windows.Media.ScaleTransform]::new($scale, $scale)
    $hostGrid.Measure([Windows.Size]::new($width, 800))
    $hostGrid.Arrange([Windows.Rect]::new(0, 0, $width, 800))
    $hostGrid.UpdateLayout()
    $first = $groups.Children[0].TranslatePoint([Windows.Point]::new(0,0), $groups)
    $second = $groups.Children[1].TranslatePoint([Windows.Point]::new(0,0), $groups)
    if ($horizontal) {
        Assert ($second.X -gt $first.X -and $second.Y -eq $first.Y) 'Horizontal sections must be side by side.'
        Assert ([Math]::Abs($background.TranslatePoint([Windows.Point]::new(0, $background.ActualHeight), $hostGrid).Y - $hostGrid.ActualHeight) -lt 1) 'Horizontal HUD must anchor to the bottom.'
        Assert ($background.ActualHeight -lt 200) 'Horizontal background should fit section height.'
        if ($count * 125 -lt $width / $scale) {
            Assert ($background.ActualWidth -lt $width / $scale) 'Horizontal background must shrink to content width.'
        } else {
            $scroll.ScrollToRightEnd()
            $hostGrid.UpdateLayout()
            Assert ($scroll.HorizontalOffset -gt 0) 'Horizontal overflow must be scrollable.'
        }
    } else {
        Assert ($second.Y -gt $first.Y -and $second.X -eq $first.X) 'Vertical mode must stack sections.'
        Assert ([Math]::Abs($background.ActualHeight - (30 + 120 * $count)) -lt 1) 'Vertical content sizing regressed.'
    }
    Assert ([Math]::Abs($background.Background.Opacity - 0.45) -lt 0.001) 'Opacity must be preserved.'
    Assert ($background.Background.Color.ToString() -eq '#FF123456') 'Color must be preserved.'
    Write-Output "PASS horizontal=$horizontal groups=$count width=$width scale=$scale"
}
Check-Layout $false 5 180 1
Check-Layout $true 5 1400 1
Check-Layout $true 2 1400 0.8
Check-Layout $true 10 700 1.5
Check-Layout $false 2 180 1
Write-Output 'PASS legacy default, persistence, mode switching, content sizing, scale, overflow and opacity.'

$settings.HorizontalMode = $true
$groups.Children.Clear()
foreach ($title in @('CPU','RAM','GPU','Drives','Network')) {
    $group = [Windows.Controls.StackPanel]::new()
    $group.Style = $app.FindResource('GroupPanel')
    $label = [Windows.Controls.Label]::new()
    $label.Style = $app.FindResource('AppTitle')
    $label.Content = $title
    [void]$group.Children.Add($label)
    $metrics = [Windows.Controls.Primitives.UniformGrid]::new()
    $metrics.Style = $app.FindResource('MetricRows')
    foreach ($value in @('Load: 18%', 'Free: 33 GB')) {
        $text = [Windows.Controls.TextBlock]::new()
        $text.Style = $app.FindResource('DataText')
        $text.Text = $value
        $text.Margin = [Windows.Thickness]::new(0,0,6,0)
        [void]$metrics.Children.Add($text)
    }
    [void]$group.Children.Add($metrics)
    [void]$groups.Children.Add($group)
}
$hostGrid.LayoutTransform = [Windows.Media.ScaleTransform]::new(1,1)
$hostGrid.Measure([Windows.Size]::new(1600,900))
$hostGrid.Arrange([Windows.Rect]::new(0,0,1600,900))
$hostGrid.UpdateLayout()
Assert ($background.ActualHeight -le 48) "Compact HUD exceeds a 48px taskbar: $($background.ActualHeight)"
Assert ($legacy.HorizontalXOffset -eq 0 -and $legacy.HorizontalYOffset -eq 0) 'Horizontal placement must default to bottom-left.'
Write-Output "PASS compact text height=$($background.ActualHeight), bottom anchoring and default offsets."

foreach ($count in @(1,2,3,6)) {
    $grid = [Windows.Controls.Primitives.UniformGrid]::new()
    $grid.Style = $app.FindResource('MetricRows')
    for ($i=0; $i -lt $count; $i++) {
        $cell = [Windows.Controls.Border]::new()
        $cell.Width = 80; $cell.Height = 14
        [void]$grid.Children.Add($cell)
    }
    $grid.Measure([Windows.Size]::new(1000,1000))
    $grid.Arrange([Windows.Rect]::new([Windows.Point]::new(0,0),$grid.DesiredSize))
    $positions = @($grid.Children | ForEach-Object { $_.TranslatePoint([Windows.Point]::new(0,0),$grid).Y } | Select-Object -Unique)
    Assert ($positions.Count -eq [Math]::Min(2,$count)) 'Metrics must occupy two rows when more than one is selected.'
    Assert ($grid.ActualWidth -eq (80 * [Math]::Ceiling($count / 2.0))) 'Two-row metrics must reduce width.'
    $settings.HorizontalMode = $false
    Assert ($grid.Columns -eq 1 -and $grid.Rows -eq 0) 'Vertical mode must restore one metric column.'
    $settings.HorizontalMode = $true
}
Write-Output 'PASS two metric rows for 1/2/3/6 metrics, reduced width and vertical restoration.'

$settings.HorizontalMode = $true
foreach ($round in @($true, $false)) {
    $metric = [SidebarDiagnostics.Monitoring.BaseMetric]::new([SidebarDiagnostics.Monitoring.MetricKey]::RAMUsed, ([Enum]::Parse([SidebarDiagnostics.Monitoring.DataType], 'bps', $false)), 'Test', $round, 0, [SidebarDiagnostics.Monitoring.BitsPerSecondConverter]::Instance)
    $text = [Windows.Controls.TextBlock]::new()
    $text.Style = $app.FindResource('MetricValue')
    $text.DataContext = $metric
    [void]$text.SetBinding([Windows.Controls.TextBlock]::TextProperty,[Windows.Data.Binding]::new('Text'))
    [void]$hostGrid.Children.Add($text)
    $hostGrid.UpdateLayout()
    $initialWidth = $null
    foreach ($value in @(0,128,126720,131072,134217728,999999999999)) {
        $metric.Update([double]$value)
        [Windows.Data.BindingOperations]::GetMultiBindingExpression($text, [Windows.FrameworkElement]::WidthProperty).UpdateTarget()
        $text.Measure([Windows.Size]::new(1000,1000))
        $text.Arrange([Windows.Rect]::new([Windows.Point]::new(0,0),$text.DesiredSize))
        if ($null -eq $initialWidth) { $initialWidth = $text.ActualWidth }
        Assert ($text.ActualWidth -eq $initialWidth) "Width shifted at $($metric.Text)"
    }
    if ($round) { $roundedWidth = $initialWidth } else { Assert ($initialWidth -gt $roundedWidth) 'Decimal mode needs extra capacity.' }
    $settings.HorizontalMode = $false
    Assert ([double]::IsNaN($text.Width)) 'Vertical mode must retain its existing auto width.'
    $settings.HorizontalMode = $true
    [void]$hostGrid.Children.Remove($text)
    $metric.Dispose()
}
Write-Output 'PASS fixed reading widths across digit changes, kbps/Mbps/Gbps, rounding and decimal modes.'



foreach ($round in @($true, $false)) {
    $metric = [SidebarDiagnostics.Monitoring.BaseMetric]::new([SidebarDiagnostics.Monitoring.MetricKey]::RAMUsed, ([Enum]::Parse([SidebarDiagnostics.Monitoring.DataType], 'Bps', $false)), 'Test', $round, 0, [SidebarDiagnostics.Monitoring.BytesPerSecondConverter]::Instance)
    foreach ($mb in @(999,999.49,999.5,999.999,1000,1023,1024)) {
        $metric.Update($mb * 1000 * 1000)
        Assert ($metric.Text -notmatch '^[0-9],[0-9]{3}') "Four-digit rate remains: $($metric.Text)"
    }
    $metric.Update(1000 * 1000 * 1000)
    Assert ($metric.Text -match 'GB/s') '1000 MB/s must promote to GB/s.'
    Assert ([Math]::Abs($metric.Value - (1000000000.0 / 1048576)) -lt 0.001) 'Display promotion must not change the numeric metric.'
    $settings.HorizontalMode = $false
    $metric.Update(1000 * 1024 * 1024)
    Assert ($metric.Text -match '1,000.*MB/s') 'Vertical formatting must remain unchanged.'
    $settings.HorizontalMode = $true
    $metric.Dispose()
}
Write-Output 'PASS early unit promotion at rounding boundaries; numeric values and vertical mode unchanged.'

foreach ($converter in @([SidebarDiagnostics.Monitoring.BitsPerSecondConverter]::Instance, [SidebarDiagnostics.Monitoring.BytesPerSecondConverter]::Instance)) {
    $metric = [SidebarDiagnostics.Monitoring.BaseMetric]::new([SidebarDiagnostics.Monitoring.MetricKey]::RAMUsed, ([Enum]::Parse([SidebarDiagnostics.Monitoring.DataType], 'Bps', $false)), 'Rate', $true, 0, $converter)
    foreach ($case in @(@(1000,'1 kB/s'),@(78000,'78 kB/s'),@(999499,'999 kB/s'),@(999500,'1 MB/s'),@(1000000,'1 MB/s'),@(1000000000,'1 GB/s'))) {
        $metric.Update([double]$case[0])
        Assert ($metric.Text -eq $case[1]) "Expected $($case[1]), got $($metric.Text)"
    }
    $metric.Dispose()
}
Write-Output 'PASS identical decimal bytes/second for network and drive converters, including rounding thresholds.'

Assert ([SidebarDiagnostics.Monitoring.BaseMonitor]::ClassifyGpu('AMD Radeon(TM) Graphics') -eq 'iGPU') 'Detected AMD integrated adapter heading.'
Assert ([SidebarDiagnostics.Monitoring.BaseMonitor]::ClassifyGpu('NVIDIA GeForce RTX 5070 Laptop GPU') -eq 'dGPU') 'Detected NVIDIA dedicated adapter heading.'
Assert ([SidebarDiagnostics.Monitoring.BaseMonitor]::ClassifyGpu('Unknown adapter') -eq 'GPU') 'Unknown GPU must not be guessed.'
$drives = @([SidebarDiagnostics.Monitoring.DriveMonitor]::new('C:', 'Custom C', [SidebarDiagnostics.Monitoring.MetricConfig[]]@(), $true, 0), [SidebarDiagnostics.Monitoring.DriveMonitor]::new('D:', 'Custom D', [SidebarDiagnostics.Monitoring.MetricConfig[]]@(), $true, 0))
$drivePanel = [SidebarDiagnostics.Monitoring.MonitorPanel]::new('Drives','M0,0 L1,1', [SidebarDiagnostics.Monitoring.iMonitor[]]$drives)
Assert ($drives[0].HorizontalHeading -eq 'Drives C:' -and $drives[1].HorizontalHeading -eq 'D:') 'Drive letters belong in per-column headings.'
Assert ($null -ne $drives[0].HorizontalIcon -and $null -eq $drives[1].HorizontalIcon) 'Only first column has an icon.'
$drivePanel.Dispose()
Write-Output 'PASS GPU classification, unknown fallback, drive column headings and first-column-only icon.'

$legacy.FontColor = '#FFFFFF'
Assert ($legacy.EffectiveHeadingColor -eq '#FFFFFF') 'Old settings should inherit the existing font color.'
$legacy.HeadingColor = '#00AAFF'
$restored = [Newtonsoft.Json.JsonConvert]::DeserializeObject([Newtonsoft.Json.JsonConvert]::SerializeObject($legacy), [SidebarDiagnostics.Framework.Settings])
Assert ($restored.HeadingColor -eq '#00AAFF') 'Heading color must persist.'
$settings.HeadingColor = '#00AAFF'
$settings.FontColor = '#FFFFFF'
$heading = [Windows.Controls.Label]::new()
$heading.Style = $app.FindResource('HeadingTitle')
$reading = [Windows.Controls.TextBlock]::new()
$reading.Style = $app.FindResource('DataText')
Assert ($heading.Foreground.Color.ToString() -eq '#FF00AAFF') 'Heading style should use the selected color.'
Assert ($reading.Foreground.Color.ToString() -eq '#FFFFFFFF') 'Readings must keep the existing font color.'
$settings.HeadingColor = '#FFAA00'
Assert ($heading.Foreground.Color.ToString() -eq '#FFFFAA00') 'Heading color should update dynamically.'
Write-Output 'PASS heading color persistence, legacy fallback and independent heading/readout colors.'
