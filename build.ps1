$ErrorActionPreference = 'Stop'
foreach ($name in @('BUILDROOT_X86_URL', 'OVERLAY_X86_URL', 'DISK_IMAGE_X86_URL')) {
    if (-not [Environment]::GetEnvironmentVariable($name)) { throw "Set $name to a Git URL containing the pinned commit; see README.md." }
}
$id = [guid]::NewGuid().ToString('N')
$container = "openipc-x86-$id"
$image = "openipc-x86-builder:$id"
$output = Join-Path $PSScriptRoot "artifacts-$id"
function Check-Exit { if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code $LASTEXITCODE. Container, if created: $container" } }
docker build -t $image $PSScriptRoot
Check-Exit
# A fresh container writable layer makes simultaneous builds independent.
docker run --name $container -e BUILDROOT_X86_URL -e OVERLAY_X86_URL -e DISK_IMAGE_X86_URL -e JOBS $image
Check-Exit
New-Item -ItemType Directory -Path $output | Out-Null
docker cp "${container}:/work/output/images/bzImage" $output
Check-Exit
docker cp "${container}:/work/output/images/rootfs.ext4" $output
Check-Exit
docker rm $container | Out-Null
Check-Exit
Write-Host "Artifacts: $output"
