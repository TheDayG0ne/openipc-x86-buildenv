#!/bin/sh
set -eu

# Keep both the Buildroot source and output on a Linux filesystem, isolated from
# any other build. /external and /sources are read-only host checkouts.
BR_VERSION=2024.02.10
BR_DIR="/work/buildroot-$BR_VERSION"
for path in /external/configs/openipc_x86_64_defconfig /sources/firmware/general/external.mk /sources/divinus; do
    if [ ! -e "$path" ]; then
        echo "Missing required input: $path" >&2
        exit 1
    fi
done
if [ ! -f "$BR_DIR/Makefile" ]; then
    wget -O "/tmp/buildroot-$BR_VERSION.tar.gz" "https://github.com/buildroot/buildroot/archive/$BR_VERSION.tar.gz"
    tar -xzf "/tmp/buildroot-$BR_VERSION.tar.gz" -C /work
fi
# The upstream GENERAL external.mk assumes a single external tree. Stage a
# private copy and adapt it for the x86 external tree; never alter the checkout.
mkdir -p /work/output/firmware-general
rsync -a --delete /sources/firmware/general/ /work/output/firmware-general/
find /work/output/firmware-general -type f \( -name '*.in' -o -name 'Config.in' -o -name '*.mk' -o -name '*.sh' -o -name '*.list' -o -name '*.awk' -o -name 'external.desc' \) -exec sed -i 's/\r$//' {} +
sed -i 's/$(BR2_EXTERNAL)/$(BR2_EXTERNAL_GENERAL_PATH)/g' /work/output/firmware-general/external.mk
chmod +x /work/output/firmware-general/scripts/rootfs_script.sh
printf '%s\n' 'DIVINUS_OVERRIDE_SRCDIR = /sources/divinus' > /work/output/local.mk
make -C "$BR_DIR" O=/work/output BR2_EXTERNAL=/work/output/firmware-general:/external openipc_x86_64_defconfig
make -C "$BR_DIR" O=/work/output BR2_EXTERNAL=/work/output/firmware-general:/external -j"${JOBS:-2}" all
