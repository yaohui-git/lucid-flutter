# lucid-flutter

一个开源防手机沉迷的工具（游戏）—— **清醒兽 · Lucid**

把「少刷手机」从痛苦的自我控制，变成一场养宠物的养成游戏。刷得越多宠物越虚弱，打开分心 APP 时会自动弹出互动挑战打断下意识动作。

## 核心能力

- ✅ 检测每个 APP 的使用时长（UsageStats）
- ✅ 打开目标 APP（抖音/小红书等）时**自动弹出拦截挑战**
- ✅ 前台常驻通知保活
- ✅ 全部数据存在手机本地，不联网、不上传
- ✅ 宠物养成：5 档状态、6 种进化、成就徽章

## 快速开始

打包需要一台电脑（Windows / macOS / Linux 均可）。先装好 Flutter SDK + Android Studio + JDK 17，然后：

```bash
bash build-apk.sh
```

APK 会生成在 `lucid/build/app/outputs/flutter-apk/app-release.apk`，传到安卓手机安装即可。

**首次使用必做**：在 APP「设置」页开启「使用情况访问权」和「无障碍服务」，并勾选要拦截的 APP。

## 完整文档

- [打包说明.md](打包说明.md) — 环境准备、两种打包方式、3 步授权、常见问题
- [build-apk.sh](build-apk.sh) — 一键打包脚本

## 项目结构

```
source/
├── pubspec.yaml
├── lib/
│   ├── main.dart               # 入口 + 导航
│   ├── core/                   # 状态模型 / 原生通信 / 本地存储
│   ├── widgets/pet_avatar.dart # 自绘宠物动画
│   └── pages/                  # 宠物/拦截/进化/数据/设置 页
└── android/app/src/main/
    ├── AndroidManifest.xml
    └── kotlin/com/lucid/lucid/
        ├── MainActivity.kt
        ├── LucidAccessibilityService.kt
        └── BootReceiver.kt
```

## 隐私

所有数据仅保存在本机，不上传任何服务器。无障碍服务仅检测目标 APP 包名并弹窗，不读取屏幕内容（`canRetrieveWindowContent=false`）。
