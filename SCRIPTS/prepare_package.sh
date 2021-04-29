#!/bin/bash
clear

### 基础部分 ###
# 使用 O3 级别的优化
sed -i 's/Os/O3/g' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

### 必要的 Patches ###
# Patch jsonc
wget -q https://github.com/QiuSimons/R2S-R4S-X86-OpenWrt/raw/master/PATCH/new/package/use_json_object_new_int64.patch
patch -p1 < ./use_json_object_new_int64.patch

### 获取额外的 LuCI 应用、主题和依赖 ###
# Argon 主题
wget -P ./feeds/luci/themes/luci-theme-argon/luasrc/view/themes/argon -N https://github.com/jerrykuku/luci-theme-argon/raw/9fdcfc866ca80d8d094d554c6aedc18682661973/luasrc/view/themes/argon/footer.htm
wget -P ./feeds/luci/themes/luci-theme-argon/luasrc/view/themes/argon -N https://github.com/jerrykuku/luci-theme-argon/raw/9fdcfc866ca80d8d094d554c6aedc18682661973/luasrc/view/themes/argon/header.htm
# MAC 地址与 IP 绑定
rm -rf ./package/lean/luci-app-arpbind
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-arpbind package/lean/luci-app-arpbind
# Boost 通用即插即用
svn co https://github.com/ryohuang/slim-wrt/trunk/slimapps/application/luci-app-boostupnp package/new/luci-app-boostupnp
sed -i 's,api.ipify.org,myip.ipip.net/s,g' ./package/new/luci-app-boostupnp/root/usr/sbin/boostupnp.sh
rm -rf ./feeds/packages/net/miniupnpd
svn co https://github.com/immortalwrt/packages/trunk/net/miniupnpd feeds/packages/net/miniupnpd
# 动态DNS
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-tencentddns package/new/luci-app-tencentddns
# FRP 内网穿透
rm -rf ./feeds/luci/applications/luci-app-frps
rm -rf ./feeds/luci/applications/luci-app-frpc
rm -rf ./feeds/packages/net/frp
rm -f ./package/feeds/packages/frp
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-frps package/lean/luci-app-frps
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-frpc package/lean/luci-app-frpc
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/frp package/lean/frp
# ServerChan 微信推送
rm -rf ./feeds/luci/applications/luci-app-serverchan
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-serverchan feeds/luci/applications/luci-app-serverchan
# 网络唤醒
svn co https://github.com/msylgj/OpenWrt_luci-app/trunk/luci-app-services-wolplus package/new/luci-app-services-wolplus
# 翻译及部分功能优化
svn co https://github.com/QiuSimons/R2S-R4S-X86-OpenWrt/trunk/PATCH/duplicate/addition-trans-zh package/lean/lean-translate

### 最后的收尾工作 ###
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../SCRIPTS/fuck package/base-files/files/usr/bin/fuck
# 最大连接数
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 定制化配置
sed -i "s/'%D %V %C'/'Built by OPoA($(date +%Y.%m.%d))@%D %V %C'/g" package/base-files/files/etc/openwrt_release
sed -i "/%D/a\ Built by OPoA($(date +%Y.%m.%d))" package/base-files/files/etc/banner
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
sed -i "s/openclash.config.enable=0/openclash.config.enable=1/g" feeds/luci/applications/luci-app-openclash/root/etc/uci-defaults/luci-openclash
sed -i 's/+kmod-fast-classifier //g' package/lean/lean-translate/Makefile
sed -i '/exit 0/i\echo "/usr/share/unblockneteasemusic/" >> /etc/sysupgrade.conf && cat /etc/sysupgrade.conf | sort | uniq > /tmp/tmp_sysupgrade_conf && cat /tmp/tmp_sysupgrade_conf > /etc/sysupgrade.conf' package/lean/lean-translate/files/zzz-default-settings
# 生成默认配置及缓存
rm -rf .config

exit 0
