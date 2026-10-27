param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$delivery = 'C:\Users\Administrator\Desktop\mIDDLEFILE\Townscaper逆向成品'
$relativeTargets = @(
    'work\tools\vendor\BITFDCE.tmp',
    'work\tools\vendor\ghidra_12.1.4_PUBLIC_20260921.zip',
    'work\tools\vendor\ghidra_parts',
    'work\tools\vendor\jdk-25',
    'work\tools\vendor\jdk21_parts',
    'work\tools\vendor\jdk_parts',
    'work\tools\vendor\OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip',
    'work\tools\vendor\OpenJDK25U-jdk_x64_windows_hotspot_25.0.4.1_1.zip',
    'work\tools\OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip',
    'work\废弃\ghidra_incomplete_20261013',
    'work\asset_pydeps',
    'work\runtime_pydeps',
    'work\__pycache__'
)
$targets = @($relativeTargets | ForEach-Object {
    $absolute = [IO.Path]::GetFullPath((Join-Path $workspace $_))
    if (-not $absolute.StartsWith($workspace + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Target escaped workspace' }
    if (Test-Path -LiteralPath $absolute) {
        $item = Get-Item -LiteralPath $absolute -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing junction: $absolute" }
        $bytes = if ($item.PSIsContainer) { (Get-ChildItem -LiteralPath $absolute -Recurse -File -Force | Measure-Object Length -Sum).Sum } else { $item.Length }
        [pscustomobject]@{ path=$absolute; bytes=[long]$bytes; action='delete-rebuildable-download-or-dependency'; reason='Redundant/failed download, unused JDK25, or reproducible Python package cache; configured Ghidra and JDK21 are retained.' }
    }
})
# This archive was created from the failed download folder, not a saved database.
$redundantArchive = Join-Path $delivery '备份\Ghidra早期未完成项目.zip'
if (Test-Path -LiteralPath $redundantArchive) {
    $targets += [pscustomobject]@{ path=$redundantArchive; bytes=(Get-Item -LiteralPath $redundantArchive).Length; action='delete-redundant-failed-download-archive'; reason='This new archive contains only the failed Ghidra download/parts, no analysis database.' }
}
$project = [IO.Path]::GetFullPath((Join-Path $workspace 'work\ghidra_project21'))
if (Test-Path -LiteralPath $project) {
    $archiveProof = Get-Content -LiteralPath (Join-Path $delivery '数据库归档校验.json') -Raw | ConvertFrom-Json
    $proof = @($archiveProof | Where-Object { $_.source -eq $project -and $_.verified })
    if ($proof.Count -ne 1) { throw 'Missing verified database backup' }
    $archiveHash = (Get-FileHash -LiteralPath $proof[0].archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($archiveHash -ne $proof[0].sha256) { throw 'Database archive hash changed' }
    $targets += [pscustomobject]@{ path=$project; bytes=[long]$proof[0].original_bytes; action='archive-then-remove-uncompressed-duplicate'; reason='All10 original files were hash-verified inside the completed-project ZIP; important data remains in the dedicated backup folder.' }
}
if (-not $Apply) {
    $targets | ConvertTo-Json -Depth 5
    return
}
$configuredPaths = @([Environment]::GetEnvironmentVariable('GHIDRA_INSTALL_DIR','User'),[Environment]::GetEnvironmentVariable('JAVA_HOME','User'))
foreach ($target in $targets) {
    $checked = [IO.Path]::GetFullPath($target.path)
    $allowedWorkspace = $checked.StartsWith($workspace + '\work\', [StringComparison]::OrdinalIgnoreCase)
    $allowedNewArchive = $checked.Equals($redundantArchive,[StringComparison]::OrdinalIgnoreCase)
    if (-not ($allowedWorkspace -or $allowedNewArchive)) { throw "Unexpected target: $checked" }
    foreach ($configured in $configuredPaths) {
        if ($configured -and ($configured.Equals($checked,[StringComparison]::OrdinalIgnoreCase) -or $configured.StartsWith($checked+'\',[StringComparison]::OrdinalIgnoreCase))) { throw 'Refusing configured tool directory' }
    }
    if (Test-Path -LiteralPath $checked) { Remove-Item -LiteralPath $checked -Recurse -Force }
    if (Test-Path -LiteralPath $checked) { throw "Removal failed: $checked" }
}
$total = ($targets | Measure-Object bytes -Sum).Sum
$record = [ordered]@{ timestamp=(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'); workspace=$workspace; delivery=$delivery; targets=$targets; gross_bytes_removed=[long]$total; preserved_database_archive_bytes=500162007; effective_original_workspace_bytes_reclaimed_after_database_archive=[long](($targets | Where-Object { $_.path -ne $redundantArchive } | Measure-Object bytes -Sum).Sum - 500162007); configured_tool_directories_retained=$configuredPaths; policy='Only this task workspace caches/downloads and verified database duplicate were removed; user desktop files, Steam files, existing saves, IDA and configured Ghidra/JDK were retained.' }
$record | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $workspace 'outputs\townscaper_cleanup_record.json') -Encoding utf8
$record | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $delivery '清理记录.json') -Encoding utf8
Write-Output ("Gross bytes removed: " + $total)
Write-Output ("Effective original workspace bytes reclaimed after archive: " + $record.effective_original_workspace_bytes_reclaimed_after_database_archive)
