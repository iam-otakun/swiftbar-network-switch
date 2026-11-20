# Network Switch — a SwiftBar plugin / 网络切换 SwiftBar 插件

A tiny [SwiftBar](https://github.com/swiftbar/SwiftBar) plugin for macOS that switches a wired network connection between **two gateways on the same LAN** with one click from the menu bar.

一个小巧的 macOS [SwiftBar](https://github.com/swiftbar/SwiftBar) 插件：在菜单栏一键切换有线连接的**同网段双网关**。

## Why / 为什么做这个

Some networks have two ways out living on the same subnet — for example a campus/office LAN where the default router (`.1`) reaches the local network and the internet directly, while a second box (`.2`, e.g. a bypass router running a proxy) routes traffic through a different exit. macOS has no quick built-in way to flip the gateway and DNS of a connection back and forth, so this plugin puts the switch in the menu bar:

有些网络里，同一个子网住着两个出口——比如学校/办公室局域网：默认路由器（`.1`）直达本地与互联网，另一台盒子（`.2`，例如跑代理的旁路由）则把流量送往另一个出口。macOS 没有现成的快捷方式来回切换一个连接的网关与 DNS，于是这个插件把开关放进了菜单栏：

- The menu bar shows the current mode at a glance. / 菜单栏直接显示当前模式。
- The dropdown shows the current gateway & DNS, and offers: switch to mode A, switch to mode B, Settings…, Quit. / 下拉菜单显示当前网关与 DNS，并提供：切换到模式 A、切换到模式 B、设置…、退出。
- **Settings…** lets you edit both modes' gateway and DNS in dialogs (with IPv4 validation) — no need to touch the script again. / **设置…** 可在对话框里修改两套网关与 DNS（带 IPv4 格式校验），改完不用再碰脚本。
- Settings are stored in `~/.network-switch.conf`. / 设置保存在 `~/.network-switch.conf`。

Switching asks for an administrator password (via the standard macOS prompt), because changing a network service's gateway/DNS requires privileges.

切换时系统会弹出标准的管理员密码框——修改网络服务的网关/DNS 本就需要提权。

## Install / 安装

1. Install [SwiftBar](https://github.com/swiftbar/SwiftBar). / 安装 [SwiftBar](https://github.com/swiftbar/SwiftBar)。
2. Download `network-switch.10s.sh` into your SwiftBar plugins folder and make it executable:
   把 `network-switch.10s.sh` 放进 SwiftBar 插件目录并赋予执行权限：

   ```
   chmod +x network-switch.10s.sh
   ```

3. Edit the top of the script to match your machine — the network service name, the fixed IP and subnet mask, and the two default gateway/DNS pairs:
   按你的机器修改脚本开头的配置——网络服务名、固定 IP 与子网掩码、两套默认网关/DNS：

   ```bash
   SERVICE="USB 10/100/1G/2.5G LAN"   # as shown in System Settings → Network
   IP="192.168.50.10"                 # this Mac's fixed IP on that service
   MASK="255.255.255.0"
   SCHOOL_GW="192.168.50.1"           # mode A gateway
   SCHOOL_DNS="192.168.50.1"          # mode A DNS
   OVERSEAS_GW="192.168.50.2"         # mode B gateway
   OVERSEAS_DNS="192.168.50.2"        # mode B DNS
   ```

   The variable names (`SCHOOL` / `OVERSEAS`) and the menu labels come from the setup this plugin was born in — a school network and an overseas-exit bypass router. Rename them to whatever your two exits are called.
   变量名（`SCHOOL` / `OVERSEAS`）与菜单文案来自这个插件诞生的场景——学校网络与出海旁路由。你的两个出口叫什么，就改成什么。

4. Refresh SwiftBar. The current mode appears in your menu bar. / 刷新 SwiftBar，菜单栏即显示当前模式。

The `.10s.` in the file name is SwiftBar's refresh-interval convention (every 10 seconds), so the menu bar label always reflects the real current gateway.

文件名里的 `.10s.` 是 SwiftBar 的刷新间隔约定（每 10 秒），保证菜单栏显示的始终是真实的当前网关。

## Notes / 说明

- The script reads the *actual* current gateway via `networksetup -getinfo` — the label never lies about which exit you are on.
  插件用 `networksetup -getinfo` 读取**真实**当前网关——标签永远不会骗你现在走的是哪个出口。
- It only changes the gateway and DNS of the one service named at the top of the script; everything else is untouched.
  它只改脚本开头指定的那一个网络服务的网关与 DNS，其它一概不动。
- This is the exact script running daily on the author's Mac, shared in the hope it is useful to someone with the same two-gateways-one-LAN setup.
  这是作者每天在自己 Mac 上实际运行的脚本原样分享，希望能帮到同样「一个局域网、两个出口」的人。

## Credits / 作者

By **Otakun** ([@iam-otakun](https://github.com/iam-otakun)) and **Dash**, his Muse assistant — idea by Otakun, code by Dash, shared back to the open-source community.

由 **Otakun**（[@iam-otakun](https://github.com/iam-otakun)）与他的 Muse 助手 **Dash** 共同完成——idea 出自 Otakun，代码出自 Dash，分享回开源社区。

## License / 许可

MIT
