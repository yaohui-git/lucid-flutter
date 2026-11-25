#!/usr/bin/env bash
# ============================================================
# 一键推送到 GitHub — 在你自己电脑上执行
# 前提：已安装 git，且本机已配置 GitHub 凭据（ gh auth login 或 HTTPS token ）
# 用法：解压本仓库后，在此目录执行  bash 一键推送.sh
# ============================================================
set -e

REPO_URL="https://github.com/yaohui-git/lucid-flutter.git"
BRANCH="main"

echo "============================================"
echo "  推送清醒兽源码到 GitHub"
echo "  目标：$REPO_URL"
echo "============================================"

# 若当前目录已是 git 仓库且带 origin，直接推送
if git remote get-url origin >/dev/null 2>&1; then
  echo "▶ 检测到已配置远程仓库，直接推送..."
  git remote set-url origin "$REPO_URL"
else
  echo "▶ 关联远程仓库..."
  git remote add origin "$REPO_URL"
fi

echo "▶ 推送到 $BRANCH 分支..."
git push -u origin "$BRANCH" --force

echo "============================================"
echo "✅ 推送完成！"
echo "查看：https://github.com/yaohui-git/lucid-flutter"
echo "============================================"
