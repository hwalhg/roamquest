# RoamQuest - 项目开发文档

## 项目概述

**RoamQuest** 是一款城市探索应用，通过 AI 为用户生成个性化的城市体验清单。用户可以发现精心策划的景点、美食和体验，通过拍照打卡记录旅程，并分享精美的旅行报告。

**Slogan:** Discover cities, one adventure at a time.

### 核心价值
- 自动位置检测，智能生成清单
- AI 驱动的个性化城市指南
- 照片打卡，记录美好回忆
- 视觉报告，分享城市探险

---

## 功能需求

### 1. 用户认证
- **Apple Sign-In**: 主要登录方式
- **自动登录状态检测**: App 启动时自动检测用户登录状态
- **用户资料管理**: 用户名、头像、统计信息

### 2. 城市探索
- **自动位置检测**: 基于 GPS 检测当前城市
- **手动选择城市**: 支持搜索和选择热门城市
- **AI 生成清单**: 调用 DeepSeek API 生成包含 20+ 项目的清单
- **清单模板缓存**: 保存已生成的城市模板，避免重复调用 AI

### 3. 清单功能
- **分类筛选**: Landmark / Food / Experience / Hidden Gems
- **进度追踪**: 显示完成进度（X/Y 格式 + 百分比）
- **自定义添加**: 用户可手动添加清单项
- **完成状态标记**: 绿色勾选 / 解锁图标 / 锁图标

### 4. 打卡功能
- **拍照打卡**: 支持相机拍照和相册选择
- **照片上传**: 上传到 Supabase Storage
- **位置记录**: 可选保存打卡时的经纬度
- **已完成编辑**: 已完成项目可重新编辑照片（不消耗免费额度）

### 5. 报告生成
- **视觉报告**: 显示清单标题、城市信息、完成统计
- **照片拼贴**: 网格布局展示所有打卡照片
- **地图标记**: 在地图上标记打卡地点（暂时禁用 Mapbox）
- **分享功能**: 支持分享到其他应用或保存到相册

### 6. 订阅系统
- **Freemium 模式**:
  - 免费用户: 每个分类 1 次免费打卡
  - Premium 用户: 无限次打卡
- **Apple IAP**: 支持月付 ($4.99)、季付 ($13.49)、年付 ($47.99)
- **自动续订**: 支持订阅自动续订
- **支付墙**: 超过免费额度时显示订阅提示

### 7. 用户资料
- **统计信息**: 探索城市数量、打卡总数、照片总数
- **隐私政策**: 内置隐私政策页面

---

## 技术栈

### 前端框架
| 技术 | 版本 | 说明 |
|------|------|------|
| Flutter | 3.x | 跨平台移动应用开发框架 |
| Dart | >= 3.0.0 | Flutter 所用编程语言 |

### 支持平台
- iOS (主要)
- Android
- macOS
- Web (部分功能受限)

### 后端服务
| 服务 | 说明 |
|------|------|
| **Supabase** | PostgreSQL 数据库 + Auth + Storage |
| **DeepSeek API** | AI 清单生成（替代 Claude API） |
| **Apple Sign-In** | 用户认证 |
| **Apple In-App Purchase** | 订阅支付 |

### 状态管理
- **Provider**: 轻量级状态管理解决方案

### 网络请求
- **dio**: HTTP 客户端，用于调用 AI API
- **supabase_flutter**: Supabase 官方 SDK

### 位置服务
- **geolocator**: 获取当前位置
- **geocoding**: 反向地理编码（坐标 -> 城市名）

### 媒体处理
- **image_picker**: 拍照/选择照片
- **cached_network_image**: 图片缓存

### 存储与配置
- **shared_preferences**: 本地键值存储
- **flutter_dotenv**: 环境变量管理
- **path_provider**: 文件路径获取

### UI 组件
- **flutter_svg**: SVG 图片支持
- **shimmer**: 加载动画
- **share_plus**: 分享功能

### 其他依赖
- **uuid**: UUID 生成
- **equatable**: 对象相等性比较
- **intl**: 国际化支持
- **package_info_plus**: 获取应用信息

### 禁用的功能（因兼容性问题）
- **mapbox_gl**: 地图展示（Web 平台兼容问题）
- **flutter_local_notifications**: 推送通知（暂时禁用）

---

## 项目结构

```
roam_quest/
├── lib/                              # 主要源代码目录
│   ├── core/                        # 核心工具模块
│   │   ├── config/                  # 配置文件
│   │   │   └── supabase_config.dart # Supabase 配置和初始化
│   │   ├── constants/               # 应用常量
│   │   │   ├── api_constants.dart   # API 配置和 AI 提示模板
│   │   │   └── app_constants.dart   # 应用常量
│   │   ├── theme/                   # 主题样式
│   │   │   ├── app_colors.dart      # 颜色定义
│   │   │   ├── app_text_styles.dart # 文字样式
│   │   │   └── app_theme.dart       # 主题配置
│   │   ├── utils/                   # 工具类
│   │   │   └── app_logger.dart      # 日志工具
│   │   └── widgets/                 # 通用组件
│   │       ├── app_bottom_sheet.dart # 底部弹窗组件
│   │       └── widgets.dart         # 其他通用组件
│   ├── data/                        # 数据层
│   │   ├── models/                  # 数据模型
│   │   ├── repositories/            # 数据仓库模式
│   │   └── services/                # 外部服务
│   │       ├── auth_service.dart    # 认证服务
│   │       └── local_storage_service.dart # 本地存储服务
│   ├── features/                    # 功能模块（特性驱动）
│   │   ├── auth/                    # 认证模块
│   │   ├── home/                    # 首页模块
│   │   ├── checklist/               # 清单管理模块
│   │   ├── checkin/                 # 打卡功能模块
│   │   ├── report/                  # 报告生成模块
│   │   └── subscription/            # 订阅管理模块
│   │       └── widgets/             # 模块专用组件
│   └── l10n/                        # 国际化
│       └── app_localizations.dart   # 本地化字符串
├── database/                        # 数据库相关 SQL 文件
│   ├── schema_v2.sql                # 数据库主模式（v2）
│   ├── create_profile_trigger.sql   # 创建触发器
│   └── fix_*.sql                    # 数据库修复脚本
├── assets/                          # 静态资源
│   ├── images/                      # 图片资源
│   └── icons/                       # 图标资源
├── android/                         # Android 平台特定代码
├── ios/                             # iOS 平台特定代码
├── macos/                           # macOS 平台特定代码
├── web/                             # Web 平台特定代码
├── test/                            # 单元测试
├── integration_test/                # 集成测试
├── .env                             # 环境变量（Git 忽略）
├── .env.example                     # 环境变量模板
├── .gitignore                       # Git 忽略配置
├── pubspec.yaml                     # 项目依赖配置
├── analysis_options.yaml            # Dart 代码分析配置
├── README.md                        # 项目说明文档
├── CLAUDE.md                        # AI 开发助手文档（本文件）
├── PRIVACY_POLICY.md                # 隐私政策
├── TEST_CHECKLIST.md                # 功能测试清单
└── IOS_CHECKLIST.md                 # iOS 上架检查清单
```

---

## 数据库设计

### 核心表结构

#### 1. cities（城市表）
- 公开预置数据
- 存储城市基本信息
- `is_active`: 控制城市是否对用户可见

#### 2. attractions（景点模板表）
- AI 生成的景点数据
- 关联到特定城市
- 可被多个用户清单引用

#### 3. checklists（用户清单表）
- 用户创建的清单头部
- `id`: UUID 主键
- `user_id`: 关联到 Supabase Auth 用户
- `city_id`: 外键关联到城市

#### 4. checklist_items（清单项目表）
- 清单中的具体项目
- `is_completed`: 完成状态
- `checkin_photo_url`: 打卡照片
- `checked_at`: 打卡时间
- `rating`: 用户评分（1-20，显示时除以2得到0.5-10）
- `notes`: 用户备注

#### 5. subscriptions（订阅记录表）
- 用户订阅信息
- `product_id`: 订阅产品 ID
- `start_date/end_date`: 订阅有效期
- `auto_renew`: 自动续订开关
- `original_transaction_id`: App Store 原始交易 ID

#### 6. profiles（用户资料表）
- 用户个人信息
- `user_id`: 关联到 auth.users
- `preferences`: JSON 格式的用户偏好
- 通过触发器在用户注册时自动创建

### 行级安全策略（RLS）
- **cities** 和 **attractions**: 公开可读，禁用 RLS
- **checklists**、**checklist_items**、**subscriptions**、**profiles**: 启用 RLS
- 用户只能访问自己的数据（通过 `auth.uid() = user_id` 验证）

### 索引优化
- 所有外键字段建立索引
- 常用查询字段（如 `is_active`, `created_at`）建立索引

---

## 环境配置

### 必需的环境变量

```env
# Supabase 配置
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# DeepSeek AI API（当前使用）
DEEPSEEK_API_KEY=your_deepseek_api_key

# Claude AI API（已停用，改用DeepSeek）
# CLAUDE_API_KEY=your_claude_api_key

# Mapbox（已禁用）
# MAPBOX_ACCESS_TOKEN=your_mapbox_access_token
# MAPBOX_STYLE_URL=mapbox://styles/mapbox/streets-v12

# 应用配置
FREE_CHECKIN_LIMIT=5
CHECKLIST_ITEM_COUNT=20

# 订阅产品 ID
PRODUCT_ID_MONTHLY=com.roamquest.subscription.monthly
PRODUCT_ID_QUARTERLY=com.roamquest.subscription.quarterly
PRODUCT_ID_YEARLY=com.roamquest.subscription.yearly
```

### 订阅价格
| 方案 | 价格 | 节省 |
|------|------|------|
| 月付 | $4.99 | - |
| 季付 | $13.49 | 10% |
| 年付 | $47.99 | 20% |

---

## 开发规范

### 命名规范
| 类型 | 规范 | 示例 |
|------|------|------|
| 文件和目录 | snake_case | `auth_service.dart`, `checklist_page/` |
| 类和类型 | PascalCase | `AppColors`, `AuthService` |
| 变量和方法 | camelCase | `userId`, `getUserInfo()` |
| 常量 | camelCase 或 UPPER_SNAKE_CASE | `supabaseUrl`, `FREE_CHECKIN_LIMIT` |

### 代码风格（Linter 规则）

```yaml
# analysis_options.yaml 关键规则
linter:
  rules:
    - prefer_const_constructors      # 优先使用 const 构造函数
    - prefer_const_declarations      # 优先使用 const 声明
    - prefer_const_literals_to_create_immutables  # 优先使用 const 字面量
    - avoid_print                     # 避免使用 print（使用 logger）
    - avoid_unnecessary_containers    # 避免不必要的容器
    - prefer_single_quotes            # 使用单引号
    - sort_child_properties_last     # 子属性排序
    - use_key_in_widget_constructors # Widget 构造函数使用 key 参数
```

### 架构模式
- **特性驱动开发（Feature-Driven）**: 按功能模块组织代码
- **仓库模式（Repository Pattern）**: 数据访问层抽象
- **分层架构（Clean Architecture）**: Core / Data / Features 清晰分层

### 目录组织原则
1. **模块化设计**: 每个功能独立模块
2. **服务层抽象**: 外部服务通过接口注入
3. **配置集中管理**: 统一的配置文件
4. **错误处理**: 优雅的降级处理（如 Supabase 初始化失败）
5. **日志记录**: 使用 `AppLogger` 统一日志

### 注释规范
- 公共 API 必须添加文档注释
- 复杂逻辑添加行内注释
- 遵循 Dart 文档注释格式（`///`）

---

## 主题设计

### 颜色系统

```dart
// 主色调
primary: #6C5CE7      // 紫色
primaryLight: #A29BFE

// 次要色
secondary: #00CEC9     // 青色
secondaryLight: #81ECEC

// 强调色
accent: #FD79A8       // 粉色
accentYellow: #FDCB6E // 黄色

// 中性色
background: #FAFAFA
surface: #FFFFFF
textPrimary: #2D3436
textSecondary: #636E72

// 分类颜色
landmark: #FF6B6B     // 红色
food: #4ECDC4         // 青绿色
experience: #45B7D1   // 蓝色
hidden: #96CEB4       // 绿色
```

### 渐变色
- **primaryGradient**: 紫色渐变 (#6C5CE7 → #A29BFE)
- **sunsetGradient**: 日落渐变 (#6C5CE7 → #FD79A8 → #FDCB6E)

---

## AI 集成

### DeepSeek API 配置
```dart
static const String deepSeekBaseUrl = 'https://api.deepseek.com/v1/chat/completions';
static const String deepSeekModel = 'deepseek-chat';
```

### AI 提示模板
- 根据城市、国家、语言生成清单
- 包含分类：landmark、food、experience
- 限制标题长度（最多 8 词）
- 确保包含真实存在的景点
- 输出纯 JSON 格式

---

## Web 平台限制

由于浏览器平台特性，以下功能在 Web 上受限：
1. **位置服务**: 需要 HTTPS 和用户交互
2. **相机访问**: 不可用
3. **Apple Sign In**: 不支持
4. **文件系统**: 相册访问受限

---

## 上架准备

### iOS 上架清单
- [ ] App Store Connect 配置
- [ ] 素材准备（图标、截图、描述）
- [ ] 内购产品配置
- [ ] 隐私政策 URL
- [ ] Xcode 签名和证书
- [ ] 构建 Archive 并上传
- [ ] 隐私详情配置
- [ ] 提交审核

参考文件: `IOS_CHECKLIST.md`

### 隐私政策
- 必需的 App Store 上架材料
- 已准备: `PRIVACY_POLICY.md`
- 包含数据收集、用途、安全、用户权利等说明

---

## 测试指南

参考文件: `TEST_CHECKLIST.md`

### 测试覆盖
1. 用户认证（登录/登出/状态检测）
2. 首页功能（位置检测/城市选择/AI 生成）
3. 清单展示（分类筛选/进度追踪/自定义添加）
4. 打卡功能（拍照/上传/编辑）
5. 报告生成（视觉报告/照片拼贴/分享）
6. 订阅系统（免费额度检查/Apple IAP/状态同步）
7. 用户资料（信息显示/编辑/统计）
8. 数据服务（Supabase 连接/CRUD 操作）

---

## 版本信息

- **当前版本**: 1.0.0+1
- **Flutter SDK**: >= 3.0.0 < 4.0.0
- **数据库版本**: 2.0

---

## 重要注意事项

### 安全
1. RLS 策略必须使用 `auth.uid() = user_id` 进行验证
2. 用户数据必须隔离，防止跨用户访问
3. API 密钥存储在 `.env` 文件中，不提交到 Git

### 性能
1. 城市模板缓存后直接使用，避免重复调用 AI
2. 照片上传使用 Supabase Storage，带进度显示
3. 数据库查询使用索引优化性能

### 用户体验
1. 免费额度限制清晰显示
2. 支付墙弹窗友好引导
3. 错误提示清晰明了
4. 加载状态使用 Shimmer 动画

### 版本控制
1. **⚠️ 禁止自动提交到 GitHub**
   - 所有代码更改必须经过用户审核后才能提交
   - **绝对禁止**自动执行 `git commit` 或 `git push`
   - 修改代码后，仅使用 `git diff` 展示变更，等待用户确认
   - 用户明确同意后，才能执行提交操作

2. **提交规范**: 遵循语义化版本控制，清晰说明变更内容

3. **分支管理**: 开发使用 feature 分支，合并前必须 review

4. **避免敏感信息**: 确保 API 密钥、环境变量等敏感信息不被提交

---

## 常见问题

### Q1: 为什么从 Claude API 切换到 DeepSeek？
A: DeepSeek 是国产大模型，API 访问更稳定，成本更低。

### Q2: Mapbox 地图为什么禁用？
A: Web 平台兼容问题，未来可能重新启用。

### Q3: 免费额度如何计算？
A: 每个分类（landmark、food、experience、hidden）各 1 次免费打卡。

### Q4: 如何处理 AI 生成失败？
A: 自动重试最多 3 次，失败后显示错误提示。

---

## 联系方式

- **项目地址**: https://github.com/yourusername/roam_quest
- **支持邮箱**: support@roamquest.app
- **隐私政策**: 见 PRIVACY_POLICY.md

---

*最后更新: 2026-03-18*
