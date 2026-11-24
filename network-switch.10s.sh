#!/bin/bash
# <xbar.title>网络切换 / Network Switch</xbar.title>
# <xbar.version>v2.5</xbar.version>
# <xbar.author>Otakun and Dash</xbar.author>
# <xbar.author.github>iam-otakun</xbar.author.github>
# <xbar.desc>Switch the active network connection between two gateways on the same LAN from the menu bar. Locations are kept as Profiles, each storing a gateway and DNS for its Direct and Overseas exits; Profiles can be added, edited (rename included), deleted and selected from the menu. The network service and this Mac's own IP are detected automatically. UI language follows the system. 在菜单栏一键切换当前网络的出口：同一局域网内的两个网关之间切换。地点存为 Profile，每个 Profile 各存直连与出海两组网关和 DNS，添加、编辑（含改名）、删除、选用都在菜单里完成。网卡与本机 IP 自动检测，界面语言跟随系统。</xbar.desc>
# <xbar.dependencies>bash</xbar.dependencies>
# <xbar.abouturl>https://github.com/iam-otakun/swiftbar-network-switch</xbar.abouturl>
# SwiftBar 插件：网络切换 v2（Profile 版）
# 菜单栏显示「Profile名-出口名」，如 Home-出海、Office-直连
# 每个 Profile 存两组网关/DNS：直连、出海；菜单里可添加/编辑/删除/选用 Profile
# 网卡服务与本机 IP 自动检测：认当前默认路由的网卡，切换时沿用当前 IP 与掩码
# 配置文件：~/.network-switch.conf（v1 老配置会自动迁移为名为「默认」的 Profile）
# v2.5：菜单末尾新增 About 子菜单（Version、Idea: Otakun、Coding: Dash、GitHub Repository 链接），与其它 Windows/macOS 程序统一规格
# v2.4：状态与勾选改按实测网关逐个 Profile 匹配（对不上只显示「未知」）；新增 Proxy 开关
# （系统代理指向设定地址，预设手机热点 Clash Mi），与网关模式双向互斥、切换必过中立态

CONF="$HOME/.network-switch.conf"

# ---------- 界面语言：跟随系统（中文系统用中文，其它用英文）；环境变量 NETSWITCH_LANG 可覆盖 ----------
if [ -n "$NETSWITCH_LANG" ]; then
  case "$NETSWITCH_LANG" in zh*) UI=zh ;; *) UI=en ;; esac
else
  LANG1=$(defaults read -g AppleLanguages 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"')
  [ -z "$LANG1" ] && LANG1=$(defaults read -g AppleLocale 2>/dev/null)
  case "$LANG1" in zh*) UI=zh ;; *) UI=en ;; esac
fi
if [ "$UI" = zh ]; then
  L_DIRECT="直连"; L_OVERSEAS="出海"; L_UNKNOWN="未知"; L_GW="网关"
  L_AUTO="自动（DHCP）"; L_DHCP="恢复自动（DHCP）"; L_QUIT="退出"; L_ABOUT="关于"
  L_EDIT="编辑此 Profile…"; L_DEL="删除此 Profile…"; L_ADD="添加 Profile…"
  L_NOTCONF="未配置"; L_NOTCONF_TIP="还没有任何 Profile"; L_NOTCONF_LINE="还没有 Profile，先添加一个"
  L_TIP_FMT='当前：%s-%s，网关 %s，DNS %s，网卡 %s（%s）'
  L_STATUS_FMT='当前：%s-%s（网关 %s，DNS %s）'
  L_EXIT_FMT='%s（网关 %s，DNS %s）'
  L_LBL_FMT='「%s」%s · %s'
  L_DLG_TITLE="网络切换 · Profile"
  L_NAME_PROMPT="Profile 名称（例如 Home、Office）"
  L_CANCEL="取消"; L_NEXT="下一步"; L_SAVE="保存"; L_DELETE_BTN="删除"
  L_SWITCH_FAIL="切换失败"; L_NO_IP_FMT='当前网卡（%s）没有 IP 地址，无法切换。'
  L_SWITCH_CANCELLED="在密码框点了取消，本次没有切换。"
  L_SWITCH_ERR_FMT='切换命令执行失败，网络没有改动。系统报错：%s'
  L_NOT_SAVED="未保存"; L_NOT_ADDED="未添加"; L_CANT_DELETE="不能删除"
  L_BAD_IP="有地址格式不对，应为 IPv4 形式，例如 192.168.1.1。"
  L_NAME_EMPTY="Profile 名称不能为空。"
  L_NAME_PIPE="Profile 名称不能包含 | 字符。"
  L_NAME_EXISTS_FMT='已经有一个叫「%s」的 Profile 了。'
  L_KEEP_ONE="至少要保留一个 Profile。"
  L_DEL_Q_FMT='删除 Profile「%s」？'
  L_PROXY="Proxy"; L_EDIT_PROXY="编辑代理地址…"
  L_STATUS_UNKNOWN_FMT='当前：未知（网关 %s，DNS %s）'
  L_TIP_UNKNOWN_FMT='当前：未知，网关 %s，DNS %s，网卡 %s（%s）'
  L_PROXY_TITLE="网络切换 · 代理"
  L_PROXY_IP_PROMPT="代理 IP（例如手机热点的 172.20.10.1）"
  L_PROXY_PORT_PROMPT="代理端口（例如 7890）"
  L_BAD_PORT="端口应为 1–65535 的数字。"
else
  L_DIRECT="Direct"; L_OVERSEAS="Overseas"; L_UNKNOWN="Unknown"; L_GW="Gateway"
  L_AUTO="Automatic (DHCP)"; L_DHCP="Restore Automatic (DHCP)"; L_QUIT="Quit"; L_ABOUT="About"
  L_EDIT="Edit this Profile..."; L_DEL="Delete this Profile..."; L_ADD="Add Profile..."
  L_NOTCONF="Not Configured"; L_NOTCONF_TIP="No Profiles yet"; L_NOTCONF_LINE="No Profiles yet - add one first"
  L_TIP_FMT='Current: %s-%s, gateway %s, DNS %s, service %s (%s)'
  L_STATUS_FMT='Current: %s-%s (gateway %s, DNS %s)'
  L_EXIT_FMT='%s (gateway %s, DNS %s)'
  L_LBL_FMT='%s - %s - %s'
  L_DLG_TITLE="Network Switch - Profile"
  L_NAME_PROMPT="Profile name (e.g. Home, Office)"
  L_CANCEL="Cancel"; L_NEXT="Next"; L_SAVE="Save"; L_DELETE_BTN="Delete"
  L_SWITCH_FAIL="Switch Failed"; L_NO_IP_FMT='The current service (%s) has no IP address, so switching is not possible.'
  L_SWITCH_CANCELLED="Cancelled at the password prompt - nothing was switched."
  L_SWITCH_ERR_FMT='The switch command failed, so the network was left unchanged. System error: %s'
  L_NOT_SAVED="Not Saved"; L_NOT_ADDED="Not Added"; L_CANT_DELETE="Cannot Delete"
  L_BAD_IP="One of the addresses is not in IPv4 form, e.g. 192.168.1.1."
  L_NAME_EMPTY="The Profile name cannot be empty."
  L_NAME_PIPE="The Profile name cannot contain the | character."
  L_NAME_EXISTS_FMT='A Profile named %s already exists.'
  L_KEEP_ONE="At least one Profile must remain."
  L_DEL_Q_FMT='Delete the Profile %s?'
  L_PROXY="Proxy"; L_EDIT_PROXY="Edit Proxy Address..."
  L_STATUS_UNKNOWN_FMT='Current: Unknown (gateway %s, DNS %s)'
  L_TIP_UNKNOWN_FMT='Current: Unknown, gateway %s, DNS %s, service %s (%s)'
  L_PROXY_TITLE="Network Switch - Proxy"
  L_PROXY_IP_PROMPT="Proxy IP (e.g. 172.20.10.1, a phone hotspot)"
  L_PROXY_PORT_PROMPT="Proxy port (e.g. 7890)"
  L_BAD_PORT="The port must be a number between 1 and 65535."
fi

# ---------- 配置 ----------
# 格式：
#   ACTIVE=Home
#   PROFILE|Home|DIRECT_GW|192.168.52.1
#   PROFILE|Home|DIRECT_DNS|192.168.52.1
#   PROFILE|Home|OVERSEAS_GW|192.168.52.2
#   PROFILE|Home|OVERSEAS_DNS|192.168.52.2

P_NAMES=()
P_DGW=()
P_DDNS=()
P_OGW=()
P_ODNS=()
ACTIVE=""
PROXY_IP="172.20.10.1"
PROXY_PORT="7890"

conf_get() { # $1=Profile 名 $2=键名
  awk -F'|' -v n="$1" -v k="$2" '$1=="PROFILE" && $2==n && $3==k {print $4; exit}' "$CONF" 2>/dev/null
}

save_conf() {
  {
    echo "# network-switch profiles (v2)"
    echo "ACTIVE=$ACTIVE"
    local i
    for i in "${!P_NAMES[@]}"; do
      echo "PROFILE|${P_NAMES[$i]}|DIRECT_GW|${P_DGW[$i]}"
      echo "PROFILE|${P_NAMES[$i]}|DIRECT_DNS|${P_DDNS[$i]}"
      echo "PROFILE|${P_NAMES[$i]}|OVERSEAS_GW|${P_OGW[$i]}"
      echo "PROFILE|${P_NAMES[$i]}|OVERSEAS_DNS|${P_ODNS[$i]}"
    done
    echo "APP|PROXY_IP|$PROXY_IP"
    echo "APP|PROXY_PORT|$PROXY_PORT"
    # 其它 APP| 行（如 Windows 版的 AUTOSTART/AUTOUPDATE）原样保留，不误删
    if [ -f "$CONF" ]; then
      grep '^APP|' "$CONF" 2>/dev/null | grep -v '^APP|PROXY_IP|' | grep -v '^APP|PROXY_PORT|' || true
    fi
  } > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
}

load_conf() {
  P_NAMES=(); P_DGW=(); P_DDNS=(); P_OGW=(); P_ODNS=(); ACTIVE=""
  [ -f "$CONF" ] || return 0
  # v1 老配置迁移：SCHOOL_* / OVERSEAS_* -> 名为「默认」的 Profile
  if ! grep -q '^PROFILE|' "$CONF" && grep -q '^SCHOOL_GW=' "$CONF"; then
    SCHOOL_GW=""; SCHOOL_DNS=""; OVERSEAS_GW=""; OVERSEAS_DNS=""
    . "$CONF"
    ACTIVE="默认"
    P_NAMES=("默认")
    P_DGW=("$SCHOOL_GW"); P_DDNS=("$SCHOOL_DNS")
    P_OGW=("$OVERSEAS_GW"); P_ODNS=("$OVERSEAS_DNS")
    save_conf
    return 0
  fi
  ACTIVE=$(grep '^ACTIVE=' "$CONF" | head -1 | cut -d= -f2-)
  local names name i found
  names=$(grep '^PROFILE|' "$CONF" | cut -d'|' -f2 | uniq)
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    P_NAMES+=("$name")
    P_DGW+=("$(conf_get "$name" DIRECT_GW)")
    P_DDNS+=("$(conf_get "$name" DIRECT_DNS)")
    P_OGW+=("$(conf_get "$name" OVERSEAS_GW)")
    P_ODNS+=("$(conf_get "$name" OVERSEAS_DNS)")
  done <<EOF
$names
EOF
  # ACTIVE 不在列表中时回落到第一个 Profile
  found=0
  for i in "${!P_NAMES[@]}"; do
    [ "${P_NAMES[$i]}" = "$ACTIVE" ] && found=1
  done
  [ "$found" = 0 ] && ACTIVE="${P_NAMES[0]}"
  # 代理地址（与 Windows 版共用 APP|PROXY_IP / APP|PROXY_PORT），缺省用预设值
  local pip pport
  pip=$(grep '^APP|PROXY_IP|' "$CONF" 2>/dev/null | head -1 | cut -d'|' -f3)
  pport=$(grep '^APP|PROXY_PORT|' "$CONF" 2>/dev/null | head -1 | cut -d'|' -f3)
  [ -n "$pip" ] && PROXY_IP="$pip"
  [ -n "$pport" ] && PROXY_PORT="$pport"
}

idx_of() { # $1=Profile 名，输出下标，不存在则 -1
  local i
  for i in "${!P_NAMES[@]}"; do
    if [ "${P_NAMES[$i]}" = "$1" ]; then echo "$i"; return 0; fi
  done
  echo -1
}

active_idx() {
  idx_of "$ACTIVE"
}

name_exists() {
  local i
  for i in "${!P_NAMES[@]}"; do
    [ "${P_NAMES[$i]}" = "$1" ] && return 0
  done
  return 1
}

# ---------- 网络检测 ----------

detect_service() {
  local iface svc
  iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')
  if [ -n "$iface" ]; then
    svc=$(networksetup -listnetworkserviceorder 2>/dev/null | awk -v dev="$iface" '
      /^\([0-9]+\) / { line=$0; sub(/^\([0-9]+\) /, "", line); name=line }
      /Device:/ { if (index($0, "Device: " dev ")")) { print name; exit } }
    ')
  fi
  if [ -z "$svc" ]; then
    if networksetup -listallnetworkservices 2>/dev/null | grep -qx 'Wi-Fi'; then
      svc="Wi-Fi"
    else
      svc=$(networksetup -listallnetworkservices 2>/dev/null | sed -n '2p')
    fi
  fi
  echo "$svc"
}

info_field() { # $1=服务名 $2=字段名（如 Router）
  networksetup -getinfo "$1" 2>/dev/null | awk -F': ' -v f="$2" '$1==f {print $2; exit}'
}

proxy_is_on() { # $1=服务名；系统代理已启用且正指向设定地址才算「开」（与 Windows 版口径一致）
  local out srv port
  out=$(networksetup -getwebproxy "$1" 2>/dev/null)
  echo "$out" | grep -q '^Enabled: Yes' || return 1
  srv=$(echo "$out" | awk -F': ' '$1=="Server" {print $2; exit}')
  port=$(echo "$out" | awk -F': ' '$1=="Port" {print $2; exit}')
  [ "$srv" = "$PROXY_IP" ] && [ "$port" = "$PROXY_PORT" ]
}

alert() { # $1=标题 $2=正文
  osascript -e "display alert \"$1\" message \"$2\"" >/dev/null 2>&1
}

run_priv() { # $1=要提权执行的 shell 命令；失败时弹窗说明，不再静默（取消与其它错误分开提示）
  local out rc
  out=$(osascript -e "do shell script \"$1\" with administrator privileges" 2>&1)
  rc=$?
  if [ $rc -ne 0 ]; then
    case "$out" in
      *"User canceled"*|*"User cancelled"*) alert "$L_SWITCH_FAIL" "$L_SWITCH_CANCELLED" ;;
      *) alert "$L_SWITCH_FAIL" "$(printf "$L_SWITCH_ERR_FMT" "$out")" ;;
    esac
    return 1
  fi
  return 0
}

valid_ip() {
  echo "$1" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

# ---------- 动作 ----------

do_switch() { # $1=网关 $2=DNS
  local svc ip mask
  svc=$(detect_service)
  ip=$(info_field "$svc" "IP address")
  mask=$(info_field "$svc" "Subnet mask")
  if [ -z "$ip" ] || [ -z "$mask" ]; then
    alert "$L_SWITCH_FAIL" "$(printf "$L_NO_IP_FMT" "$svc")"
    return 0
  fi
  run_priv "/usr/sbin/networksetup -setmanual '$svc' $ip $mask $1 && /usr/sbin/networksetup -setdnsservers '$svc' $2"
}

do_dhcp() {
  local svc
  svc=$(detect_service)
  run_priv "/usr/sbin/networksetup -setdhcp '$svc' && /usr/sbin/networksetup -setdnsservers '$svc' Empty"
}

do_proxy() { # 开关系统代理：开=HTTP/HTTPS/SOCKS 三件套都指向设定地址并启用；关=三件套全关
  local svc
  svc=$(detect_service)
  if proxy_is_on "$svc"; then
    run_priv "/usr/sbin/networksetup -setwebproxystate '$svc' off && /usr/sbin/networksetup -setsecurewebproxystate '$svc' off && /usr/sbin/networksetup -setsocksfirewallproxystate '$svc' off"
  else
    run_priv "/usr/sbin/networksetup -setwebproxy '$svc' $PROXY_IP $PROXY_PORT && /usr/sbin/networksetup -setsecurewebproxy '$svc' $PROXY_IP $PROXY_PORT && /usr/sbin/networksetup -setsocksfirewallproxy '$svc' $PROXY_IP $PROXY_PORT && /usr/sbin/networksetup -setwebproxystate '$svc' on && /usr/sbin/networksetup -setsecurewebproxystate '$svc' on && /usr/sbin/networksetup -setsocksfirewallproxystate '$svc' on"
  fi
}

ask_proxy_field() { # $1=默认值 $2=提示语；取消时返回非 0
  osascript - "$1" "$2" "$L_PROXY_TITLE" "$L_CANCEL" "$L_SAVE" <<'APPLESCRIPT'
on run argv
  set v to text returned of (display dialog (item 2 of argv) default answer (item 1 of argv) with title (item 3 of argv) buttons {(item 4 of argv), (item 5 of argv)} default button (item 5 of argv))
  return v
end run
APPLESCRIPT
}

edit_proxy() { # 改代理地址并存盘；代理正开着时立即改指新地址（与 Windows 版口径一致）
  local svc was_on new_ip new_port
  svc=$(detect_service)
  was_on=0; proxy_is_on "$svc" && was_on=1
  new_ip=$(ask_proxy_field "$PROXY_IP" "$L_PROXY_IP_PROMPT") || return 0
  new_ip=$(echo "$new_ip" | sed 's/^ *//; s/ *$//')
  if ! valid_ip "$new_ip"; then
    alert "$L_NOT_SAVED" "$L_BAD_IP"
    return 0
  fi
  new_port=$(ask_proxy_field "$PROXY_PORT" "$L_PROXY_PORT_PROMPT") || return 0
  new_port=$(echo "$new_port" | sed 's/^ *//; s/ *$//')
  case "$new_port" in
    ''|*[!0-9]*) alert "$L_NOT_SAVED" "$L_BAD_PORT"; return 0 ;;
  esac
  if [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
    alert "$L_NOT_SAVED" "$L_BAD_PORT"
    return 0
  fi
  PROXY_IP="$new_ip"; PROXY_PORT="$new_port"
  save_conf
  if [ "$was_on" = 1 ]; then
    run_priv "/usr/sbin/networksetup -setwebproxy '$svc' $PROXY_IP $PROXY_PORT && /usr/sbin/networksetup -setsecurewebproxy '$svc' $PROXY_IP $PROXY_PORT && /usr/sbin/networksetup -setsocksfirewallproxy '$svc' $PROXY_IP $PROXY_PORT"
  fi
}

ask_name() { # $1=默认值；取消时返回非 0
  osascript - "$1" "$L_NAME_PROMPT" "$L_DLG_TITLE" "$L_CANCEL" "$L_NEXT" <<'APPLESCRIPT'
on run argv
  set n to text returned of (display dialog (item 2 of argv) default answer (item 1 of argv) with title (item 3 of argv) buttons {(item 4 of argv), (item 5 of argv)} default button (item 5 of argv))
  return n
end run
APPLESCRIPT
}

ask_values() { # $1=Profile 名 $2..$5=直连网关/直连DNS/出海网关/出海DNS 的默认值
  local lbl1 lbl2 lbl3 lbl4
  lbl1=$(printf "$L_LBL_FMT" "$1" "$L_DIRECT" "$L_GW")
  lbl2=$(printf "$L_LBL_FMT" "$1" "$L_DIRECT" "DNS")
  lbl3=$(printf "$L_LBL_FMT" "$1" "$L_OVERSEAS" "$L_GW")
  lbl4=$(printf "$L_LBL_FMT" "$1" "$L_OVERSEAS" "DNS")
  osascript - "$1" "$2" "$3" "$4" "$5" "$L_DLG_TITLE" "$L_CANCEL" "$L_NEXT" "$L_SAVE" "$lbl1" "$lbl2" "$lbl3" "$lbl4" <<'APPLESCRIPT'
on run argv
  set gw1 to text returned of (display dialog (item 10 of argv) default answer (item 2 of argv) with title (item 6 of argv) buttons {(item 7 of argv), (item 8 of argv)} default button (item 8 of argv))
  set dns1 to text returned of (display dialog (item 11 of argv) default answer (item 3 of argv) with title (item 6 of argv) buttons {(item 7 of argv), (item 8 of argv)} default button (item 8 of argv))
  set gw2 to text returned of (display dialog (item 12 of argv) default answer (item 4 of argv) with title (item 6 of argv) buttons {(item 7 of argv), (item 8 of argv)} default button (item 8 of argv))
  set dns2 to text returned of (display dialog (item 13 of argv) default answer (item 5 of argv) with title (item 6 of argv) buttons {(item 7 of argv), (item 9 of argv)} default button (item 9 of argv))
  return gw1 & linefeed & dns1 & linefeed & gw2 & linefeed & dns2
end run
APPLESCRIPT
}

check_values() { # 四个地址逐个验 IPv4 格式，坏则弹窗并返回非 0
  local v
  for v in "$1" "$2" "$3" "$4"; do
    if ! valid_ip "$v"; then
      alert "$L_NOT_SAVED" "$L_BAD_IP"
      return 1
    fi
  done
  return 0
}

add_profile() {
  local name out gw1 dns1 gw2 dns2
  name=$(ask_name "") || return 0
  name=$(echo "$name" | sed 's/^ *//; s/ *$//')
  if [ -z "$name" ]; then
    alert "$L_NOT_ADDED" "$L_NAME_EMPTY"
    return 0
  fi
  case "$name" in
    *"|"*) alert "$L_NOT_ADDED" "$L_NAME_PIPE"; return 0 ;;
  esac
  if name_exists "$name"; then
    alert "$L_NOT_ADDED" "$(printf "$L_NAME_EXISTS_FMT" "$name")"
    return 0
  fi
  out=$(ask_values "$name" "" "" "" "") || return 0
  gw1=$(echo "$out" | sed -n '1p'); dns1=$(echo "$out" | sed -n '2p')
  gw2=$(echo "$out" | sed -n '3p'); dns2=$(echo "$out" | sed -n '4p')
  check_values "$gw1" "$dns1" "$gw2" "$dns2" || return 0
  P_NAMES+=("$name"); P_DGW+=("$gw1"); P_DDNS+=("$dns1"); P_OGW+=("$gw2"); P_ODNS+=("$dns2")
  ACTIVE="$name"
  save_conf
}

edit_profile() { # $1=Profile 名；第一步先改名（可不改），再改两组网关/DNS
  local idx out gw1 dns1 gw2 dns2 old_name new_name
  old_name="$1"
  idx=$(idx_of "$old_name")
  [ "$idx" -ge 0 ] || return 0
  new_name=$(ask_name "$old_name") || return 0
  new_name=$(echo "$new_name" | sed 's/^ *//; s/ *$//')
  if [ -z "$new_name" ]; then
    alert "$L_NOT_SAVED" "$L_NAME_EMPTY"
    return 0
  fi
  case "$new_name" in
    *"|"*) alert "$L_NOT_SAVED" "$L_NAME_PIPE"; return 0 ;;
  esac
  if [ "$new_name" != "$old_name" ] && name_exists "$new_name"; then
    alert "$L_NOT_SAVED" "$(printf "$L_NAME_EXISTS_FMT" "$new_name")"
    return 0
  fi
  out=$(ask_values "$new_name" "${P_DGW[$idx]}" "${P_DDNS[$idx]}" "${P_OGW[$idx]}" "${P_ODNS[$idx]}") || return 0
  gw1=$(echo "$out" | sed -n '1p'); dns1=$(echo "$out" | sed -n '2p')
  gw2=$(echo "$out" | sed -n '3p'); dns2=$(echo "$out" | sed -n '4p')
  check_values "$gw1" "$dns1" "$gw2" "$dns2" || return 0
  P_NAMES[$idx]="$new_name"
  P_DGW[$idx]="$gw1"; P_DDNS[$idx]="$dns1"; P_OGW[$idx]="$gw2"; P_ODNS[$idx]="$dns2"
  [ "$ACTIVE" = "$old_name" ] && ACTIVE="$new_name"
  save_conf
}

del_profile() { # $1=Profile 名
  local idx btn n_names n_dgw n_ddns n_ogw n_odns i
  if [ "${#P_NAMES[@]}" -le 1 ]; then
    alert "$L_CANT_DELETE" "$L_KEEP_ONE"
    return 0
  fi
  local q
  q=$(printf "$L_DEL_Q_FMT" "$1")
  btn=$(osascript -e "button returned of (display dialog \"$q\" with title \"$L_DLG_TITLE\" buttons {\"$L_CANCEL\", \"$L_DELETE_BTN\"} default button \"$L_CANCEL\")") || return 0
  [ "$btn" = "$L_DELETE_BTN" ] || return 0
  idx=$(idx_of "$1")
  n_names=(); n_dgw=(); n_ddns=(); n_ogw=(); n_odns=()
  for i in "${!P_NAMES[@]}"; do
    [ "$i" = "$idx" ] && continue
    n_names+=("${P_NAMES[$i]}"); n_dgw+=("${P_DGW[$i]}"); n_ddns+=("${P_DDNS[$i]}")
    n_ogw+=("${P_OGW[$i]}"); n_odns+=("${P_ODNS[$i]}")
  done
  P_NAMES=("${n_names[@]}"); P_DGW=("${n_dgw[@]}"); P_DDNS=("${n_ddns[@]}")
  P_OGW=("${n_ogw[@]}"); P_ODNS=("${n_odns[@]}")
  [ "$ACTIVE" = "$1" ] && ACTIVE="${P_NAMES[0]}"
  save_conf
}

load_conf

case "$1" in
  switch) # $2=Profile 名 $3=direct|overseas；点中即同时定 Profile 并切换出口
    idx=$(idx_of "$2")
    [ "$idx" -ge 0 ] || exit 0
    ACTIVE="$2"; save_conf
    if [ "$3" = "direct" ]; then
      do_switch "${P_DGW[$idx]}" "${P_DDNS[$idx]}"
    else
      do_switch "${P_OGW[$idx]}" "${P_ODNS[$idx]}"
    fi
    exit 0 ;;
  addprofile)  add_profile;       exit 0 ;;
  editprofile) edit_profile "$2"; exit 0 ;;
  delprofile)  del_profile "$2";  exit 0 ;;
  dhcp)        do_dhcp;      exit 0 ;;
  proxy)       do_proxy;     exit 0 ;;
  editproxy)   edit_proxy;   exit 0 ;;
  quit)        osascript -e 'tell application "SwiftBar" to quit'; exit 0 ;;
esac

# ---------- 菜单渲染 ----------

if [ "${#P_NAMES[@]}" -eq 0 ]; then
  echo "$L_NOTCONF | tooltip=\"$L_NOTCONF_TIP\""
  echo "---"
  echo "$L_NOTCONF_LINE"
  echo "---"
  echo "$L_ADD | bash=\"$0\" param0=addprofile terminal=false refresh=true"
  echo "$L_QUIT | bash=\"$0\" param0=quit terminal=false"
  exit 0
fi

SVC=$(detect_service)
GW=$(info_field "$SVC" "Router")
MYIP=$(info_field "$SVC" "IP address")
DNS=$(networksetup -getdnsservers "$SVC" 2>/dev/null | head -1)
case "$DNS" in
  *"aren't any"*) DNS="$L_AUTO" ;;
esac

# 实测归属：拿真实网关逐个 Profile 匹配（不再只认 ACTIVE 那个），对不上就是未知、不挂名
MATCH_IDX=-1
MATCH_MODE=""
for i in "${!P_NAMES[@]}"; do
  if [ "$GW" = "${P_DGW[$i]}" ]; then
    MATCH_IDX=$i; MATCH_MODE="$L_DIRECT"; break
  fi
  if [ "$GW" = "${P_OGW[$i]}" ]; then
    MATCH_IDX=$i; MATCH_MODE="$L_OVERSEAS"; break
  fi
done

PROXY_ON=0
proxy_is_on "$SVC" && PROXY_ON=1

if [ "$MATCH_IDX" -ge 0 ]; then
  MNAME="${P_NAMES[$MATCH_IDX]}"
  TIP=$(printf "$L_TIP_FMT" "$MNAME" "$MATCH_MODE" "$GW" "$DNS" "$SVC" "$MYIP")
  echo "$MNAME-$MATCH_MODE | tooltip=\"$TIP\""
  echo "---"
  printf "$L_STATUS_FMT\n" "$MNAME" "$MATCH_MODE" "$GW" "$DNS"
else
  TIP=$(printf "$L_TIP_UNKNOWN_FMT" "$GW" "$DNS" "$SVC" "$MYIP")
  echo "$L_UNKNOWN | tooltip=\"$TIP\""
  echo "---"
  printf "$L_STATUS_UNKNOWN_FMT\n" "$GW" "$DNS"
fi
echo "---"
for i in "${!P_NAMES[@]}"; do
  if [ "$i" = "$MATCH_IDX" ]; then
    echo "${P_NAMES[$i]} | checked=true"
  else
    echo "${P_NAMES[$i]}"
  fi
  C1=""; C2=""
  if [ "$i" = "$MATCH_IDX" ]; then
    [ "$MATCH_MODE" = "$L_DIRECT" ] && C1=" checked=true"
    [ "$MATCH_MODE" = "$L_OVERSEAS" ] && C2=" checked=true"
  fi
  DEXIT=$(printf "$L_EXIT_FMT" "$L_DIRECT" "${P_DGW[$i]}" "${P_DDNS[$i]}")
  OEXIT=$(printf "$L_EXIT_FMT" "$L_OVERSEAS" "${P_OGW[$i]}" "${P_ODNS[$i]}")
  if [ "$PROXY_ON" = 1 ]; then
    # 代理模式下两个出口变灰不可选（借道另一台设备的 Clash，本机网关须原样）；编辑/删除不动网络，照常可用
    echo "--$DEXIT | color=#999999$C1"
    echo "--$OEXIT | color=#999999$C2"
  else
    echo "--$DEXIT | bash=\"$0\" param0=switch param1=\"${P_NAMES[$i]}\" param2=direct terminal=false refresh=true$C1"
    echo "--$OEXIT | bash=\"$0\" param0=switch param1=\"${P_NAMES[$i]}\" param2=overseas terminal=false refresh=true$C2"
  fi
  echo "-----"
  echo "--$L_EDIT | bash=\"$0\" param0=editprofile param1=\"${P_NAMES[$i]}\" terminal=false refresh=true"
  echo "--$L_DEL | bash=\"$0\" param0=delprofile param1=\"${P_NAMES[$i]}\" terminal=false refresh=true"
done
echo "---"
if [ "$PROXY_ON" = 1 ]; then
  echo "$L_PROXY | checked=true bash=\"$0\" param0=proxy terminal=false refresh=true"
elif [ "$MATCH_IDX" -ge 0 ]; then
  # 网关模式下 Proxy 变灰：设定里的代理地址属于另一个网络，在这里够不着
  echo "$L_PROXY | color=#999999"
else
  echo "$L_PROXY | bash=\"$0\" param0=proxy terminal=false refresh=true"
fi
echo "$L_EDIT_PROXY | bash=\"$0\" param0=editproxy terminal=false refresh=true"
echo "---"
echo "$L_ADD | bash=\"$0\" param0=addprofile terminal=false refresh=true"
echo "$L_DHCP | bash=\"$0\" param0=dhcp terminal=false refresh=true"
echo "---"
echo "$L_ABOUT"
echo "--Version v2.5"
echo "--Idea: Otakun"
echo "--Coding: Dash"
echo "--GitHub Repository | href=https://github.com/iam-otakun/swiftbar-network-switch"
echo "---"
echo "$L_QUIT | bash=\"$0\" param0=quit terminal=false"
