#!/usr/bin/env bash
# ============================================================
# 清醒兽 · Lucid — 一键打包 APK 脚本
# 用法：在项目目录外新建一个空目录，把本脚本和 source/ 放进去，运行：
#   bash build-apk.sh
# 前提：已安装 Flutter SDK（3.x）并配置好 Android SDK + JDK 17
# ============================================================
set -e

APP_NAME="lucid"
ORG="com.lucid"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)/$APP_NAME"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)/source"

echo "============================================"
echo "  清醒兽 · Lucid  APK 打包脚本"
echo "============================================"

# 1. 检查 flutter
if ! command -v flutter >/dev/null 2>&1; then
  echo "❌ 未找到 flutter 命令，请先安装 Flutter SDK 并加入 PATH"
  exit 1
fi

# 2. 生成 Flutter 骨架（若已存在则跳过）
if [ -d "$PROJECT_DIR" ]; then
  echo "⚠️  目录 $PROJECT_DIR 已存在，将复用。"
else
  echo "▶ 生成 Flutter 项目骨架..."
  flutter create --org "$ORG" --project-name "$APP_NAME" --platforms android "$APP_NAME"
fi

# 3. 覆盖源码
echo "▶ 覆盖 Dart 源码与原生配置..."
cp -f "$SOURCE_DIR/pubspec.yaml" "$PROJECT_DIR/pubspec.yaml"
cp -rf "$SOURCE_DIR/lib/." "$PROJECT_DIR/lib/"

# 覆盖原生 Kotlin / Manifest / 资源
mkdir -p "$PROJECT_DIR/android/app/src/main/kotlin/com/lucid/lucid"
cp -f "$SOURCE_DIR/android/app/src/main/AndroidManifest.xml" \
      "$PROJECT_DIR/android/app/src/main/AndroidManifest.xml"
cp -f "$SOURCE_DIR/android/app/src/main/kotlin/com/lucid/lucid/"*.kt \
      "$PROJECT_DIR/android/app/src/main/kotlin/com/lucid/lucid/"
cp -f "$SOURCE_DIR/android/app/src/main/res/xml/accessibility_service_config.xml" \
      "$PROJECT_DIR/android/app/src/main/res/xml/accessibility_service_config.xml" 2>/dev/null || \
  { mkdir -p "$PROJECT_DIR/android/app/src/main/res/xml"; \
    cp -f "$SOURCE_DIR/android/app/src/main/res/xml/accessibility_service_config.xml" \
          "$PROJECT_DIR/android/app/src/main/res/xml/accessibility_service_config.xml"; }
cp -f "$SOURCE_DIR/android/app/src/main/res/values/strings.xml" \
      "$PROJECT_DIR/android/app/src/main/res/values/strings.xml"

# 4. 拉取依赖
echo "▶ 拉取 Flutter 依赖..."
cd "$PROJECT_DIR"
flutter pub get

# 5. 打包
echo "▶ 开始打包 release APK（首次可能较慢）..."
flutter build apk --release

echo "============================================"
echo "✅ 打包完成！"
echo "APK 路径：$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
echo "把它传到安卓手机安装即可。"
echo "============================================"
