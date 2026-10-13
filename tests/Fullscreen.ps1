param([string]$OutputDirectory = (Join-Path $PSScriptRoot '../SidebarDiagnostics/bin/Release'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
[void][Reflection.Assembly]::LoadFrom((Join-Path $OutputDirectory 'SidebarDiagnostics.DynamicHud.exe'))
$method = [SidebarDiagnostics.Sidebar].GetMethod('CoversScreen',[Reflection.BindingFlags]'Static,NonPublic')
function Rect($left,$top,$right,$bottom) {
    $r = [SidebarDiagnostics.Windows.RECT]::new()
    $r.Left=$left; $r.Top=$top; $r.Right=$right; $r.Bottom=$bottom
    return $r
}
$primary = Rect 0 0 1920 1080
$secondary = Rect -1920 0 0 1080
$cases = @(
    @($primary,$primary,'Chrome_WidgetWin_1',$true,'fullscreen YouTube'),
    @((Rect 0 0 1920 1032),$primary,'Chrome_WidgetWin_1',$false,'maximized browser'),
    @($secondary,$primary,'Chrome_WidgetWin_1',$false,'fullscreen on other monitor'),
    @($secondary,$secondary,'Chrome_WidgetWin_1',$true,'fullscreen on negative-coordinate monitor'),
    @($primary,$primary,'WorkerW',$false,'desktop'),
    @($primary,$primary,'Shell_TrayWnd',$false,'taskbar'),
    @((Rect 10 10 1800 1000),$primary,'Chrome_WidgetWin_1',$false,'windowed video')
)
foreach ($case in $cases) {
    $actual = $method.Invoke($null,@($case[0],$case[1],$case[2]))
    if ($actual -ne $case[3]) { throw "Failed: $($case[4])" }
    Write-Output "PASS $($case[4])"
}
