> **This SwiftBar plugin has been superseded / 本 SwiftBar 插件已被独立版取代** — the standalone app lives in [**NetworkSwitch**](https://github.com/iam-otakun/NetworkSwitch) (macOS and Windows editions together, v2.0.0+). This repository is archived and kept for history only. / 独立版在 [NetworkSwitch](https://github.com/iam-otakun/NetworkSwitch)（macOS 与 Windows 两端同仓，v2.0.0 起）。本仓库已归档，仅作历史留存。

---

# Network Switch — a SwiftBar plugin / 网络切换 SwiftBar 插件

A tiny [SwiftBar](https://github.com/swiftbar/SwiftBar) plugin for macOS that switches the active network connection between **two gateways on the same LAN** with one click from the menu bar. Locations are kept as **Profiles** — take the same Mac home and to the office, and each place has its own pair of gateways.

一个小巧的 macOS [SwiftBar](https://github.com/swiftbar/SwiftBar) 插件：在菜单栏一键切换当前连接的**同网段双网关**。不同地点存为 **Profile**——同一台 Mac 带回家、带到办公室，每个地方有自己的一对网关。

## Why / 为什么做这个

Some networks have two ways out living on the same subnet — for example a campus/office LAN where the default router (`.1`) reaches the local network and the internet directly, while a second box (`.2`, e.g. a bypass router running a proxy) routes traffic through a different exit. macOS has no quick built-in way to flip the gateway and DNS of a connection back and forth. And if you move between two such networks, the gateway pairs differ per place. So this plugin puts the switch in the menu bar, organised by place:

有些网络里，同一个子网住着两个出口——比如学校/办公室局域网：默认路由器（`.1`）直达本地与互联网，另一台盒子（`.2`，例如跑代理的旁路由）则把流量送往另一个出口。macOS 没有现成的快捷方式来回切换一个连接的网关与 DNS；而且人在两个这样的网络之间移动时，每个地方的网关还不一样。于是这个插件把开关放进菜单栏，并按地点组织：

- The menu bar shows the current state as **Profile–Exit**, e.g. `Home-出海` or `Office-直连`. The profile named is the one the measured gateway actually matches; on a network that matches no Profile, it shows just **Unknown**, with no profile name claimed. / 菜单栏以**「Profile 名-出口名」**显示当前状态，如 `Home-出海`、`Office-直连`。所显示的 Profile 是实测网关真正对上的那个；在对不上任何 Profile 的网络上，只显示**「未知」**，不挂任何 Profile 的名字。
- The dropdown lists the **Profiles at the top level**; each Profile opens a submenu with its two exits — **Direct（直连）** and **Overseas（出海）** — each with its own gateway and DNS. Clicking an exit applies it and makes that Profile the current one. / 下拉菜单里 **Profile 是一级菜单**，每个 Profile 的子菜单里是它的两个出口——**直连**与**出海**——各有自己的网关与 DNS。点中某个出口即切换过去，并把该 Profile 定为当前。
- **Add Profile…** in the menu creates a new Profile: a name plus a gateway and a DNS text field for each exit, with IPv4 validation. Each Profile's submenu also carries **Edit** (rename included) and **Delete**. No need to touch the script, ever. / 菜单里的**添加 Profile…**即可新建：一个名字，外加每个出口各一组网关与 DNS 文本框，带 IPv4 格式校验。每个 Profile 的子菜单里还有**编辑**（含改名）与**删除**。永远不用再改脚本。
- **The network service and this Mac's own IP are detected automatically**: the service follows the current default route (Wi-Fi at home, a USB adapter at the office), and switching keeps the IP and subnet mask the Mac already has, changing only the gateway and DNS. The exact same plugin file runs unchanged on every Mac. / **网卡服务与本机 IP 全自动检测**：服务认当前默认路由的那块网卡（家里是 Wi-Fi，办公室是 USB 网卡），切换时沿用本机已有的 IP 与掩码，只改网关与 DNS。同一份插件文件，所有 Mac 原样通用。
- A **Restore DHCP** item puts the connection back to automatic when you want out. / 菜单里有**恢复自动（DHCP）**，想回到全自动时点它。

- A **Proxy** item under the Profiles toggles the macOS system proxy (HTTP, HTTPS and SOCKS together), pointing at the address stored in the config (`APP|PROXY_IP` / `APP|PROXY_PORT`, preset `172.20.10.1` / `7890` — e.g. a phone hotspot sharing Clash Mi). **Edit Proxy Address...** changes the address, and editing while the proxy is on re-points it immediately. Gateway mode and proxy mode are mutually exclusive in both directions: while the Proxy is on, every Profile's exits are greyed out; while the measured gateway matches a Profile exit, the Proxy item is greyed out. Moving between the two modes always passes through the neutral state — **Restore DHCP**, or a network that matches no Profile. / Profile 下面有一个 **Proxy** 菜单项，开关 macOS 系统代理（HTTP、HTTPS、SOCKS 三件套一起），指向配置里存的地址（`APP|PROXY_IP` / `APP|PROXY_PORT`，预设 `172.20.10.1` / `7890`，例如手机个人热点共享的 Clash Mi）；**编辑代理地址…**可改地址，代理开着时改完立即改指新地址。网关模式与代理模式双向互斥：Proxy 开着时，所有 Profile 的出口变灰；实测网关对上某个 Profile 出口时，Proxy 变灰。两种模式之间切换必须经过中立态——**恢复自动（DHCP）**，或换到对不上任何 Profile 的网络。
- Settings are stored in `~/.network-switch.conf`. A v1 config file is migrated automatically into a Profile named `默认`. / 设置保存在 `~/.network-switch.conf`。v1 的老配置会自动迁移为一个名为 `默认` 的 Profile。

Switching asks for an administrator password (via the standard macOS prompt), because changing a network service's gateway/DNS requires privileges.

切换时系统会弹出标准的管理员密码框——修改网络服务的网关/DNS 本就需要提权。

## Install / 安装

1. Install [SwiftBar](https://github.com/swiftbar/SwiftBar). / 安装 [SwiftBar](https://github.com/swiftbar/SwiftBar)。
2. Download `network-switch.10s.sh` into your SwiftBar plugins folder and make it executable:
   把 `network-switch.10s.sh` 放进 SwiftBar 插件目录并赋予执行权限：

   ```
   chmod +x network-switch.10s.sh
   ```

3. Refresh SwiftBar. The menu bar shows `未配置` (not configured). Open the menu, choose **Add Profile…**, and fill in the name and the two exits' gateway/DNS pairs. Done — repeat for each location you move between.
   刷新 SwiftBar，菜单栏会显示`未配置`。打开菜单选**添加 Profile…**，填入名字与两个出口的网关/DNS 即可。每个常去的地点重复一次。

The `.10s.` in the file name is SwiftBar's refresh-interval convention (every 10 seconds), so the menu bar label always reflects the real current gateway.

文件名里的 `.10s.` 是 SwiftBar 的刷新间隔约定（每 10 秒），保证菜单栏显示的始终是真实的当前网关。

## Config file / 配置文件

`~/.network-switch.conf` is plain text, one value per line — easy to inspect or pre-seed by hand:

`~/.network-switch.conf` 是纯文本，一行一个值——便于查看，也可以手工预置：

```
ACTIVE=Home
PROFILE|Home|DIRECT_GW|192.168.52.1
PROFILE|Home|DIRECT_DNS|192.168.52.1
PROFILE|Home|OVERSEAS_GW|192.168.52.2
PROFILE|Home|OVERSEAS_DNS|192.168.52.2
PROFILE|Office|DIRECT_GW|192.168.50.1
PROFILE|Office|DIRECT_DNS|192.168.50.1
PROFILE|Office|OVERSEAS_GW|192.168.50.2
PROFILE|Office|OVERSEAS_DNS|192.168.50.2
APP|PROXY_IP|172.20.10.1
APP|PROXY_PORT|7890
```

The `APP|` lines are shared with the Windows edition (its own settings such as `APP|AUTOSTART` may also live here; this plugin preserves lines it does not own when saving). / `APP|` 行与 Windows 版共用（它自己的设置如 `APP|AUTOSTART` 也存在这个文件里；本插件保存时保留不属于自己的行）。

## Notes / 说明

- The script reads the *actual* current gateway via `networksetup -getinfo` on the auto-detected service — the label never lies about which exit you are on.
  插件在自动检测到的网卡上用 `networksetup -getinfo` 读取**真实**当前网关——标签永远不会骗你现在走的是哪个出口。
- It only ever changes the gateway and DNS of that one service; everything else is untouched.
  它只改那一个网络服务的网关与 DNS，其它一概不动。
- This is the exact script running daily on the author's Macs (a desktop at the office, a laptop that travels), shared in the hope it is useful to someone with the same two-gateways-one-LAN setup.
  这是作者每天在自己机器上实际运行的脚本原样分享（办公室一台、随身一台），希望能帮到同样「一个局域网、两个出口」的人。

## Changelog / 更新日志

- **v2.5** (2026-11-24) — An **About** submenu at the end of the menu (Version, Idea: Otakun, Coding: Dash, and a "GitHub Repository" link) — the unified About rolled out to all our Windows and macOS programs in this round. No functional changes. / 菜单末尾新增 **About** 子菜单（Version、Idea: Otakun、Coding: Dash、一条写着「GitHub Repository」的链接）——本轮统一 About 的一环，与其它 Windows、macOS 程序同一规格。无功能变化。
- **v2.4** (2026-11-24) — Feature parity with the Windows edition v1.2.x. A **Proxy** item toggles the macOS system proxy (HTTP/HTTPS/SOCKS) pointing at the configured address (preset: a phone hotspot's Clash Mi), with **Edit Proxy Address...** beside it; gateway mode and proxy mode are mutually exclusive in both directions, and switching between them passes through the neutral state. The menu-bar state and the checkmarks now follow the measured gateway across **all** Profiles — on a network that matches none, the label is just **Unknown**, with no profile name claimed. Saving the config now preserves `APP|` lines owned by the Windows edition. / 与 Windows 版 v1.2.x 功能对齐。新增 **Proxy** 开关：开关 macOS 系统代理（HTTP/HTTPS/SOCKS）并指向设定地址（预设手机热点的 Clash Mi），旁边有**编辑代理地址…**；网关模式与代理模式双向互斥，切换必过中立态。菜单栏状态与勾选改按实测网关逐个 Profile 匹配——对不上任何 Profile 时只显示**「未知」**，不挂名。保存配置时保留 Windows 版的 `APP|` 行。

- **v2.3** (2026-11-21) — Switching no longer fails silently: if you cancel the administrator password prompt, an alert now says the switch was cancelled and nothing changed; if the privileged command fails for another reason, the alert shows the system's raw error text so the problem can be diagnosed. / 切换失败不再无声无息：在管理员密码框点取消，会弹窗说明已取消、本次没有切换；提权命令因其它原因失败时，弹窗会带出系统原始报错，便于定位问题。
- **v2.2** (2026-11-20) — Bilingual UI that follows the system language: Chinese on Chinese systems, English elsewhere — menu bar title, menus, dialogs and alerts included (`Profile` remains the product term in both languages). Set the `NETSWITCH_LANG` environment variable (`zh`/`en`) to override. Also fixed the exit submenu items rendering blank (a `printf` format beginning with `--` was parsed as options). / 界面双语跟随系统语言：中文系统显示中文，其它显示英文——菜单栏标题、菜单、对话框与提示全覆盖（`Profile` 在两种语言里都是产品术语）；可用环境变量 `NETSWITCH_LANG`（`zh`/`en`）覆盖。另修复出口子菜单项显示空白（`printf` 格式以 `--` 开头被当成选项解析）。

- **v2.1** (2026-11-20) — Plugin UI language unified to Simplified Chinese (plugin title and description; a migrated v1 config's Profile is now named `默认`). / 插件界面文字统一为简体中文（插件标题与说明；v1 老配置迁移出的 Profile 改名为 `默认`）。
- **v2.0.1** (2026-11-20) — Edit Profile now starts with the name field, so a Profile can be renamed (empty and duplicate names are rejected; the active Profile follows the rename). / 编辑 Profile 的第一步改为名称框，Profile 可以改名（空名与重名会被拦下；当前 Profile 会跟随新名）。
- **v2.0** (2026-11-20) — Profiles: each location stores Direct and Overseas gateway/DNS pairs; Profiles are the top-level menu with exits as submenus; add, edit and delete from the menu; network service and local IP detected automatically. / Profile 版：每个地点存直连与出海两组网关/DNS；Profile 为一级菜单、出口为二级；添加、编辑、删除都在菜单里；网卡与本机 IP 自动检测。
- **v1.0** (2026-11-20) — First release: one-click switching between two gateways for a single location. / 首版：单个地点的一键双网关切换。

## Credits / 作者

By **Otakun** ([@iam-otakun](https://github.com/iam-otakun)) and **Dash**, his Muse assistant — idea by Otakun, code by Dash, shared back to the open-source community. The Profiles design and the menu hierarchy (Profiles first, exits second) are Otakun's.

由 **Otakun**（[@iam-otakun](https://github.com/iam-otakun)）与他的 Muse 助手 **Dash** 共同完成——idea 出自 Otakun，代码出自 Dash，分享回开源社区。Profile 的设计与菜单层级（Profile 在前、出口在后）出自 Otakun。

## License / 许可

MIT
