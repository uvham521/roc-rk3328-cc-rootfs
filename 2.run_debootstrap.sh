#!/bin/bash
set -e

root_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_path="${root_path}/build"
package_path="${root_path}/package"

boot_loop_dev=""
rootfs_loop_dev=""

# 定义清理函数
cleanup() {
    echo "Cleaning up..."
    # 卸载 /boot 挂载点
    if mountpoint -q ${build_path}/rootfs/boot; then
        sudo umount -l ${build_path}/rootfs/boot || true
    fi
    # 卸载 rootfs 挂载点
    if mountpoint -q ${build_path}/rootfs; then
        sudo umount -l ${build_path}/rootfs || true
    fi
    # 释放 loopback 设备
    if [ -n "${boot_loop_dev}" ]; then
        sudo losetup -d ${boot_loop_dev} || true
    fi
    if [ -n "${rootfs_loop_dev}" ]; then
        sudo losetup -d ${rootfs_loop_dev} || true
    fi
    # 删除构建目录
    rm -rf ${build_path}/rootfs
}

# 捕获脚本退出或中断信号，并执行清理
trap cleanup EXIT

echo "Cleaning up previous runs..."
rm -rf ${build_path}/disk-signature.txt

echo "Mounting generated block files for use with docker..."
# 挂载 loopback 设备
boot_loop_dev=$(sudo losetup -f --show ${build_path}/boot.vfat)
rootfs_loop_dev=$(sudo losetup -f --show ${build_path}/rootfs.ext4)

# 挂载目录
mkdir -p ${build_path}/rootfs
sudo mount -t ext4 ${rootfs_loop_dev} ${build_path}/rootfs
sudo mkdir -p ${build_path}/rootfs/boot
sudo mount -t vfat ${boot_loop_dev} ${build_path}/rootfs/boot

# 删除占位符文件
sudo rm -f ${build_path}/rootfs/placeholder ${build_path}/rootfs/boot/placeholder

# 生成随机磁盘签名
sudo hexdump -n 4 -e '1 "0x%08X" 1 "\n"' /dev/urandom >${build_path}/disk-signature.txt

# 执行 debootstrap 和 chroot
cd ${build_path}/rootfs
sudo debootstrap --no-check-gpg --foreign --arch=arm64 --include=apt-transport-https bookworm ${build_path}/rootfs http://ftp.cn.debian.org/debian
sudo cp /usr/bin/qemu-aarch64-static usr/bin/
sudo chroot ${build_path}/rootfs /debootstrap/debootstrap --second-stage

# Copy over our overlay if we have one
if [[ -d ${root_path}/overlay/ ]]; then
	echo "Applying rootfs overlay"
	sudo cp -R ${root_path}/overlay/* ./
fi

# Apply our disk signature to fstab
UBOOTUUID=$(cat ${build_path}/disk-signature.txt | awk '{print tolower($0)}')
sudo sed -i "s|PLACEHOLDERUUID|${UBOOTUUID:2}|g" ${build_path}/rootfs/etc/fstab

# Hostname
echo "${distrib_name}" | sudo tee ${build_path}/rootfs/etc/hostname >/dev/null
echo "127.0.1.1	${distrib_name}" | sudo tee -a ${build_path}/rootfs/etc/hosts >/dev/null

# Console settings
cat <<EOF | sudo tee ${build_path}/rootfs/debconf.set >/dev/null
console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
EOF

# Copy over kernel goodies
sudo cp -r ${package_path}/kernel ${build_path}/rootfs/root/

# Kick off bash setup script within chroot
sudo cp ${root_path}/bootstrap ${build_path}/rootfs/bootstrap
sudo chroot ${build_path}/rootfs bash /bootstrap
sudo rm ${build_path}/rootfs/bootstrap

# Final cleanup
sudo rm ${build_path}/rootfs/usr/bin/qemu-aarch64-static

echo "All done!"
