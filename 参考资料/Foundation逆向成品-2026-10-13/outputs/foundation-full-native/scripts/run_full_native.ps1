param([ValidateSet('decode','supplement','decompile','retry')][string]$Stage='decode',[int]$Workers=8,[int]$Timeout=8,[int]$StartShard=0)
$ErrorActionPreference='Stop'
$ExpectedTargetHash='2c0a048bc1fa2791f58ea432b85cbd9b816af0efec6d6d1c0be6c12195da31af'
if((Get-FileHash -LiteralPath 'D:\steamtest\steamapps\common\Foundation\foundation.exe' -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedTargetHash){throw 'Input identity changed; recorded recovery profile must not be applied to this new binary.'}
$Root=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Out=Join-Path $Root 'outputs\foundation-full-native'
$Project=Join-Path $PSScriptRoot 'ghidra-project'
New-Item -ItemType Directory -Path $Out,$Project -Force | Out-Null
$env:JAVA_HOME='C:\Users\Administrator\Documents\Codex\2026-10-12\new-chat-2\work\tools\vendor\jdk-21\jdk-21.0.12.1+1'
$env:GHIDRA_HEADLESS_MAXMEM='8G'
$Headless='C:\Users\Administrator\Documents\Codex\2026-10-12\new-chat-2\work\tools\vendor\ghidra-12.1.4\ghidra_12.1.4_PUBLIC\support\analyzeHeadless.bat'
$Arguments=@($Project,'FoundationFull')
if($Stage -eq 'decode' -and -not(Test-Path -LiteralPath (Join-Path $Project 'FoundationFull.gpr'))){$Arguments+=@('-import','D:\steamtest\steamapps\common\Foundation\foundation.exe')}
else{$Arguments+=@('-process','foundation.exe')}
$Arguments+=@('-noanalysis','-scriptPath',$PSScriptRoot,'-postScript','FullNativeRecover.java',$PSScriptRoot,$Out,$Stage,$Workers,$Timeout,$StartShard,'-log',(Join-Path $PSScriptRoot "$Stage-headless.log"))
& $Headless @Arguments *> (Join-Path $PSScriptRoot "$Stage-console.log")
if($LASTEXITCODE -ne 0){throw "Ghidra $Stage failed, inspect console."}
