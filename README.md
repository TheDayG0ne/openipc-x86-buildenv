# OpenIPC x86: experimental build environment

This repository builds the experimental x86 Buildroot kernel and ext4 root filesystem in Docker. It does **not** produce a bootable disk image. `overlay-x86` and `disk-image-x86` are fetched as pinned source inputs for inspection, but are not integrated into this build. The disk image tool requires a squashfs root filesystem and a compatible early init; this build produces ext4 instead. Do not flash the output to a physical disk. UVC, RTSP, boot, persistence and security are not validated; isolate experiments from untrusted networks. x264 includes GPL code.

## Prerequisites and one-command build

On Windows, install Docker Desktop with the Linux engine, Git and PowerShell. Docker needs network access and substantial free disk space (tens of GB); Docker storage may reside on a different drive. On other hosts the Dockerfile and entrypoint can be used directly; the convenience script is PowerShell. Clone this repository and, from its directory, set these **required Git URLs** to repositories that serve the exact commits listed below. No remotes were configured for these three projects in the source workspace; no published locations are assumed. Publish or otherwise provide these commits before attempting a clean-machine build. The Git server must allow fetching the commits by SHA. Private repositories require appropriate Docker-build/container network authentication, which is not configured here; do not put credentials in URLs, since Docker retains container configuration.

```powershell
$env:BUILDROOT_X86_URL = 'https://your-git-server/your-buildroot-x86.git'
$env:OVERLAY_X86_URL = 'https://your-git-server/your-overlay-x86.git'
$env:DISK_IMAGE_X86_URL = 'https://your-git-server/your-disk-image-x86.git'
# Optional: $env:JOBS = '4'
./build.ps1
```

Each invocation uses a uniquely named image and container, with sources and output inside the container's Linux filesystem. It never mounts or edits existing checkouts, volumes, or host build directories; concurrent invocations are independent, subject to available resources. On success `bzImage` and `rootfs.ext4` are copied to a new `artifacts-<random-id>` directory next to the script and the container is removed. The uniquely tagged builder image remains. On failure, the container (if created) remains for diagnosis; the error reports its name. Inspect it with `docker logs <name>` and remove it with `docker rm <name>` only when no longer needed. Remove the corresponding uniquely tagged image explicitly when desired. No automatic Docker-wide pruning is performed.

## Source lock

The entrypoint fetches and verifies these exact Git commit IDs in fresh checkouts. Local uncommitted changes are intentionally excluded.

| Source | URL | Commit |
| --- | --- | --- |
| firmware | https://github.com/OpenIPC/firmware.git | `9e6a05287f4fc17d914e621bcf824e89dbcb8b0c` |
| Divinus | https://github.com/TheDayG0ne/divinus.git | `8738c5fa0707c294bb7a4f02ba96b5b8855f2ef7` |
| buildroot-x86 | `BUILDROOT_X86_URL` | `6e351e210e97079c83c06ba7a140d889fa96d6f5` |
| overlay-x86 | `OVERLAY_X86_URL` | `6ba5eaf42b981e05718490a6f7c69faccd955362` |
| disk-image-x86 | `DISK_IMAGE_X86_URL` | `1e357d01650d821cdcea10a34c1ba0fbaea486e8` |
| Buildroot 2024.02.10 | https://github.com/buildroot/buildroot.git | `4235e198768df7d2696f49f28b090c08fed79954` |

These are source pins, not a guarantee of bit-identical output: the Debian base image and apt packages are not pinned, and Buildroot fetches additional packages and toolchain sources from the network. Availability and hashes of those downloads depend on the pinned Buildroot/package definitions. Git SHA verification is not publisher authentication; independently verify sources and use trusted URLs. The Divinus pin excludes local modifications and may lack UVC functionality expected by the external tree. Firmware's GENERAL tree is copied and adapted privately for multiple external trees; the full embedded firmware overlay is not applied. There is no installer or configured persistent overlay.

## Checks

Run `powershell -NoProfile -File ./tests/static.ps1` for offline checks of the source lock and safety conventions. A full test requires the three accessible repositories, Docker and network; run `./build.ps1`, check both output files are nonempty, and test only in a disposable VM after arranging a suitable bootloader and kernel `root=`. This does not validate disk-image or overlay integration. A successful build alone does not establish bootability or hardware support.
