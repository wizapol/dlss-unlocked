[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ManifestFile,
    [Parameter(Mandatory=$true)][string]$InputDirectory
)
$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath $ManifestFile -Raw | ConvertFrom-Json
if ($manifest.Schema -ne 1 -or $manifest.Approved -ne $true -or !$manifest.Files) {
    throw 'Inputs are not approved. An observed hash is not a security approval.'
}
$root = (Resolve-Path -LiteralPath $InputDirectory).Path.TrimEnd('\')
if ((Get-Item -LiteralPath $root).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Input root cannot be a reparse point.' }
$expected = @{}
foreach ($entry in $manifest.Files) {
    if ([IO.Path]::IsPathRooted($entry.Path) -or $entry.Path.Contains(':')) { throw 'Invalid input path.' }
    $path = [IO.Path]::GetFullPath((Join-Path $root $entry.Path))
    if (!$path.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Input escapes the root.' }
    if ($expected.ContainsKey($path)) { throw 'Duplicate input.' }
    $expected[$path] = $true
    if ($entry.SHA256 -notmatch '^[a-fA-F0-9]{64}$' -or !(Test-Path -LiteralPath $path -PathType Leaf)) { throw 'Missing input or invalid SHA256.' }
    $cursor = Get-Item -LiteralPath $path
    while ($cursor -and $cursor.FullName -ne $root) {
        if ($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse points are not accepted.' }
        $cursor = Get-Item -LiteralPath (Split-Path $cursor.FullName -Parent)
    }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.SHA256) { throw 'Input hash mismatch.' }
}
foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Force) {
    if (!$expected.ContainsKey($file.FullName)) { throw 'Unexpected input file.' }
}
Write-Output ('Verified '+$expected.Count+' approved inputs. Nothing downloaded, loaded or executed.')
