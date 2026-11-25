#!/usr/bin/env bash
# ============================================================
# 清醒兽 · Lucid — 一键打包 APK（复用已有 Android 环境版）
# 适用：已按《Android 构建环境重装清单》配好 JDK17 + Android SDK + Gradle 的电脑
# 用法：把本脚本和 source/ 放同一目录，终端 cd 到该目录后运行：
#   bash build-apk.sh              # 首次联网构建（推荐）
#   bash build-apk.sh --offline    # 复用缓存离线构建（需先联网成功一次）
# 前提：Flutter SDK 已装好（flutter 命令可用），JAVA_HOME / ANDROID_HOME 已设置
# ============================================================
set -e

APP_NAME="lucid"
ORG="com.lucid"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$BASE_DIR/$APP_NAME"
SOURCE_DIR="$BASE_DIR/source"
OFFLINE=0
[ "$1" = "--offline" ] && OFFLINE=1

echo "============================================"
echo "  清醒兽 · Lucid  APK 打包脚本"
echo "============================================"

# 1. 检查前置环境
if ! command -v flutter >/dev/null 2>&1; then
  echo "❌ 未找到 flutter 命令。请先把 Flutter SDK 的 bin 目录加入 PATH。"
  echo "   验证：flutter --version"
  exit 1
fi
if [ -z "$JAVA_HOME" ]; then
  echo "⚠️  未检测到 JAVA_HOME，请先设置指向已有的 JDK 17，例如："
  echo '   export JAVA_HOME="/d/.../.buildtools/jdk/jdk-17.0.20.1+1"'
  exit 1
fi
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
  echo "⚠️  未检测到 ANDROID_HOME，请先设置指向已有的 android-sdk，例如："
  echo '   export ANDROID_HOME="/d/.../.buildtools/android-sdk"'
  exit 1
fi

echo "JAVA_HOME    = $JAVA_HOME"
echo "ANDROID_HOME = ${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
echo "Flutter      = $(flutter --version 2>/dev/null | head -1)"

# 2. 生成 Flutter 骨架（若已存在则跳过）
if [ -d "$PROJECT_DIR" ]; then
  echo "▶ 目录 $APP_NAME 已存在，复用（如需全新构建请先删除它）。"
else
  echo "▶ 生成 Flutter 项目骨架..."
  flutter create --org "$ORG" --project-name "$APP_NAME" --platforms android "$APP_NAME"
fi

# 3. 覆盖源码与原生配置
echo "▶ 覆盖 Dart 源码与原生配置..."
cp -f "$SOURCE_DIR/pubspec.yaml" "$PROJECT_DIR/pubspec.yaml"
cp -rf "$SOURCE_DIR/lib/." "$PROJECT_DIR/lib/"
mkdir -p "$PROJECT_DIR/android/app/src/main/kotlin/com/lucid/lucid"
cp -f "$SOURCE_DIR/android/app/src/main/AndroidManifest.xml" \
      "$PROJECT_DIR/android/app/src/main/AndroidManifest.xml"
cp -f "$SOURCE_DIR/android/app/src/main/kotlin/com/lucid/lucid/"*.kt \
      "$PROJECT_DIR/android/app/src/main/kotlin/com/lucid/lucid/"
mkdir -p "$PROJECT_DIR/android/app/src/main/res/xml" "$PROJECT_DIR/android/app/src/main/res/values"
cp -f "$SOURCE_DIR/android/app/src/main/res/xml/accessibility_service_config.xml" \
      "$PROJECT_DIR/android/app/src/main/res/xml/accessibility_service_config.xml"
cp -f "$SOURCE_DIR/android/app/src/main/res/values/strings.xml" \
      "$PROJECT_DIR/android/app/src/main/res/values/strings.xml"

# 4. 让 Flutter 复用已有的 Android SDK（写 local.properties，路径用正斜杠）
SDK_DIR="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
SDK_POSIX=$(printf '%s' "$SDK_DIR" | sed 's|\\|/|g' | sed 's|^c:|C:|I')
echo "sdk.dir=$SDK_POSIX" > "$PROJECT_DIR/android/local.properties"
echo "▶ 已写入 local.properties → sdk.dir=$SDK_POSIX"

# 5. 离线模式：把骨架的 Gradle/AGP 版本对齐到常见缓存版本（9.6.0 / 9.4.0）
if [ "$OFFLINE" = 1 ]; then
  echo "▶ 离线模式：对齐 Gradle 9.6.0 / AGP 9.4.0（若你的缓存版本不同，请手动改）"
  WRAPPER="$PROJECT_DIR/android/gradle/wrapper/gradle-wrapper.properties"
  if [ -f "$WRAPPER" ]; then
    sed -i.bak -E 's|gradle-[0-9.]+-bin\.zip|gradle-9.6.0-bin.zip|' "$WRAPPER" && rm -f "$WRAPPER.bak"
  fi
  SETTINGS="$PROJECT_DIR/android/settings.gradle.kts"
  if [ -f "$SETTINGS" ]; then
    sed -i.bak -E 's|(com.android.application") version "[0-9.]+|\1 version "9.4.0|' "$SETTINGS" && rm -f "$SETTINGS.bak"
  fi
fi

# 6. 拉依赖 + 打包
cd "$PROJECT_DIR"
echo "▶ 拉取 Flutter 依赖..."
flutter pub get

echo "▶ 开始打包 release APK（首次联网可能较慢）..."
if [ "$OFFLINE" = 1 ]; then
  flutter build apk --release --offline
else
  flutter build apk --release
fi

echo "============================================"
echo "✅ 打包完成！"
echo "APK 路径：$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
echo "安装：adb -s <设备序列号> install -r <上面的APK路径>"
echo "首次使用：APP 设置页开启「使用情况访问权」+「无障碍服务」并勾选目标 APP。"
echo "============================================"
