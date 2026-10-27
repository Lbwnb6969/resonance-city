$ErrorActionPreference='Stop'
$Root=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location -LiteralPath $Root
$Work=Join-Path $Root 'work\full-native'
New-Item -ItemType Directory -Path $Work -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'FullNativeRecover.java'),(Join-Path $PSScriptRoot 'run_full_native.ps1') -Destination $Work -Force
python (Join-Path $PSScriptRoot 'prepare_full_native.py')
if($LASTEXITCODE -ne 0){throw 'Static inventory failed.'}
& (Join-Path $Work 'run_full_native.ps1') -Stage decode
& (Join-Path $Work 'run_full_native.ps1') -Stage supplement
& (Join-Path $Work 'run_full_native.ps1') -Stage decompile -Workers 8 -Timeout 8
python (Join-Path $PSScriptRoot 'summarize_full_native.py')
if($LASTEXITCODE -ne 0){throw 'Decompiler shard validation failed.'}
& (Join-Path $Work 'run_full_native.ps1') -Stage retry -Workers 1 -Timeout 45
python (Join-Path $PSScriptRoot 'verify_text_bytes.py')
if($LASTEXITCODE -ne 0){throw 'Original byte comparison failed.'}
python (Join-Path $PSScriptRoot 'finalize_full_native.py')
if($LASTEXITCODE -ne 0){throw 'Final coverage validation failed.'}
