#!/bin/bash
set -e

root_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_path="${root_path}/build"
tools_path="${root_path}/tools"
package_path="${root_path}/package"
output_path="${root_path}/output"

# Tempdir for root
GENIMAGE_ROOT=$(mktemp -d)

# setup and move bits
mkdir -p ${build_path}/final
cp ${build_path}/boot.vfat ${build_path}/final/
cp ${build_path}/rootfs.ext4 ${build_path}/final/
cp ${root_path}/genimage_final.cfg ${build_path}/genimage.cfg

# Update UUID in genimage.cfg to match what u-boot has set
sed -i "s|PLACEHOLDERUUID|$(cat ${build_path}/disk-signature.txt)|g" ${build_path}/genimage.cfg

echo "Generating disk image"
cp ${package_path}/u-boot/rk3328-roc-cc.uboot ${build_path}/final/u-boot.bin

rm -rf /tmp/genimage-initial-tmppath
${tools_path}/genimage-16/genimage \
    --rootpath "${GENIMAGE_ROOT}" \
    --tmppath "/tmp/genimage-initial-tmppath" \
    --inputpath "${build_path}/final" \
    --outputpath "${build_path}/final" \
    --config "${build_path}/genimage.cfg"

mkdir -p ${output_path}
mv ${build_path}/final/sdcard.img ${output_path}/debian-sdcard.img
# gzip ${output_path}/debian-sdcard.img

rm -rf /tmp/genimage-initial-tmppath
