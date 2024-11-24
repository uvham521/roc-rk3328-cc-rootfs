#!/bin/bash
set -e

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_path="${root_path}/build"
tools_path="${root_path}/tools"

echo "Cleaning up..."
rm -rf ${build_path}/boot.vfat
rm -rf ${build_path}/rootfs.ext4

# Tempdir for root
GENIMAGE_ROOT=$(mktemp -d)

# "fake" file so generation is happy
touch ${GENIMAGE_ROOT}/placeholder

# Generate our boot and rootfs disk images
rm -rf /tmp/genimage-initial-tmppath
${tools_path}/genimage-16/genimage                         \
	--rootpath "${GENIMAGE_ROOT}"     \
	--tmppath "/tmp/genimage-initial-tmppath"    \
	--inputpath "${build_path}"  \
	--outputpath "${build_path}" \
	--config "${root_path}/genimage_initial.cfg"

exit 0
