# RoamQuest - 开发指南

## 项目概述

**RoamQuest** 是一款城市探索应用，为旅行者生成个性化的"必做"清单。用户可以发现精心策划的体验，通过照片打卡记录回忆，并分享他们城市冒险的精美报告。

## 已完成的核心模块

### ✅ 项目结构
```
roam_quest/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── core/                     # 核心层
│   │   ├── constants/            # 常量配置
│   │   ├── theme/                # 主题样式
│   │   ├── config/               # 配置文件
│   │   └── utils/                # 工具类
│   ├── data/                     # 数据层
│   │   ├── models/               # 数据模型
│   │   └── services/             # 服务层
│   ├── features/                 # 功能层
│   │   ├── home/                 # 首页
│   │   ├── checklist/            # 清单页
│   │   ├── checkin/              # 打卡页
│   │   └── subscription/         # 订阅页 (待开发)
│   └── l10n/                     # 国际化
├── ios/                          # iOS 配置
├── android/                      # Android 配置
├── assets/                       # 资源文件
├── pubspec.yaml                  # 依赖配置
├── .env.example                  # 环境变量模板
└── claude.md                     # 项目说明文档
```

### ✅ 数据模型 (lib/data/models/)

| 文件 | 说明 | 状态 |
|------|------|------|
| `city.dart` | 城市模型 | ✅ 完成 |
| `checklist_item.dart` | 清单项模型 | ✅ 完成 |
| `checklist.dart` | 清单模型 | ✅ 完成 |
| `subscription.dart` | 订阅模型 | ✅ 完成 |

### ✅ 服务层 (lib/data/services/)

| 服务 | 说明 | 状态 |
|------|------|------|
| `location_service.dart` | 定位服务 (Geolocator) | ✅ 完成 |
| `ai_service.dart` | AI 清单生成 (Claude API) | ✅ 完成 |
| `storage_service.dart` | 数据存储 (Supabase) | ✅ 完成 |

### ✅ 功能页面 (lib/features/)

| 页面 | 说明 | 状态 |
|------|------|------|
| `home/home_page.dart` | 首页 - 城市发现 | ✅ 完成 |
| `checklist/checklist_page.dart` | 清单展示页 | ✅ 完成 |
| `checkin/checkin_page.dart` | 照片打卡页 | ✅ 完成 |

### ✅ 主题系统

| 文件 | 说明 | 状态 |
|------|------|------|
| `app_colors.dart` | 颜色定义 | ✅ 完成 |
| `app_text_styles.dart` | 文本样式 | ✅ 完成 |
| `app_theme.dart` | 主题配置 | ✅ 完成 |

### ✅ 国际化

| 语言 | 文件 | 状态 |
|------|------|------|
| 英文 | `app_en.arb` | ✅ 完成 |
| 中文 | `app_zh.arb` | ✅ 完成 |

### ✅ 平台配置

| 平台 | 配置 | 状态 |
|------|------|------|
| iOS | `Info.plist` (权限配置) | ✅ 完成 |
| Android | `AndroidManifest.xml` | ✅ 完成 |

---

## 下一步开发计划

### 优先级 P0 (核心功能)

1. **修复依赖问题**
   - 添加 `equatable` 依赖到 `pubspec.yaml`
   - 运行 `flutter pub get`

2. **完善主入口**
   - 确保 Supabase 正确初始化
   - 添加错误处理

3. **测试核心流程**
   - 定位功能测试
   - AI 生成清单测试
   - 拍照打卡测试

### 优先级 P1 (增强功能)

4. **报告页面** (`features/report/`)
   - 地图可视化 (Mapbox)
   - 照片墙展示
   - 报告导出/分享

5. **订阅功能** (`features/subscription/`)
   - Apple In-App Purchase 集成
   - 订阅状态管理
   - 支付流程

6. **数据持久化**
   - 本地缓存 (SharedPreferences)
   - Supabase 数据库表创建
   - 照片上传功能

### 优先级 P2 (优化体验)

7. **UI/UX 优化**
   - 添加动画效果
   - 加载状态优化
   - 错误提示优化

8. **性能优化**
   - 图片缓存优化
   - 列表滚动优化
   - API 调用优化

9. **多语言支持**
   - 集成 flutter_localizations
   - 动态语言切换
   - RTL 支持 (可选)

---

## 快速开始

### 1. 安装依赖

```bash
cd /Users/mac/Documents/codes/ai-project/roam_quest
flutter pub get
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填入你的 API 密钥
```

需要的环境变量：
- `SUPABASE_URL` - Supabase 项目 URL
- `SUPABASE_ANON_KEY` - Supabase 匿名密钥
- `CLAUDE_API_KEY` - Claude API 密钥
- `MAPBOX_ACCESS_TOKEN` - Mapbox 访问令牌

### 3. 运行应用

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# macOS (开发测试)
flutter run -d macos
```

---

## 开发注意事项

### 代码规范

- 使用 `camelCase` 命名变量和方法
- 使用 `PascalCase` 命名类和类型
- 使用 `snake_case` 命名文件
- 公共 API 添加文档注释

### Git 提交规范

```
feat: 新功能
fix: 修复 bug
refactor: 代码重构
style: 代码格式调整
docs: 文档更新
test: 测试相关
chore: 构建/工具相关
```

### 当前已知问题

1. `equatable` 包未添加到 `pubspec.yaml`
2. Supabase 数据库表未创建
3. 照片上传功能未实现
4. 报告页面未开发

---

## 技术债务

| 项目 | 优先级 | 说明 |
|------|--------|------|
| 添加单元测试 | P2 | 核心服务需要测试覆盖 |
| 错误处理优化 | P1 | 统一错误处理机制 |
| 日志系统 | P2 | 完善日志记录 |
| 性能监控 | P2 | 添加性能追踪 |

---

## API 文档

### Claude API

**端点**: `POST https://api.anthropic.com/v1/messages`

**请求体**:
```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 2048,
  "messages": [{
    "role": "user",
    "content": "<生成清单的 prompt>"
  }]
}
```

**响应**:
```json
{
  "content": [{
    "type": "text",
    "text": "<包含 JSON 的响应>"
  }]
}
```

### Supabase 表结构

**checklists** 表:
```sql
CREATE TABLE checklists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  city_name VARCHAR(100) NOT NULL,
  country VARCHAR(100) NOT NULL,
  country_code VARCHAR(10) NOT NULL,
  latitude DECIMAL NOT NULL,
  longitude DECIMAL NOT NULL,
  language VARCHAR(10) NOT NULL,
  items JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**checkins** 表:
```sql
CREATE TABLE checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  checklist_id UUID REFERENCES checklists(id) ON DELETE CASCADE,
  item_id VARCHAR(100) NOT NULL,
  photo_url TEXT NOT NULL,
  latitude DECIMAL,
  longitude DECIMAL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 联系方式

- 项目文档: `claude.md`
- README: `README.md`
- 问题反馈: GitHub Issues

---

**最后更新**: 2026-01-15
**当前版本**: 1.0.0 (开发中)
