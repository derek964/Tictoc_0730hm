# Tictoc HarmonyOS

Tictoc 的独立 HarmonyOS 原生执行端。工程使用 ArkTS 和 Stage 模型，通过 Screen Time Guard Kit 将应用访问限制交给系统执行，不依赖 Android APK、Android 无障碍服务或普通悬浮窗。

## 当前功能

- 查询并请求 Screen Time Guard Kit 用户授权。
- 使用系统 appPicker 选择受管应用，只保存系统返回的匿名 token；已用于立即限制的 token 会另行记录，避免更换选择后留下无法解除的旧限制。
- 每日停用时段，支持跨午夜及每天重复。
- 每日共享使用额度（1–1440 分钟）。
- 立即限制所选应用、解除 Tictoc 创建的限制。
- 查询 Tictoc 策略数量并显示真实授权状态。
- 6 位管理 PIN；随机盐 + SHA-256 摘要保存于本机 Preferences。
- 5 次 PIN 错误后暂停 30 秒；应用页面正常退到后台时重新锁定管理入口。

## 工程基线

- `compatibleSdkVersion`: HarmonyOS 6.0.2(22)
- `targetSdkVersion`: HarmonyOS 6.0.2(22)
- 设备：Phone、Tablet
- 工程工具：DevEco Studio 6.0.2 Beta1 或与 API 22 兼容的更高版本
- bundleName：`com.derek.tictoc.hm`（请在 AppGallery Connect 填写此值；是否可注册以平台唯一性校验为准）

当前基线来自华为官方 Screen Time Guard Kit 示例的工程结构，原示例采用 Apache License 2.0；本工程保留根目录 `LICENSE`。参考仓库：

<https://gitcode.com/HarmonyOS_Samples/screentimeguard_kit_samplecode_appscontrol_arkts>

## 导入和签名

1. 安装 DevEco Studio 6.0.2 Beta1 或兼容的更新版本，并安装 HarmonyOS 6.0.2/API 22 SDK。
2. 使用 DevEco Studio 打开本目录，等待工程同步。
3. 在 AppGallery Connect 创建 HarmonyOS 应用。若正式应用包名与占位值不同，修改 `AppScope/app.json5` 的 `bundleName`。
4. 在应用的“ACL 权限”中申请 `ohos.permission.MANAGE_SCREEN_TIME_GUARD`。提交真实业务说明、用户授权界面和管控流程材料。
5. ACL 审核通过后重新申请调试或发布 Profile，勾选该受限权限，把证书和 Profile 配置到工程签名。
6. 连接 HarmonyOS 6.0.2 或以上的 Phone/Tablet，运行 entry 模块。

`module.json5` 已声明受限权限，但仅声明权限不能取得能力。未获批或签名 Profile 不包含权限时，系统将返回权限校验失败。

官方流程：

- <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/screentimeguard-permission-application>
- <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/screentimeguard-request-user-auth>

## 首次验证流程

1. 首次打开设置 6 位 PIN。
2. 点击“开启系统守护授权”，在系统页面同意授权。
3. 打开系统应用选择器，选择两个非关键应用。
4. 先测试“立即限制”，确认被选应用出现系统拦截页，再回到 Tictoc 解除。
5. 设置覆盖当前时间的停用区间，验证跨午夜、重启和断网。
6. 设置较短的共享额度，验证额度共同消耗和次日重复。
7. 撤销系统授权，确认 Tictoc 刷新后不再显示已授权。

## 设计边界

- appPicker token 不含包名、应用名称或图标，本应用不会尝试反向解析。
- 系统自带许可应用、Tictoc 自身、其他获授权的管控应用等不一定能被限制。
- 服务范围以官方文档为准；主空间之外、应用分身等场景不作能力承诺。
- API 22 基线没有调用 HarmonyOS 6.1.1/API 24 才提供的 `AppConfig.isSupportAppUninstall`。
- `queryGuardStrategyData` 的当前文档起始版本为 26.0.0，本工程不把它作为 API 22 的使用统计来源。
- PIN 保护应用内的编辑与解除入口，不能取代系统授权机制，也不能阻止恢复出厂等系统操作。

## 目录

```text
entry/src/main/ets/
├─ data/SettingsStore.ets          本地规则、token 与 PIN 凭据
├─ entryability/EntryAbility.ets  应用入口
├─ guard/TictocGuardManager.ets   Screen Time Guard Kit 封装
├─ pages/HomePage.ets             授权、规则和 PIN 界面
└─ security/PinSecurity.ets       PIN 随机盐与摘要校验
```

## 构建

在 DevEco Studio 完成 SDK、签名和 ACL Profile 配置后，可从 IDE 构建 entry 的 debug HAP。命令行环境通常使用项目同步后生成/提供的 hvigorw；本仓库不伪造本机尚不存在的 SDK 路径或签名配置。

构建产物通常位于 `entry/build/default/outputs/default/`，具体文件名以 DevEco Studio 当前版本输出为准。
