#!/bin/bash
clear

### 基础部分 ###
# 使用 O3 级别的优化
sed -i 's/Os/O3 -funsafe-math-optimizations -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections/g' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

### 必要的 Patches ###
# Patch arm64 型号名称
wget -P target/linux/generic/pending-5.4 https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/target/linux/generic/pending-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# Patch Kernel 以解决 FullCone 冲突
wget -P target/linux/generic/hack-5.4 https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
# Patch Kernel 以支持 Shortcut-FE
wget -P target/linux/generic/hack-5.4 https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
# Patch jsonc
wget -qO- https://github.com/QiuSimons/R2S-R4S-X86-OpenWrt/raw/master/PATCH/jsonc/use_json_object_new_int64.patch | patch -p1
# fix firewall flock
patch -p1 < ../PATCHES/001-fix-firewall-flock.patch
# BBRv2
wget -qO- https://github.com/QiuSimons/R2S-R4S-X86-OpenWrt/raw/master/PATCH/BBRv2/openwrt-kmod-bbr2.patch | patch -p1
wget -P target/linux/generic/hack-5.4 https://github.com/QiuSimons/R2S-R4S-X86-OpenWrt/raw/master/PATCH/BBRv2/693-Add_BBRv2_congestion_control_for_Linux_TCP.patch
# CacULE
wget -qO- https://github.com/QiuSimons/openwrt-NoTengoBattery/commit/7d44cab.patch | patch -p1
wget -qO target/linux/generic/hack-5.4/694-cacule-5.4.patch https://github.com/hamadmarri/cacule-cpu-scheduler/raw/master/patches/CacULE/v5.4/cacule-5.4.patch
# UKSM
wget -P target/linux/generic/hack-5.4 https://github.com/QiuSimons/R2S-R4S-X86-OpenWrt/raw/master/PATCH/UKSM/695-uksm-5.4.patch

### 获取额外的 LuCI 应用、主题和依赖 ###
# MOD Argon
pushd feeds/luci/themes/luci-theme-argon
wget -qO- https://github.com/msylgj/luci-theme-argon/commit/0197576.patch | patch -p1
popd
# MOD TurboACC To Add BBRv2
pushd feeds/luci/applications/luci-app-turboacc
patch -p1 < ../../../../../PATCHES/003-mod-turboacc-switch-bbr-support-to-bbr2.patch
popd
# DNSPod
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-tencentddns feeds/luci/applications/luci-app-tencentddns
ln -sf ../../../feeds/luci/applications/luci-app-tencentddns ./package/feeds/luci/luci-app-tencentddns
# OpenClash
rm -rf feeds/luci/applications/luci-app-openclash
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash feeds/luci/applications/luci-app-openclash
# SSR Plus: add DNSProxy support
rm -rf ./feeds/luci/applications/luci-app-ssr-plus
svn co https://github.com/msylgj/helloworld/branches/dnsproxy-edns/luci-app-ssr-plus feeds/luci/applications/luci-app-ssr-plus
# 翻译及部分功能优化
svn co https://github.com/QiuSimons/OpenWrt-Add/trunk/addition-trans-zh package/emortal/addition-trans-zh
cp -f ../SCRIPTS/zzz-default-settings package/emortal/addition-trans-zh/files/zzz-default-settings
rm -rf package/emortal/addition-trans-zh/status

#Vermagic
latest_version="$(curl -s https://github.com/openwrt/openwrt/releases |grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" |sed -n '/21/p' |sed -n 1p |sed 's/v//g' |sed 's/.tar.gz//g')"
wget https://downloads.openwrt.org/releases/${latest_version}/targets/rockchip/armv8/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' > .vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

### 最后的收尾工作 ###
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../SCRIPTS/fuck package/base-files/files/usr/bin/fuck
# 定制化配置
sed -i "s/'%D %V %C'/'Built by OPoA($(date +%Y.%m.%d))@%D %V'/g" package/base-files/files/etc/openwrt_release
sed -i "/DISTRIB_REVISION/d" package/base-files/files/etc/openwrt_release
sed -i "/%D/a\ Built by OPoA($(date +%Y.%m.%d))" package/base-files/files/etc/banner
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
pushd feeds/luci/applications/luci-app-ssr-plus
sed -i 's,ispip.clang.cn/all_cn,cdn.jsdelivr.net/gh/QiuSimons/Chnroute@master/dist/chnroute/chnroute,' root/etc/init.d/shadowsocksr
sed -i 's,YW5vbnltb3Vz/domain-list-community/release/gfwlist.txt,Loyalsoldier/v2ray-rules-dat/release/gfw.txt,' root/etc/init.d/shadowsocksr
sed -i '/Clang.CN.CIDR/a\o:value("https://cdn.jsdelivr.net/gh/QiuSimons/Chnroute@master/dist/chnroute/chnroute.txt", translate("QiuSimons/Chnroute"))' luasrc/model/cbi/shadowsocksr/advanced.lua
wget -qO- https://github.com/1715173329/ssrplus-routing-rules/raw/master/direct/microsoft.txt | cat > root/etc/ssrplus/white.list
popd
sed -i 's/1608/1800/g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/cpufreq
sed -i 's/2016/2208/g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/cpufreq
#sed -i 's/1512/1608/g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/cpufreq
# 生成默认配置及缓存
rm -rf .config

exit 0
