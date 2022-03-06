#!/bin/bash

latest_release="$(curl -s https://github.com/openwrt/openwrt/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" | sed -n '/[2-9][0-9]/p' | sed -n 1p | sed 's/.tar.gz//g')"
git clone --single-branch -b ${latest_release} https://github.com/openwrt/openwrt openwrt_release
git clone -b openwrt-21.02 --depth 1 https://github.com/immortalwrt/immortalwrt openwrt
rm -f ./openwrt/include/version.mk
rm -f ./openwrt/include/kernel.mk
rm -f ./openwrt/include/kernel-version.mk
rm -f ./openwrt/include/toolchain-build.mk
rm -f ./openwrt/include/kernel-defaults.mk
rm -f ./openwrt/package/base-files/image-config.in
pushd openwrt/target/linux/
rm -rf `ls | egrep -v '(rockchip)'`
popd
rm -rf ./openwrt_release/target/linux/rockchip
cp -f ./openwrt_release/include/version.mk ./openwrt/include/version.mk
cp -f ./openwrt_release/include/kernel.mk ./openwrt/include/kernel.mk
cp -f ./openwrt_release/include/kernel-version.mk ./openwrt/include/kernel-version.mk
cp -f ./openwrt_release/include/toolchain-build.mk ./openwrt/include/toolchain-build.mk
cp -f ./openwrt_release/include/kernel-defaults.mk ./openwrt/include/kernel-defaults.mk
cp -f ./openwrt_release/package/base-files/image-config.in ./openwrt/package/base-files/image-config.in
cp -f ./openwrt_release/version ./openwrt/version
cp -f ./openwrt_release/version.date ./openwrt/version.date
cp -rf ./openwrt_release/target/linux/* ./openwrt/target/linux/

exit 0