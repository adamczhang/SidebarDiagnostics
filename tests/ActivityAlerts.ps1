param([string]$OutputDirectory = (Join-Path $PSScriptRoot '../SidebarDiagnostics/bin/Release'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
[void][Reflection.Assembly]::LoadFrom((Join-Path $OutputDirectory 'SidebarDiagnostics.DynamicHud.exe'))
[SidebarDiagnostics.Framework.Settings]::Instance.AlertBlink = $false
[SidebarDiagnostics.Framework.Settings]::Instance.AlertFontColor = '#FFFF00'
function Assert($ok,$message) { if (!$ok) { throw $message } }
foreach ($case in @(@('CPULoad','Percent',65),@('GPUCoreLoad','Percent',65),@('GPUVRAMLoad','Percent',65),@('RAMLoad','Percent',65),@('DriveRead','Bps',1000000000),@('DriveWrite','Bps',1000000000),@('NetworkIn','Bps',50000000),@('NetworkOut','Bps',50000000))) {
    foreach ($round in @($true,$false)) {
        $key = [Enum]::Parse([SidebarDiagnostics.Monitoring.MetricKey],$case[0])
        $unit = [Enum]::Parse([SidebarDiagnostics.Monitoring.DataType],$case[1],$false)
        $converter = if ($case[1] -eq 'Bps') { [SidebarDiagnostics.Monitoring.BytesPerSecondConverter]::Instance } else { $null }
        $metric = [SidebarDiagnostics.Monitoring.BaseMetric]::new($key,$unit,'Test',$round,0,$converter)
        $metric.Update([double]$case[2])
        Assert (!$metric.IsAlert) 'Exactly at threshold should not alert.'
        $metric.Update([double]$case[2]+0.1)
        Assert ($metric.IsAlert -and $metric.AlertColor -eq '#FFFF00') 'Above threshold must use the customized alert color.'
        $metric.Update(0)
        Assert (!$metric.IsAlert) 'Alert must clear when activity drops.'
        $metric.Dispose()
    }
    Write-Output "PASS $($case[0]) boundary, rounding independence and recovery"
}
$ram = [SidebarDiagnostics.Monitoring.BaseMetric]::new([SidebarDiagnostics.Monitoring.MetricKey]::RAMUsed,([Enum]::Parse([SidebarDiagnostics.Monitoring.DataType],'Gigabyte')),'Used',$true,0,$null)
$ram.ActivityPercent = [Func[Nullable[double]]]{ return [Nullable[double]]66 }
$ram.Update(24)
Assert ($ram.IsAlert) 'RAM GB readouts must use utilization, not the displayed byte count.'
$ram.ActivityPercent = [Func[Nullable[double]]]{ return [Nullable[double]]65 }
$ram.Update(24)
Assert (!$ram.IsAlert) 'RAM utilization alert must clear.'
$ram.Dispose()
$temp = [SidebarDiagnostics.Monitoring.BaseMetric]::new([SidebarDiagnostics.Monitoring.MetricKey]::CPUTemp,([Enum]::Parse([SidebarDiagnostics.Monitoring.DataType],'Celcius')),'Temp',$true,80,$null)
$temp.Update(80)
Assert ($temp.IsAlert -and $temp.AlertColor -eq '#FFFF00') 'Existing temperature threshold/color must remain intact.'
$temp.Dispose()
Write-Output 'PASS RAM utilization mapping and existing temperature alerts.'
