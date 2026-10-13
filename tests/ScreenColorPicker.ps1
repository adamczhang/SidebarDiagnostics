param([string]$OutputDirectory = (Join-Path $PSScriptRoot '../SidebarDiagnostics/bin/Release'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, System.Drawing
$assembly = [Reflection.Assembly]::LoadFrom((Join-Path $OutputDirectory 'SidebarDiagnostics.DynamicHud.exe'))
$type = $assembly.GetType('SidebarDiagnostics.ScreenColorPicker', $true)
$constructor = $type.GetConstructors([Reflection.BindingFlags]'Instance,NonPublic')[0]
$bitmap = [Drawing.Bitmap]::new(2,2)
$bitmap.SetPixel(0,0,[Drawing.Color]::FromArgb(18,52,86))
$picker = $constructor.Invoke(@($bitmap,-100,-200))
$pixels = New-Object byte[] 16
$picker.Content.Source.CopyPixels($pixels,8,0)
if ($pixels[0] -ne 86 -or $pixels[1] -ne 52 -or $pixels[2] -ne 18) { throw 'Capture preview changed the sampled RGB color.' }
if ($null -ne $picker.SelectedColor) { throw 'Picker must start without a selection.' }
$picker.Close()
$bitmap.Dispose()
Write-Output 'PASS lossless screenshot pixels, negative desktop coordinates accepted, initial selection empty.'
