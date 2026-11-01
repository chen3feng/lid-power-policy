# lid-power-policy

插电时合盖继续运行，电池时合盖立即休眠。用一个小型 LaunchDaemon 按电源状态自动切换 macOS 的全局 `SleepDisabled` 开关。

## 背景

macOS 的 `pmset disablesleep` 是一个**全局**开关，`pmset -b/-c` 不能给它分别设置电池/插电两套值；而 `caffeinate` 对合盖睡眠并不可靠。所以要让“插电才合盖不休眠”，只能监听电源状态并动态切换。

## 行为

| 电源 | `SleepDisabled` | 合盖后 |
| --- | --- | --- |
| 插电 | `1` | 不休眠，继续下载/跑任务（内屏关闭） |
| 电池 | `0` | 立即睡眠 |

电池模式下建议配合 `sudo pmset -b hibernatemode 25`：睡眠时把内存写入磁盘并切断内存供电，合盖后几乎不耗电，开盖恢复现场。本工具不修改该设置，需要自行确认：

```bash
pmset -g custom | grep hibernatemode
```

## 目录结构

```
lid-power-policy/
├── README.md
├── install.sh                    # 安装
├── uninstall.sh                  # 卸载
├── status.sh                     # 查看状态
├── lid-power-policy.sh           # 实际执行策略的脚本
└── local.lid-power-policy.plist  # LaunchDaemon 定义
```

安装后文件位置：

- `/usr/local/sbin/lid-power-policy.sh`
- `/Library/LaunchDaemons/local.lid-power-policy.plist`

## 安装

```bash
git clone https://github.com/chen3feng/lid-power-policy.git
cd lid-power-policy
sudo ./install.sh
```

安装脚本会先把 `disablesleep` 置为 `0`（安全默认），再安装并加载守护进程。

## 验证

```bash
./status.sh
```

插电时应看到 `SleepDisabled 1`；拔掉电源后等 5~10 秒，应变为 `0`。也可以手动触发一次：

```bash
sudo /usr/local/sbin/lid-power-policy.sh
```

查看 launchd 状态：

```bash
sudo launchctl print system/local.lid-power-policy
```

## 卸载

```bash
sudo ./uninstall.sh
```

卸载会停止守护进程、删除安装的文件，并把 `disablesleep` 恢复为 `0`。

## 配置

- **轮询间隔**：修改 `local.lid-power-policy.plist` 里的 `StartInterval`（秒），默认 `5`，然后重新运行 `sudo ./install.sh`。
- **电池休眠深度**：`sudo pmset -b hibernatemode 25`（推荐）。`0` 是普通睡眠，长期合盖仍会缓慢掉电。
- **日志**：`/var/log/lid-power-policy.log`，正常情况下为空。

## 关于“长时间后关机”

这台机器（M1 Pro）不支持 `autopoweroff` / `standbydelay*`，macOS 没有原生的“睡眠 N 小时后自动关机”。`hibernatemode 25` 在睡眠瞬间就写盘并给内存断电，效果比“等一段时间再关”更省电，而且保留所有窗口和程序；代价是唤醒慢几秒。若确实要彻底断电且不保留会话，手动关机即可。

## 限制与注意

- 5 秒轮询，电源切换后最多约 5 秒才生效；拔电时如果盖子已经合上，脚本会立即 `pmset sleepnow`。
- 睡眠中插电不会自动唤醒，仍保持休眠，开盖恢复。
- 插电合盖跑任务时注意散热，不要把插着电、合着盖的机器闷在包里。
- 需要 root 安装；仅支持 macOS。
- 如果系统升级后 launchd 报错，可尝试旧写法：`sudo launchctl load -w /Library/LaunchDaemons/local.lid-power-policy.plist`。
