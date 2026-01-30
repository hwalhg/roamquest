# Flutter 安装指南 (macOS ARM64)

## 快速安装

### 方法 1: 使用安装脚本（推荐）

```bash
cd /Users/mac/Documents/codes/ai-project/roam_quest
chmod +x install_flutter.sh
./install_flutter.sh
```

### 方法 2: 手动下载

如果网络有问题，请使用国内镜像：

```bash
cd ~/development

# 使用清华大学镜像
curl -O https://mirrors.tuna.tsinghua.edu.cn/flutter/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.27.5-stable.tar.xz

# 或使用腾讯云镜像
curl -O https://mirrors.cloud.tencent.com/flutter/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.27.5-stable.tar.xz

# 解压
tar -xf flutter_macos_arm64_3.27.5-stable.tar.xz
rm flutter_macos_arm64_3.27.5-stable.tar.xz
```

### 方法 3: 浏览器下载

1. 访问: https://flutter.dev/docs/get-started/install/macos
2. 下载 macOS ARM64 版本
3. 解压到 `~/development/flutter`

---

## 配置环境变量

安装完成后，执行：

```bash
# 添加到 PATH
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc

# 重新加载配置
source ~/.zshrc

# 验证安装
flutter --version
```

---

## 运行 flutter doctor

```bash
flutter doctor
```

这会检查所有依赖并提示你需要安装的工具。

---

## 常见问题

### Q: 下载速度慢？
A: 使用国内镜像源（见方法2）

### Q: 提示权限错误？
A: 使用 `sudo` 或确保 `~/development` 目录可写

### Q: arm64 版本不兼容？
A: 你的 Mac 可能是 Intel 芯片，下载 macOS x64 版本

---

## 下一步

安装完成后，回到项目目录：

```bash
cd /Users/mac/Documents/codes/ai-project/roam_quest
flutter pub get
flutter run
```
