#!/bin/bash
# <xbar.title>网络切换</xbar.title>
# <xbar.version>v2.1</xbar.version>
# <xbar.author>Otakun and Dash</xbar.author>
# <xbar.author.github>iam-otakun</xbar.author.github>
# <xbar.desc>在菜单栏一键切换当前网络的出口：同一局域网内的两个网关（例如直连的主路由与出海的旁路由）之间切换。地点存为 Profile：每个 Profile 各存直连与出海两组网关和 DNS，Profile 的添加、编辑（含改名）、删除、选用都在菜单里完成。网卡服务与本机 IP 自动检测，同一个插件文件在任何 Mac 上原样可用。</xbar.desc>
# <xbar.dependencies>bash</xbar.dependencies>
# <xbar.abouturl>https://github.com/iam-otakun/swiftbar-network-switch</xbar.abouturl>
# SwiftBar 插件：网络切换 v2（Profile 版）
# 菜单栏显示「Profile名-出口名」，如 Home-出海、Office-直连
# 每个 Profile 存两组网关/DNS：直连、出海；菜单里可添加/编辑/删除/选用 Profile
# 网卡服务与本机 IP 自动检测：认当前默认路由的网卡，切换时沿用当前 IP 与掩码
# 配置文件：~/.network-switch.conf（v1 老配置会自动迁移为名为「默认」的 Profile）

CONF="$HOME/.network-switch.conf"

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

alert() { # $1=标题 $2=正文
  osascript -e "display alert \"$1\" message \"$2\"" >/dev/null 2>&1
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
    alert "切换失败" "当前网卡（$svc）没有 IP 地址，无法切换。"
    return 0
  fi
  osascript -e "do shell script \"/usr/sbin/networksetup -setmanual '$svc' $ip $mask $1 && /usr/sbin/networksetup -setdnsservers '$svc' $2\" with administrator privileges" >/dev/null 2>&1
}

do_dhcp() {
  local svc
  svc=$(detect_service)
  osascript -e "do shell script \"/usr/sbin/networksetup -setdhcp '$svc' && /usr/sbin/networksetup -setdnsservers '$svc' Empty\" with administrator privileges" >/dev/null 2>&1
}

ask_name() { # $1=默认值；取消时返回非 0
  osascript - "$1" <<'APPLESCRIPT'
on run argv
  set n to text returned of (display dialog "Profile 名称（例如 Home、Office）" default answer (item 1 of argv) with title "网络切换 · Profile" buttons {"取消", "下一步"} default button "下一步")
  return n
end run
APPLESCRIPT
}

ask_values() { # $1=Profile 名 $2..$5=直连网关/直连DNS/出海网关/出海DNS 的默认值
  osascript - "$1" "$2" "$3" "$4" "$5" <<'APPLESCRIPT'
on run argv
  set p to item 1 of argv
  set gw1 to text returned of (display dialog "「" & p & "」直连 · 网关" default answer (item 2 of argv) with title "网络切换 · Profile" buttons {"取消", "下一步"} default button "下一步")
  set dns1 to text returned of (display dialog "「" & p & "」直连 · DNS" default answer (item 3 of argv) with title "网络切换 · Profile" buttons {"取消", "下一步"} default button "下一步")
  set gw2 to text returned of (display dialog "「" & p & "」出海 · 网关" default answer (item 4 of argv) with title "网络切换 · Profile" buttons {"取消", "下一步"} default button "下一步")
  set dns2 to text returned of (display dialog "「" & p & "」出海 · DNS" default answer (item 5 of argv) with title "网络切换 · Profile" buttons {"取消", "保存"} default button "保存")
  return gw1 & linefeed & dns1 & linefeed & gw2 & linefeed & dns2
end run
APPLESCRIPT
}

check_values() { # 四个地址逐个验 IPv4 格式，坏则弹窗并返回非 0
  local v
  for v in "$1" "$2" "$3" "$4"; do
    if ! valid_ip "$v"; then
      alert "未保存" "有地址格式不对，应为 IPv4 形式，例如 192.168.1.1。"
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
    alert "未添加" "Profile 名称不能为空。"
    return 0
  fi
  case "$name" in
    *"|"*) alert "未添加" "Profile 名称不能包含 | 字符。"; return 0 ;;
  esac
  if name_exists "$name"; then
    alert "未添加" "已经有一个叫「$name」的 Profile 了。"
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
    alert "未保存" "Profile 名称不能为空。"
    return 0
  fi
  case "$new_name" in
    *"|"*) alert "未保存" "Profile 名称不能包含 | 字符。"; return 0 ;;
  esac
  if [ "$new_name" != "$old_name" ] && name_exists "$new_name"; then
    alert "未保存" "已经有一个叫「$new_name」的 Profile 了。"
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
    alert "不能删除" "至少要保留一个 Profile。"
    return 0
  fi
  btn=$(osascript -e "button returned of (display dialog \"删除 Profile「$1」？\" with title \"网络切换 · Profile\" buttons {\"取消\", \"删除\"} default button \"取消\")") || return 0
  [ "$btn" = "删除" ] || return 0
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
  quit)        osascript -e 'tell application "SwiftBar" to quit'; exit 0 ;;
esac

# ---------- 菜单渲染 ----------

if [ "${#P_NAMES[@]}" -eq 0 ]; then
  echo "未配置 | tooltip=\"还没有任何 Profile\""
  echo "---"
  echo "还没有 Profile，先添加一个"
  echo "---"
  echo "添加 Profile… | bash=\"$0\" param0=addprofile terminal=false refresh=true"
  echo "退出 | bash=\"$0\" param0=quit terminal=false"
  exit 0
fi

idx=$(active_idx)
SVC=$(detect_service)
GW=$(info_field "$SVC" "Router")
MYIP=$(info_field "$SVC" "IP address")
DNS=$(networksetup -getdnsservers "$SVC" 2>/dev/null | head -1)
case "$DNS" in
  *"aren't any"*) DNS="自动（DHCP）" ;;
esac

if [ "$GW" = "${P_DGW[$idx]}" ]; then
  MODE="直连"
elif [ "$GW" = "${P_OGW[$idx]}" ]; then
  MODE="出海"
else
  MODE="未知"
fi

echo "$ACTIVE-$MODE | tooltip=\"当前：$ACTIVE-$MODE，网关 $GW，DNS $DNS，网卡 $SVC（$MYIP）\""
echo "---"
echo "当前：$ACTIVE-$MODE（网关 $GW，DNS $DNS）"
echo "---"
for i in "${!P_NAMES[@]}"; do
  if [ "${P_NAMES[$i]}" = "$ACTIVE" ]; then
    echo "${P_NAMES[$i]} | checked=true"
  else
    echo "${P_NAMES[$i]}"
  fi
  C1=""; C2=""
  if [ "${P_NAMES[$i]}" = "$ACTIVE" ]; then
    [ "$MODE" = "直连" ] && C1=" checked=true"
    [ "$MODE" = "出海" ] && C2=" checked=true"
  fi
  echo "--直连（网关 ${P_DGW[$i]}，DNS ${P_DDNS[$i]}） | bash=\"$0\" param0=switch param1=\"${P_NAMES[$i]}\" param2=direct terminal=false refresh=true$C1"
  echo "--出海（网关 ${P_OGW[$i]}，DNS ${P_ODNS[$i]}） | bash=\"$0\" param0=switch param1=\"${P_NAMES[$i]}\" param2=overseas terminal=false refresh=true$C2"
  echo "-----"
  echo "--编辑此 Profile… | bash=\"$0\" param0=editprofile param1=\"${P_NAMES[$i]}\" terminal=false refresh=true"
  echo "--删除此 Profile… | bash=\"$0\" param0=delprofile param1=\"${P_NAMES[$i]}\" terminal=false refresh=true"
done
echo "---"
echo "添加 Profile… | bash=\"$0\" param0=addprofile terminal=false refresh=true"
echo "恢复自动（DHCP） | bash=\"$0\" param0=dhcp terminal=false refresh=true"
echo "---"
echo "退出 | bash=\"$0\" param0=quit terminal=false"
