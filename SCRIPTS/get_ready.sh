#!/bin/bash

latest_release="$(curl -s https://github.com/openwrt/openwrt/releases |grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" |sed -n '/21/p' |sed -n 1p)"
curl -LO "https://github.com/openwrt/openwrt/archive/${latest_release}"
mkdir openwrt_back
shopt -s extglobW
tar zxvf ${latest_release}  --strip-components 1 -C ./openwrt_back
rm -f ${latest_release}
git clone --single-branch -b openwrt-21.02 https://github.com/immortalwrt/immortalwrt openwrt
rm -f ./openwrt/include/version.mk
rm -f ./openwrt/include/kernel-version.mk
rm -f ./openwrt/package/base-files/image-config.in
cp -f ./openwrt_back/include/version.mk ./openwrt/include/version.mk
cp -f ./openwrt_back/include/kernel-version.mk ./openwrt/include/kernel-version.mk
cp -f ./openwrt_back/package/base-files/image-config.in ./openwrt/package/base-files/image-config.in

exit 0