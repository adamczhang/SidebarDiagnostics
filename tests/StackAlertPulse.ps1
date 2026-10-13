param([string]$OutputDirectory = (Join-Path $PSScriptRoot '../SidebarDiagnostics/bin/Release'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
[void][Reflection.Assembly]::LoadFrom((Join-Path $OutputDirectory 'SidebarDiagnostics.DynamicHud.exe'))
$factory = [SidebarDiagnostics.StackAlertPulse].GetMethod('CreatePulse',[Reflection.BindingFlags]'Static,NonPublic')
$normal = [Windows.Media.Colors]::White
$alert = [Windows.Media.Colors]::Cyan
$pulse = $factory.Invoke($null,@($normal,$alert))
if ($pulse.KeyFrames[5].Value.Color -ne $alert -or $pulse.KeyFrames[15].Value.Color -ne $alert -or $pulse.KeyFrames[25].Value.Color -ne $alert) { throw 'All three pulses must reach the custom color.' }
if ($pulse.KeyFrames[0].Value.Color -ne $normal -or $pulse.KeyFrames[30].Value.Color -ne $normal) { throw 'Pulse must return to the initial color.' }
if ($pulse.FillBehavior -ne 'Stop' -or $pulse.Duration.TimeSpan.TotalSeconds -ne 1.5) { throw 'Pulse must end and release the color binding after 1.5 seconds.' }
[SidebarDiagnostics.Framework.Settings]::Instance.AlertFontColor = '#00FFFF'
[SidebarDiagnostics.Framework.Settings]::Instance.AlertBlink = $true
$m = [SidebarDiagnostics.Monitoring.BaseMetric]::new([SidebarDiagnostics.Monitoring.MetricKey]::CPULoad,([Enum]::Parse([SidebarDiagnostics.Monitoring.DataType],'Percent')),'Load',$true,0,$null)
$m.Update(80)
if (!$m.IsActivityAlert -or $m.AlertColor -ne '#00FFFF') { throw 'Sustained reading must use custom color even with legacy blinking enabled.' }
$m.Update(20)
if ($m.IsAlert -or $m.IsActivityAlert) { throw 'Activity alert must clear.' }
$m.Dispose()
Write-Output 'PASS three custom-color pulses, finite animation, binding restoration and steady custom activity color.'

$monitor = [SidebarDiagnostics.Monitoring.BaseMonitor]::new('test','Test',$false)
$first = [SidebarDiagnostics.Monitoring.BaseMetric]::new([SidebarDiagnostics.Monitoring.MetricKey]::CPULoad,([Enum]::Parse([SidebarDiagnostics.Monitoring.DataType],'Percent')),'First',$true,0,$null)
$second = [SidebarDiagnostics.Monitoring.BaseMetric]::new([SidebarDiagnostics.Monitoring.MetricKey]::RAMLoad,([Enum]::Parse([SidebarDiagnostics.Monitoring.DataType],'Percent')),'Second',$true,0,$null)
$property = [SidebarDiagnostics.Monitoring.BaseMonitor].GetProperty('Metrics')
$property.GetSetMethod($true).Invoke($monitor,@(,[SidebarDiagnostics.Monitoring.iMetric[]]@($first,$second)))
$first.Update(80); $second.Update(90)
if (!$monitor.HasAlert) { throw 'Header must alert when a reading is active.' }
$first.Update(20)
if (!$monitor.HasAlert) { throw 'Header must remain alert while the second reading is active.' }
$second.Update(20)
if ($monitor.HasAlert) { throw 'Header must reset only after all readings clear.' }
$monitor.Dispose()
Write-Output 'PASS header aggregates multiple alerts and clears after the last one.'
