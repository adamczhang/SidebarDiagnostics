# Run after a Release build: powershell.exe -NoProfile -STA -File tests/BackgroundLayout.ps1
# Loads the compiled resources without starting the app or writing user settings.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
$output = Join-Path $PSScriptRoot '../SidebarDiagnostics/bin/Release'
[void][Reflection.Assembly]::LoadFrom((Join-Path $output 'Newtonsoft.Json.dll'))
[void][Reflection.Assembly]::LoadFrom((Join-Path $output 'SidebarDiagnostics.exe'))

function Assert($condition, $message) {
    if (!$condition) { throw $message }
}

$settingsType = [SidebarDiagnostics.Framework.Settings]
$legacy = [Newtonsoft.Json.JsonConvert]::DeserializeObject('{}', $settingsType)
Assert (!$legacy.FitBackgroundToContent) 'Legacy settings must keep the full-height default.'
$legacy.FitBackgroundToContent = $true
$json = [Newtonsoft.Json.JsonConvert]::SerializeObject($legacy)
$restored = [Newtonsoft.Json.JsonConvert]::DeserializeObject($json, $settingsType)
Assert ($restored.FitBackgroundToContent) 'The setting must survive JSON serialization.'

$app = [SidebarDiagnostics.App]::new()
$app.InitializeComponent()
$settings = [SidebarDiagnostics.Framework.Settings]::Instance
$settings.AutoBGColor = $false
$settings.BGColor = '#123456'
$settings.BGOpacity = 0.45
$hostGrid = [Windows.Controls.Grid]::new()
$panel = [Windows.Controls.Grid]::new()
$panel.Style = $app.FindResource('SidebarBackground')
[void]$hostGrid.Children.Add($panel)
$dock = [Windows.Controls.DockPanel]::new()
[void]$panel.Children.Add($dock)
$menu = [Windows.Controls.Border]::new()
$menu.Height = 34
[Windows.Controls.DockPanel]::SetDock($menu, 'Top')
[void]$dock.Children.Add($menu)
$scroll = [Windows.Controls.ScrollViewer]::new()
$scroll.Style = $app.FindResource('ContentView')
[void]$dock.Children.Add($scroll)
$content = [Windows.Controls.StackPanel]::new()
$scroll.Content = $content

function Check-Layout($count, $fit, $scale, $menuVisible = $true) {
    $settings.FitBackgroundToContent = $fit
    $menu.Visibility = if ($menuVisible) { 'Visible' } else { 'Collapsed' }
    $content.Children.Clear()
    for ($i = 0; $i -lt $count; $i++) {
        $row = [Windows.Controls.Border]::new()
        $row.Height = 80
        [void]$content.Children.Add($row)
    }
    $hostGrid.LayoutTransform = [Windows.Media.ScaleTransform]::new($scale, $scale)
    $hostGrid.Measure([Windows.Size]::new(200, 1000))
    $hostGrid.Arrange([Windows.Rect]::new(0, 0, 200, 1000))
    $hostGrid.UpdateLayout()
    $naturalHeight = 30 + 80 * $count
    if ($menuVisible) { $naturalHeight += 34 }
    $expected = if ($fit) { [Math]::Min($naturalHeight, 1000 / $scale) } else { 1000 / $scale }
    Assert ([Math]::Abs($panel.ActualHeight - $expected) -lt 1) "Unexpected background height: $($panel.ActualHeight); expected $expected."
    Assert ([Math]::Abs($panel.Background.Opacity - 0.45) -lt 0.001) 'Background opacity binding changed.'
    Assert ($panel.Background.Color.ToString() -eq '#FF123456') 'Background color binding changed.'
    if (80 * $count -gt $scroll.ViewportHeight) {
        $scroll.ScrollToEnd()
        $hostGrid.UpdateLayout()
        Assert ($scroll.VerticalOffset -gt 0) 'Overflowing content must remain scrollable.'
    }
    Write-Output "PASS: rows=$count fit=$fit scale=$scale menu=$menuVisible height=$($panel.ActualHeight)"
}

Check-Layout 5 $false 1
Check-Layout 5 $true 1
Check-Layout 20 $true 1
Check-Layout 2 $true 1
Check-Layout 5 $true 0.8
Check-Layout 20 $true 1.5
Check-Layout 5 $true 1 $false
Check-Layout 5 $false 1
$settings.AutoBGColor = $true
$hostGrid.UpdateLayout()
Assert ($panel.Background.Color -eq [Windows.SystemParameters]::WindowGlassColor) 'Automatic background color binding changed.'
Assert ([Math]::Abs($panel.Background.Opacity - 0.45) -lt 0.001) 'Automatic background opacity binding changed.'
Write-Output 'PASS: legacy default, JSON round trip, dynamic mode switching, color and opacity bindings.'
