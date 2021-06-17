#!/bin/bash
clear

### 基础部分 ###
# 使用 O3 级别的优化
sed -i 's/Os/O3/g' include/target.mk
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
wget https://github.com/QiuSimons/R2S-R4S-X86-OpenWrt/raw/master/PATCH/new/package/use_json_object_new_int64.patch
patch -p1 < ./use_json_object_new_int64.patch

### 获取额外的 LuCI 应用、主题和依赖 ###
# MAC 地址与 IP 绑定
rm -rf ./feeds/luci/applications/luci-app-arpbind
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-arpbind feeds/luci/applications/luci-app-arpbind
# Boost 通用即插即用
rm -rf ./feeds/packages/net/miniupnpd
svn co https://github.com/immortalwrt/packages/trunk/net/miniupnpd feeds/packages/net/miniupnpd
# DNSPod
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-tencentddns package/emortal/luci-app-tencentddns
# FRP 内网穿透
rm -rf ./feeds/luci/applications/luci-app-frps
rm -rf ./feeds/luci/applications/luci-app-frpc
rm -rf ./feeds/packages/net/frp
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-frps feeds/luci/applications/luci-app-frps
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-frpc feeds/luci/applications/luci-app-frpc
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/frp feeds/packages/net/frp
# OpenClash
rm -rf ./feeds/luci/applications/luci-app-openclash
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash feeds/luci/applications/luci-app-openclash
# ServerChan 微信推送
rm -rf ./feeds/luci/applications/luci-app-serverchan
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-serverchan feeds/luci/applications/luci-app-serverchan
# 解锁网易云
rm -rf ./feeds/luci/applications/luci-app-unblockneteasemusic
git clone https://github.com/immortalwrt/luci-app-unblockneteasemusic.git feeds/luci/applications/luci-app-unblockneteasemusic
# 翻译及部分功能优化
svn co https://github.com/QiuSimons/R2S-R4S-X86-OpenWrt/trunk/PATCH/duplicate/addition-trans-zh package/emortal/addition-trans-zh

### 最后的收尾工作 ###
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../SCRIPTS/fuck package/base-files/files/usr/bin/fuck
# 定制化配置
sed -i 's|root:x:0:0:root:/root:/bin/ash|root:x:0:0:root:/root:/bin/bash|g' package/base-files/files/etc/passwd
sed -i "s/'%D %V %C'/'Built by OPoA($(date +%Y.%m.%d))@%D %V %C'/g" package/base-files/files/etc/openwrt_release
sed -i "/%D/a\ Built by OPoA($(date +%Y.%m.%d))" package/base-files/files/etc/banner
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
sed -i "s/openclash.config.enable=0/openclash.config.enable=1/g" feeds/luci/applications/luci-app-openclash/root/etc/uci-defaults/luci-openclash
sed -i '/exit 0/i\echo "/usr/share/unblockneteasemusic/" >> /etc/sysupgrade.conf && cat /etc/sysupgrade.conf | sort | uniq > /tmp/tmp_sysupgrade_conf && cat /tmp/tmp_sysupgrade_conf > /etc/sysupgrade.conf' package/emortal/addition-trans-zh/files/zzz-default-settings
sed -i 's,1608,1800,g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/cpufreq
sed -i 's,2016,2208,g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/cpufreq
#sed -i 's,1512,1608,g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/cpufreq
# 生成默认配置及缓存
rm -rf .config

exit 0
