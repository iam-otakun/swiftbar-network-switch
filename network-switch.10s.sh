#!/bin/bash
# <xbar.title>Network Switch</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Otakun and Dash</xbar.author>
# <xbar.author.github>iam-otakun</xbar.author.github>
# <xbar.desc>Switches a wired connection between two gateways on the same LAN (for example a school network and an overseas bypass router) from the menu bar, with editable gateway and DNS settings for each mode.</xbar.desc>
# <xbar.dependencies>bash</xbar.dependencies>
# <xbar.abouturl>https://github.com/iam-otakun/swiftbar-network-switch</xbar.abouturl>
# SwiftBar 插件：办公室 Mac 网络切换（学校网络 / 出海系统）
# 菜单栏显示当前模式，悬停显示网关与 DNS；菜单里可切换、可设置两套网关/DNS
# 有线网卡 en7，服务名 USB 10/100/1G/2.5G LAN，IP 固定 192.168.50.10
# 配置文件：~/.network-switch.conf

SERVICE="USB 10/100/1G/2.5G LAN"
IP="192.168.50.10"
MASK="255.255.255.0"
CONF="$HOME/.network-switch.conf"

# 默认值（无配置文件时）
SCHOOL_GW="192.168.50.1"
SCHOOL_DNS="192.168.50.1"
OVERSEAS_GW="192.168.50.2"
OVERSEAS_DNS="192.168.50.2"
[ -f "$CONF" ] && . "$CONF"

do_switch() {
  # $1=网关 $2=DNS
  osascript -e "do shell script \"/usr/sbin/networksetup -setmanual '$SERVICE' $IP $MASK $1 && /usr/sbin/networksetup -setdnsservers '$SERVICE' $2\" with administrator privileges" >/dev/null 2>&1
}

do_settings() {
  OUT=$(osascript - "$SCHOOL_GW" "$SCHOOL_DNS" "$OVERSEAS_GW" "$OVERSEAS_DNS" <<'APPLESCRIPT'
on run argv
  set gw1 to text returned of (display dialog "学校网络 · 网关" default answer (item 1 of argv) with title "网络切换 · 设置" buttons {"取消", "下一步"} default button "下一步")
  set dns1 to text returned of (display dialog "学校网络 · DNS" default answer (item 2 of argv) with title "网络切换 · 设置" buttons {"取消", "下一步"} default button "下一步")
  set gw2 to text returned of (display dialog "出海系统 · 网关" default answer (item 3 of argv) with title "网络切换 · 设置" buttons {"取消", "下一步"} default button "下一步")
  set dns2 to text returned of (display dialog "出海系统 · DNS" default answer (item 4 of argv) with title "网络切换 · 设置" buttons {"取消", "保存"} default button "保存")
  return gw1 & linefeed & dns1 & linefeed & gw2 & linefeed & dns2
end run
APPLESCRIPT
  ) || return 0
  GW1=$(echo "$OUT" | sed -n '1p')
  DNS1=$(echo "$OUT" | sed -n '2p')
  GW2=$(echo "$OUT" | sed -n '3p')
  DNS2=$(echo "$OUT" | sed -n '4p')
  for V in "$GW1" "$DNS1" "$GW2" "$DNS2"; do
    if ! echo "$V" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
      osascript -e 'display alert "设置未保存" message "有地址格式不对，应为 IPv4 形式，例如 192.168.50.1。"' >/dev/null 2>&1
      return 0
    fi
  done
  {
    echo "SCHOOL_GW=\"$GW1\""
    echo "SCHOOL_DNS=\"$DNS1\""
    echo "OVERSEAS_GW=\"$GW2\""
    echo "OVERSEAS_DNS=\"$DNS2\""
  } > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
}

case "$1" in
  school)   do_switch "$SCHOOL_GW" "$SCHOOL_DNS"; exit 0 ;;
  overseas) do_switch "$OVERSEAS_GW" "$OVERSEAS_DNS"; exit 0 ;;
  settings) do_settings; exit 0 ;;
  quit)     osascript -e 'tell application "SwiftBar" to quit'; exit 0 ;;
esac

GW=$(networksetup -getinfo "$SERVICE" | awk -F': ' '/^Router:/{print $2}')
DNS=$(networksetup -getdnsservers "$SERVICE" | head -1)
case "$DNS" in
  *"aren't any"*) DNS="$GW（DHCP）" ;;
esac

if [ "$GW" = "$SCHOOL_GW" ]; then
  MODE="学校网络"; SHORT="学校"
elif [ "$GW" = "$OVERSEAS_GW" ]; then
  MODE="出海系统"; SHORT="出海"
else
  MODE="未知"; SHORT="网络"
fi

echo "$SHORT | tooltip=\"当前：$MODE，网关 $GW，DNS $DNS\""
echo "---"
echo "当前：$MODE（网关 $GW，DNS $DNS）"
echo "---"
echo "学校网络（网关 $SCHOOL_GW，DNS $SCHOOL_DNS） | bash=\"$0\" param0=school terminal=false refresh=true"
echo "出海系统（网关 $OVERSEAS_GW，DNS $OVERSEAS_DNS） | bash=\"$0\" param0=overseas terminal=false refresh=true"
echo "---"
echo "设置… | bash=\"$0\" param0=settings terminal=false refresh=true"
echo "退出 | bash=\"$0\" param0=quit terminal=false"
