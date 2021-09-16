#!/bin/bash

latest_release="$(curl -s https://github.com/openwrt/openwrt/releases |grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" |sed -n '/21/p' |sed -n 1p |sed 's/.tar.gz//g')"
git clone --single-branch -b ${latest_release} https://github.com/openwrt/openwrt openwrt_back
git clone -b openwrt-21.02 --depth 1 https://github.com/immortalwrt/immortalwrt openwrt
rm -f ./openwrt/include/version.mk
rm -f ./openwrt/include/kernel-version.mk
rm -f ./openwrt/package/base-files/image-config.in
pushd openwrt/target/linux/
rm -rf `ls | egrep -v '(rockchip)'`
popd
rm -rf ./openwrt_back/target/linux/rockchip
cp -f ./openwrt_back/include/version.mk ./openwrt/include/version.mk
cp -f ./openwrt_back/include/kernel-version.mk ./openwrt/include/kernel-version.mk
cp -f ./openwrt_back/package/base-files/image-config.in ./openwrt/package/base-files/image-config.in
cp -rf ./openwrt_back/target/linux/* ./openwrt/target/linux/
rm -rf ./openwrt_back

exit 0