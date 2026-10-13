# Sidebar Diagnostics Dynamic HUD

Custom version: **3.6.3.14**. Based on ArcadeRenegade/SidebarDiagnostics 3.6.3; the original license and attribution remain in place.

## Using the custom build

Run `SidebarDiagnostics.DynamicHud.exe` from its build folder with the accompanying DLLs. Close the previous instance first. This repository contains source, not an installer.

- General → Horizontal mode: compact two-row metric columns at the selected screen's bottom-left corner, over the taskbar. Horizontal mode does not reserve desktop space.
- Advanced offsets: horizontal mode has separate offsets; positive X moves right and positive Y moves up.
- Advanced → Toolbar Mode: omit the HUD from Alt+Tab.
- Always on top unchecked: horizontal mode yields to a foreground fullscreen window on its screen, then returns when fullscreen ends. Fullscreen YouTube behavior was user-verified locally.
- Customize → Heading color: independent color for headings and icons.
- Pick… next to each color: sample a screen pixel; click to select, Esc/right-click to cancel, then Apply or Save. Sampling freezes the desktop image in memory; it is not written to disk. Live multi-monitor/mixed-DPI eyedropper behavior has not been fully verified.

The background fits the content. Horizontal rates use decimal bytes/second for both drives and network, with early unit promotion and fixed-width readings. GPU columns recognize known integrated/dedicated product names and fall back to `GPU` for unknown adapters. Drive letters appear in column headings.

## Alerts

Activity thresholds are currently fixed in code: utilization above 65%, individual drive read/write above 1 GB/s, and individual network incoming/outgoing above 50 MB/s. RAM Used/Free also use the RAM utilization sensor. Comparisons use unrounded readings and decimal rate thresholds.

The affected column pulses three times over 1.5 seconds using the customizable Alert Font Color. The triggering readings and the column heading remain in that color until the alerts clear. Existing temperature, capacity, and bandwidth thresholds remain supported. Activity alerts do not continuously blink.

## Build

Requires Windows, Visual Studio Build Tools with managed desktop build tools, .NET Framework 4.7.2 targeting pack/SDK, and a .NET SDK for LibreHardwareMonitor.

```powershell
git submodule update --init --recursive
msbuild SidebarDiagnostics.sln /restore /p:RestorePackagesConfig=true /p:Configuration=Release /p:TargetFrameworks=net472 /p:GeneratePackageOnBuild=false
```

The executable is under `SidebarDiagnostics/bin/Release`. The custom executable uses its own settings directory, separate from the original SidebarDiagnostics executable.

## Regression checks

After building, run from the repository root:

```powershell
Get-ChildItem tests/*.ps1 | ForEach-Object {
    powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "Failed: $($_.Name)" }
}
```

Each script accepts `-OutputDirectory` for builds in another folder. Checks cover layout, colors, numeric formatting, alert boundaries, header aggregation, pulse keyframes, fullscreen geometry, and screenshot pixel preservation. They are not a substitute for live desktop UI tests. The legacy dependency tree still produces compiler and package audit warnings; dependency modernization is not part of this fork's HUD changes.
