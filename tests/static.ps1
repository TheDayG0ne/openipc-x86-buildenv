$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$entry = Get-Content -Raw (Join-Path $root 'buildroot-entrypoint.sh')
$runner = Get-Content -Raw (Join-Path $root 'build.ps1')
foreach ($sha in @('9e6a05287f4fc17d914e621bcf824e89dbcb8b0c','8738c5fa0707c294bb7a4f02ba96b5b8855f2ef7','6e351e210e97079c83c06ba7a140d889fa96d6f5','6ba5eaf42b981e05718490a6f7c69faccd955362','1e357d01650d821cdcea10a34c1ba0fbaea486e8','4235e198768df7d2696f49f28b090c08fed79954')) {
    if (-not $entry.Contains($sha)) { throw "Missing pin $sha" }
}
foreach ($name in @('BUILDROOT_X86_URL','OVERLAY_X86_URL','DISK_IMAGE_X86_URL')) {
    if (-not $entry.Contains($name) -or -not $runner.Contains($name)) { throw "Missing URL parameter $name" }
}
if ($runner -match 'docker\s+(?:volume\s+(?:rm|prune)|system\s+prune)' -or $runner -match '\s-v\s') { throw 'Unexpected destructive or mounted-volume operation' }
if ($runner -notmatch 'NewGuid' -or $runner -notmatch 'docker cp') { throw 'Expected isolated container and artifact copy' }
Write-Host 'Static checks passed.'
