param(
    [string]$GhidraRoot = 'C:\Users\Administrator\Documents\Codex\2026-10-12\new-chat-2\work\tools\vendor\ghidra-12.1.4\ghidra_12.1.4_PUBLIC',
    [string]$JdkRoot = 'C:\Users\Administrator\Documents\Codex\2026-10-12\new-chat-2\work\tools\vendor\jdk-21\jdk-21.0.12.1+1',
    [string]$Target = 'D:\steamtest\steamapps\common\Foundation\foundation.exe'
)
$ErrorActionPreference = 'Stop'
$TaskRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location -LiteralPath $TaskRoot
$NativeWork = Join-Path $TaskRoot 'work\native'
$NativeOutput = Join-Path $TaskRoot 'outputs\foundation-native-analysis'
$ProjectDirectory = Join-Path $NativeWork 'replay-project'
New-Item -ItemType Directory -Path $NativeWork,$ProjectDirectory -Force | Out-Null
$ExpectedSha256 = '2c0a048bc1fa2791f58ea432b85cbd9b816af0efec6d6d1c0be6c12195da31af'
if ((Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedSha256) {
    throw 'Target hash changed; this recorded native profile is for the original Foundation executable.'
}
python (Join-Path $PSScriptRoot 'select_native.py')
if ($LASTEXITCODE -ne 0) { throw 'Native seed selection failed.' }
python (Join-Path $PSScriptRoot 'select_drill.py')
if ($LASTEXITCODE -ne 0) { throw 'Typed reader seed selection failed.' }
python (Join-Path $PSScriptRoot 'select_reads.py')
if ($LASTEXITCODE -ne 0) { throw 'Eight-byte read selection failed.' }
$Functions = Get-Content -LiteralPath (Join-Path $NativeOutput 'pdata-functions.json') -Raw | ConvertFrom-Json
$ExtraAddresses = '0x1401280a0','0x14014ec70','0x140177090','0x140157df0','0x140151b20'
$Selected = $Functions | Where-Object {
    $Address = [Convert]::ToUInt64($_.start.Substring(2),16)
    ($Address -ge 0x140151000 -and $Address -lt 0x140152000) -or $_.start -in $ExtraAddresses
}
$Lines = $Selected | ForEach-Object { $_.start + "`t" + $_.end_exclusive + "`tPackage entry accessor candidate / digest helper" }
[IO.File]::WriteAllLines((Join-Path $NativeWork 'package-drill.tsv'),$Lines,[Text.UTF8Encoding]::new($false))
$env:JAVA_HOME = $JdkRoot
$env:GHIDRA_HEADLESS_MAXMEM = '4G'
$Headless = Join-Path $GhidraRoot 'support\analyzeHeadless.bat'
$ProjectName = 'FoundationFocusedReplay'
$Stages = @(
    @('seeds.tsv','focused-functions.json'),
    @('drill-seeds.tsv','drill-functions.json'),
    @('package-drill.tsv','package-drill-functions.json'),
    @('read8-drill.tsv','read8-functions.json')
)
for ($StageIndex = 0; $StageIndex -lt $Stages.Count; $StageIndex++) {
    $Stage = $Stages[$StageIndex]
    $ArgsList = @($ProjectDirectory,$ProjectName)
    if ($StageIndex -eq 0 -and -not (Test-Path -LiteralPath (Join-Path $ProjectDirectory "$ProjectName.gpr"))) {
        $ArgsList += @('-import',$Target)
    } else { $ArgsList += @('-process','foundation.exe') }
    $ArgsList += @('-noanalysis','-scriptPath',$PSScriptRoot,'-postScript','FocusedNative.java',$NativeWork,$NativeOutput,$Stage[0],$Stage[1],'-log',(Join-Path $NativeWork "replay-$StageIndex.log"))
    & $Headless @ArgsList
    if ($LASTEXITCODE -ne 0) { throw "Ghidra stage $StageIndex failed." }
}
Write-Host 'Static reconstruction complete. Review Ghidra log for FOCUSED_DONE and function JSON for decompile_completed.'
