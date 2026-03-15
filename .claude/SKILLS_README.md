# RoamQuest Skills - 高效开发助手

这是 RoamQuest 项目的 Skills 工具集，用于提高开发效率。

## 快速开始

```bash
# 查看所有可用 skills
python3 .claude/roamquest_skills.py

# 在 iOS 模拟器上运行应用
/roamquest.run

# 热重载（当修改代码后）
/roamquest.hot_reload
```

## Flutter 命令

| Skill | 说明 |
|--------|------|
| `/roamquest.run` | 启动 iOS 模拟器并运行应用 |
| `/roamquest.hot_reload` | 热重载（代码修改后）|
| `/roamquest.restart` | 热重启（重置应用状态）|
| `/roamquest.build_ios` | 构建 iOS 应用 |
| `/roamquest.run_test` | 运行 Flutter 测试 |
| `/roamquest.analyze` | 分析代码查找问题 |
| `/roamquest.format` | 格式化 Dart 代码 |
| `/roamquest.fix` | 自动修复代码问题 |
| `/roamquest.doctor` | Flutter 环境检查 |
| `/roamquest.clean` | 清理构建缓存 |
| `/roamquest.install_deps` | 安装依赖 |
| `/roamquest.upgrade_deps` | 升级依赖 |

## 导航命令

| Skill | 说明 |
|--------|------|
| `/roamquest.open_main` | 打开 main.dart 入口文件 |
| `/roamquest.open_home` | 打开首页文件 |
| `/roamquest.find_files` | 查找文件（支持 glob 模式）|
| `/roamquest.grep_code` | 在代码中搜索文本/正则 |
| `/roamquest.show_structure` | 显示项目目录结构 |

## 文档命令

| Skill | 说明 |
|--------|------|
| `/roamquest.open_docs` | 打开项目文档 |

## 使用示例

```bash
# 快速跳转到首页进行修改
/roamquest.open_home

# 查找所有 service 文件
/roamquest.find_files **/*service*.dart

# 搜索所有包含 "TODO" 的代码
/roamquest.grep_code TODO lib/

# 运行代码分析
/roamquest.analyze

# 格式化修改后的代码
/roamquest.format

# 自动修复代码问题
/roamquest.fix
```

## 项目结构

```
lib/
├── core/                    # 核心层
├── data/                    # 数据层
└── features/               # 功能层
```

## 快速参考

### 定位功能问题排查
如果定位不工作，可以：
1. 检查权限：iOS 隐私设置 → 位置服务
2. 检查环境变量：确保 `.env` 文件配置正确
3. 使用真机测试：模拟器位置服务可能不稳定

### 常见开发任务

- 修改 UI：`/roamquest.open_home` → 修改文件 → `/roamquest.format` → `/roamquest.hot_reload`
- 添加功能：找到相关文件 → 实现功能 → `/roamquest.analyze`
- 修复 Bug：`/roamquest.grep_code ERROR` 查找错误 → 修复 → 测试

## 注意事项

1. 修改代码后先使用 `/roamquest.analyze` 检查是否有问题
2. 热重载比完全重启更快，优先使用 `/roamquest.hot_reload`
3. 模拟器启动慢是正常的，耐心等待 20-30 秒
