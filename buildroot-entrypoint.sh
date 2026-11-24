#!/bin/sh
set -eu

# All checkouts and Buildroot output belong to this container, never the host.
: "${BUILDROOT_X86_URL:?Set BUILDROOT_X86_URL to a Git URL containing the pinned commit}"
: "${OVERLAY_X86_URL:?Set OVERLAY_X86_URL to a Git URL containing the pinned commit}"
: "${DISK_IMAGE_X86_URL:?Set DISK_IMAGE_X86_URL to a Git URL containing the pinned commit}"
fetch() {
    name=$1 url=$2 revision=$3
    echo "Fetching $name at $revision"
    git init -q "/work/$name"
    git -C "/work/$name" remote add origin "$url"
    git -C "/work/$name" fetch --depth 1 origin "$revision"
    git -C "/work/$name" checkout -q --detach FETCH_HEAD
    actual=$(git -C "/work/$name" rev-parse HEAD)
    [ "$actual" = "$revision" ] || { echo "Unexpected $name revision: $actual" >&2; exit 1; }
}
fetch firmware https://github.com/OpenIPC/firmware.git 9e6a05287f4fc17d914e621bcf824e89dbcb8b0c
fetch divinus https://github.com/TheDayG0ne/divinus.git 8738c5fa0707c294bb7a4f02ba96b5b8855f2ef7
fetch buildroot-x86 "$BUILDROOT_X86_URL" 6e351e210e97079c83c06ba7a140d889fa96d6f5
fetch overlay-x86 "$OVERLAY_X86_URL" 6ba5eaf42b981e05718490a6f7c69faccd955362
fetch disk-image-x86 "$DISK_IMAGE_X86_URL" 1e357d01650d821cdcea10a34c1ba0fbaea486e8
fetch buildroot https://github.com/buildroot/buildroot.git 4235e198768df7d2696f49f28b090c08fed79954

mkdir -p /work/output/firmware-general
rsync -a /work/firmware/general/ /work/output/firmware-general/
find /work/output/firmware-general -type f \( -name '*.in' -o -name 'Config.in' -o -name '*.mk' -o -name '*.sh' -o -name '*.list' -o -name '*.awk' -o -name 'external.desc' \) -exec sed -i 's/\r$//' {} +
sed -i 's/$(BR2_EXTERNAL)/$(BR2_EXTERNAL_GENERAL_PATH)/g' /work/output/firmware-general/external.mk
chmod +x /work/output/firmware-general/scripts/rootfs_script.sh
printf '%s\n' 'DIVINUS_OVERRIDE_SRCDIR = /work/divinus' > /work/output/local.mk
make -C /work/buildroot O=/work/output BR2_EXTERNAL=/work/output/firmware-general:/work/buildroot-x86 openipc_x86_64_defconfig
make -C /work/buildroot O=/work/output BR2_EXTERNAL=/work/output/firmware-general:/work/buildroot-x86 -j"${JOBS:-2}" all
