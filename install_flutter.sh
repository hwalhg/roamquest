#!/bin/bash

# Flutter 安装脚本
# 请在终端中执行此脚本

set -e

echo "🚀 开始安装 Flutter..."

# 创建开发目录
echo "📁 创建开发目录..."
mkdir -p ~/development
cd ~/development

# 检查是否已安装
if [ -d "flutter" ]; then
    echo "✅ Flutter 已安装在 ~/development/flutter"
    echo "请运行以下命令配置环境变量："
    echo ""
    echo "  echo 'export PATH=\"\$PATH:\$HOME/development/flutter/bin\"' >> ~/.zshrc"
    echo "  source ~/.zshrc"
    echo ""
    exit 0
fi

echo "⏳ 正在下载 Flutter SDK (约 1GB)..."
echo "这可能需要几分钟，请耐心等待..."

# 尝试多种下载方式
if command -v wget >/dev/null 2>&1; then
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.27.5-stable.tar.xz -O flutter.tar.xz
elif command -v curl >/dev/null 2>&1; then
    curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.27.5-stable.tar.xz -o flutter.tar.xz
else
    echo "❌ 错误: 需要 curl 或 wget 来下载 Flutter"
    exit 1
fi

echo "📦 解压 Flutter SDK..."
tar -xf flutter.tar.xz
rm flutter.tar.xz

echo "✅ Flutter 安装完成！"
echo ""
echo "请运行以下命令配置环境变量："
echo ""
echo "  echo 'export PATH=\"\$PATH:\$HOME/development/flutter/bin\"' >> ~/.zshrc"
echo "  source ~/.zshrc"
echo ""
echo "然后验证安装："
echo "  flutter doctor"
echo ""
