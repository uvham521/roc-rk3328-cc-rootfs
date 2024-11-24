#!/bin/bash
set -e

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tools_path="${root_path}/tools"
temp_path="${root_path}/.temp"

genimage_src="https://github.com/pengutronix/genimage/releases/download/v16/genimage-16.tar.xz"
genimage_filename="$(basename $genimage_src)"
genimage_repopath="${genimage_filename%.tar.xz}"

echo "Cleaning up..."
rm -rf ${tools_path}/${genimage_filename}
rm -rf ${tools_path}/${genimage_repopath}

echo "Downloading genimage..."
wget ${genimage_src} -O ${tools_path}/${genimage_filename}

echo "Extracting genimage..."
tar -xJf ${tools_path}/${genimage_filename} -C ${tools_path}

echo "Building genimage..."
cd ${tools_path}/${genimage_repopath}
./configure
make

echo "Cleaning up..."
rm -rf ${tools_path}/${genimage_filename}

exit 0
