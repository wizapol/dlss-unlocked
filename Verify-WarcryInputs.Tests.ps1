$ErrorActionPreference = 'Stop'
$root = Join-Path ([IO.Path]::GetTempPath()) ('WarcryInputTests-'+[guid]::NewGuid().ToString('N'))
$inputs = Join-Path $root 'inputs'
New-Item -ItemType Directory -Path $inputs -Force | Out-Null
$file = Join-Path $inputs 'fixture.txt'
Set-Content -LiteralPath $file -Value 'fixture'
$manifest = Join-Path $root 'manifest.json'
$state = @{Schema=1;Approved=$true;Files=@(@{Path='fixture.txt';SHA256=(Get-FileHash -LiteralPath $file).Hash})}
function Save-State { $state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest }
function Expect-Rejection([string]$label) {
    $rejected=$false
    try { & (Join-Path $PSScriptRoot 'Verify-WarcryInputs.ps1') -ManifestFile $manifest -InputDirectory $inputs } catch { $rejected=$true }
    if (!$rejected) { throw ('Expected rejection: '+$label) }
}
Save-State
& (Join-Path $PSScriptRoot 'Verify-WarcryInputs.ps1') -ManifestFile $manifest -InputDirectory $inputs
$state.Approved=$false;Save-State;Expect-Rejection 'unapproved inputs'
$state.Approved=$true;Save-State
Set-Content -LiteralPath $file -Value 'changed';Expect-Rejection 'changed hash'
Set-Content -LiteralPath $file -Value 'fixture'
Set-Content -LiteralPath (Join-Path $inputs 'extra.txt') -Value 'unexpected';Expect-Rejection 'extra input'
$state.Files[0].Path='..\manifest.json';Save-State;Expect-Rejection 'escaping path'
Write-Output 'PASS: approved fixture, unapproved manifest, changed hash, extra input and escaping path. No network or binary execution.'
