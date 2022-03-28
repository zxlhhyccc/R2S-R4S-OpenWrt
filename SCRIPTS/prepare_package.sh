#!/bin/bash
clear

### 基础部分 ###
# 使用 O3 级别的优化
sed -i 's/Os/O3 -funsafe-math-optimizations -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections/g' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

### 必要的 Patches ###
# offload bug fix
wget -qO - https://github.com/openwrt/openwrt/pull/4849.patch | patch -p1
# TCP performance optimizations backport from linux/net-next
wget -P target/linux/generic/backport-5.4 https://github.com/QiuSimons/YAOF/raw/master/PATCH/backport/695-tcp-optimizations.patch
# introduce "le9" Linux kernel patches
wget -P target/linux/generic/hack-5.4 https://github.com/QiuSimons/YAOF/raw/master/PATCH/backport/695-le9i.patch
# Patch arm64 型号名称
wget -P target/linux/generic/hack-5.4 https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/target/linux/generic/hack-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# Patch Kernel 以解决 FullCone 冲突
wget -P target/linux/generic/hack-5.4 https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
# fullconenat
rm -rf package/kernel/fullconenat
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/openwrt-fullconenat ./package/kernel/fullconenat
pushd package/kernel/fullconenat
wget -qO- https://github.com/QiuSimons/YAOF/raw/master/PATCH/firewall/fullcone6.patch | patch -p2
popd
# Patch Kernel 以支持 Shortcut-FE
wget -P target/linux/generic/hack-5.4 https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
# Patch jsonc
wget -qO- https://github.com/QiuSimons/YAOF/raw/master/PATCH/jsonc/use_json_object_new_int64.patch | patch -p1
# fix firewall flock
patch -p1 < ../PATCHES/001-fix-firewall-flock.patch
# BBRv2
wget -qO- https://github.com/QiuSimons/YAOF/raw/master/PATCH/BBRv2/openwrt-kmod-bbr2.patch | patch -p1
wget -P target/linux/generic/hack-5.4 https://github.com/QiuSimons/YAOF/raw/master/PATCH/BBRv2/693-Add_BBRv2_congestion_control_for_Linux_TCP.patch
# LRNG
svn co https://github.com/QiuSimons/YAOF/trunk/PATCH/LRNG target/linux/generic/hack-5.4/
echo '
CONFIG_LRNG=y
CONFIG_LRNG_JENT=y
' >>./target/linux/generic/config-5.4

### 获取额外的 LuCI 应用、主题和依赖 ###
# MOD Argon
pushd feeds/luci/themes/luci-theme-argon
wget -qO- https://github.com/msylgj/luci-theme-argon/commit/9fe84a8.patch | patch -p1
popd
# MOD TurboACC To Add BBRv2
pushd feeds/luci/applications/luci-app-turboacc
patch -p1 < ../../../../../PATCHES/003-mod-turboacc-switch-bbr-support-to-bbr2.patch
popd
# DNSPod
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-tencentddns feeds/luci/applications/luci-app-tencentddns
ln -sf ../../../feeds/luci/applications/luci-app-tencentddns ./package/feeds/luci/luci-app-tencentddns
# Mosdns
svn co https://github.com/QiuSimons/openwrt-mos/trunk/mosdns package/emortal/mosdns
svn co https://github.com/QiuSimons/openwrt-mos/trunk/luci-app-mosdns package/emortal/luci-app-mosdns
# OpenClash
rm -rf feeds/luci/applications/luci-app-openclash
svn co https://github.com/vernesong/OpenClash/branches/dev/luci-app-openclash feeds/luci/applications/luci-app-openclash
# SSR Plus: add DNSProxy support
rm -rf ./feeds/luci/applications/luci-app-ssr-plus
svn co https://github.com/msylgj/helloworld/branches/dnsproxy-edns/luci-app-ssr-plus feeds/luci/applications/luci-app-ssr-plus
# ServerChan
rm -rf feeds/luci/applications/luci-app-serverchan
git clone -b fix-ip-black --depth 1 https://github.com/msylgj/luci-app-serverchan.git feeds/luci/applications/luci-app-serverchan

#Vermagic
latest_version="$(curl -s https://github.com/openwrt/openwrt/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" | sed -n '/[2-9][0-9]/p' | sed -n 1p | sed 's/v//g' | sed 's/.tar.gz//g')"
wget https://downloads.openwrt.org/releases/${latest_version}/targets/rockchip/armv8/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' >.vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

### 最后的收尾工作 ###
# Lets Fuck
if [ ! -d "package/base-files/files/usr/bin" ]; then
    mkdir package/base-files/files/usr/bin
fi
cp -f ../SCRIPTS/fuck package/base-files/files/usr/bin/fuck
# 定制化配置
sed -i "s/'%D %V %C'/'Built by OPoA($(date +%Y.%m.%d))@%D %V'/g" package/base-files/files/etc/openwrt_release
sed -i "/DISTRIB_REVISION/d" package/base-files/files/etc/openwrt_release
sed -i "/%D/a\ Built by OPoA($(date +%Y.%m.%d))" package/base-files/files/etc/banner
sed -i "/openwrt_banner/d" package/emortal/default-settings/files/99-default-settings
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
pushd feeds/luci/applications/luci-app-ssr-plus
sed -i 's,ispip.clang.cn/all_cn,gh.404delivr.workers.dev/https://github.com/QiuSimons/Chnroute/raw/master/dist/chnroute/chnroute,' root/etc/init.d/shadowsocksr
sed -i 's,YW5vbnltb3Vz/domain-list-community/release/gfwlist.txt,Loyalsoldier/v2ray-rules-dat/release/gfw.txt,' root/etc/init.d/shadowsocksr
sed -i '/Clang.CN.CIDR/a\o:value("gh.404delivr.workers.dev/https://github.com/QiuSimons/Chnroute/raw/master/dist/chnroute/chnroute.txt", translate("QiuSimons/Chnroute"))' luasrc/model/cbi/shadowsocksr/advanced.lua
wget -qO- https://github.com/1715173329/ssrplus-routing-rules/raw/master/direct/microsoft.txt | cat > root/etc/ssrplus/white.list
popd
sed -i 's/1608/1800/g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/cpufreq
sed -i 's/2016/2208/g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/cpufreq
#sed -i 's/1512/1608/g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/cpufreq
# 生成默认配置及缓存
rm -rf .config

# 清理可能因patch存在的冲突文件
find ./ -name *.orig | xargs rm -rf
find ./ -name *.rej | xargs rm -rf

exit 0
