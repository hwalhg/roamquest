# RoamQuest iOS 上架详细步骤

## 一、前期准备

### 1. 准备材料

| 材料 | 说明 | 位置 |
|------|------|------|
| 应用图标 | 1024x1024px，无透明圆角 | 设计制作 |
| 启动页 | 1125x2436px (3x) | 需设计 |
| 截图 | 6.7" 或 6.5" iPhone，需 iPhone 15 Pro | 至少需要 4 张 |
| 隐私政策 | 政策文档，需可访问 | 需要托管 |
| 服务条款 | 条款文档，需可访问 | 需要托管 |
| 测试账号 | Sandbox 测试账号 | App Store Connect 中创建 |

---

## 二、配置项目（必需）

### 步骤 1: 修改 Bundle Identifier

1. 打开 Xcode 项目
   ```bash
   open ios/Runner.xcworkspace
   ```

2. 选择 `Runner` → `General` → `Bundle Identifier`

3. 修改为你的团队 ID：
   ```
   com.yourteam.roamquest
   ```

4. 确保 **Signing & Capabilities** 配置正确：
   - ✅ Automatically manage signing
   - ✅ 选择正确的 Team

### 步骤 2: 添加 iOS 14.5+ 必需配置

打开 `ios/Runner/Info.plist`，添加以下内容（在 `</dict>` 前添加）：

```xml
<!-- iOS 14.5+ 必需 -->
<key>NSAppTransparency</key>
<true/>

<!-- 隐私政策 URL（必需）-->
<key>NSPrivacyPolicyLocationUsageDescription</key>
<string>访问我们的隐私政策以了解我们如何使用您的位置数据：https://roamquest.app/privacy</string>

<!-- 订阅相关说明 -->
<key>NSUserTrackingUsageDescription</key>
<string>我们不会使用您的数据进行跨应用追踪</string>
```

### 步骤 3: 创建 Entitlements 文件

创建 `ios/Runner/Runner.entitlements` 文件：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- In-App Purchase -->
    <key>com.apple.developer.in-app-payments</key>
    <array>
        <string>com.roamquest.subscription.monthly</string>
        <string>com.roamquest.subscription.quarterly</string>
        <string>com.roamquest.subscription.yearly</string>
    </array>
</dict>
</plist>
```

---

## 三、App Store Connect 配置（必需）

### 访问 App Store Connect
```
https://appstoreconnect.apple.com
```

### 步骤 1: 创建 App 记录

1. 进入 **My Apps** → **+**
2. 选择 **Create a New App**
3. 填写基本信息：
   - **Platform**: iOS, iPadOS
   - **Name**: RoamQuest
   - **Primary Language**: English (U.S.)
   - **SKU**: ROAMQUEST001 (可自定义)
   - **Bundle ID**: com.yourteam.roamquest（与 Xcode 一致）

4. 选择 **Pricing and Availability**
   - ✅ 选择订阅制
   - ✅ 设置各国家/地区价格

### 步骤 2: 配置应用信息

#### App Store Information（必填）

| 字段 | 内容 |
|------|------|
| **Name** | RoamQuest |
| **Subtitle** | 城市探索之旅 |
| **Description** | 发现每个城市的精彩之处，生成个性化清单，记录你的旅行回忆。支持无限打卡和精美报告。 |
| **Keywords** | travel, city, exploration, checklist, guide, adventure |
| **Support URL** | https://roamquest.app/support |
| **Marketing URL** | https://roamquest.app |
| **Privacy Policy URL** | https://roamquest.app/privacy |
| **Terms of Use URL** | https://roamquest.app/terms |

#### Age Rating（必填）

在 **Content Rights** 中配置：
- ✅ **No Rated 17+**
- ✅ 选择 "Yes" 没有暴力、色情、赌博等内容

#### App Information

- ✅ **Category**: Travel
- ✅ **Bundles**: 可留空或选择相关

---

## 四、创建订阅产品（必需）

### 步骤 1: 创建订阅组

1. 进入 App Store Connect
2. 进入你的 App → **Subscriptions**
3. 点击 **+** 创建订阅组
4. 命名：`RoamQuest Premium`

### 步骤 2: 创建订阅产品

创建以下 3 个订阅产品：

#### 1. 月度订阅

| 字段 | 值 |
|------|-----|
| **Product ID** | com.roamquest.subscription.monthly |
| **Subscription Group** | RoamQuest Premium |
| **Reference Name** | Monthly Premium |
| **Price** | 设置价格（例如：$4.99）|
| **Description** | 按月订阅，解锁所有城市，无限打卡 |

#### 2. 季度订阅

| 字段 | 值 |
|------|-----|
| **Product ID** | com.roamquest.subscription.quarterly |
| **Subscription Group** | RoamQuest Premium |
| **Reference Name** | Quarterly Premium |
| **Price** | 比月度便宜 15-20% |
| **Description** | 按季订阅，解锁所有城市，无限打卡 |

#### 3. 年度订阅

| 字段 | 值 |
|------|-----|
| **Product ID** | com.roamquest.subscription.yearly |
| **Subscription Group** | RoamQuest Premium |
| **Reference Name** | Yearly Premium |
| **Price** | 比月度便宜 50% |
| **Description** | 按年订阅，解锁所有城市，无限打卡 |

---

## 五、配置隐私政策和服务条款

### 方案 A：使用第三方托管（推荐）

#### 隐私政策内容

```markdown
# RoamQuest 隐私政策

**最后更新日期**: 2025年2月26日

## 1. 我们收集的信息

### 我们收集的信息
- 位置信息（用于识别当前城市）
- 设备信息（iOS 版本、型号）
- 使用数据（城市探索记录、打卡记录）

### 我们不收集的信息
- 不会收集您的个人身份信息
- 不会收集您的联系信息
- 不会收集您的位置历史记录

## 2. 信息的使用

### 位置信息
- 用于识别您当前所在的城市
- 用于生成城市相关的探索清单
- 位置信息仅用于提供个性化体验，不会存储或与第三方共享

### 使用数据
- 用于生成个人旅行报告
- 存储在您的设备本地和 Supabase 云端（已加密）

## 3. 信息的共享

### 与 Supabase 云端共享
- 根据您的同意，使用 Supabase 云服务存储使用数据
- Supabase 遵循隐私和安全标准

### 与 Apple 分享
- 订阅信息与 Apple 共享
- Apple 处理订阅相关交易

## 4. 信息的存储

### 本地存储
- 部分数据存储在您的设备本地
- 您可以随时清除本地数据

### 云端存储
- 通过 Supabase 加密存储
- 使用您的 Apple ID 进行身份验证

## 5. 您的权利

### 访问和删除
- 您有权访问、修改和删除您的使用数据
- 您有权随时取消订阅

### 禁用跟踪
- 您可以在 iOS 设置中禁用 App 跟踪

## 6. 数据安全

### 加密
- 所有数据传输均使用加密技术

### 安全措施
- 我们采取合理的安全措施保护您的信息

## 7. 儿童隐私

### 年龄限制
- 本应用适用于 17 岁及以上用户
- 我们不会故意收集 17 岁以下用户的信息

## 8. 联系我们

如有疑问，请通过以下方式联系我们：
- 邮箱: support@roamquest.app
```

#### 服务条款内容

```markdown
# RoamQuest 服务条款

**最后更新日期**: 2025年2月26日

## 1. 服务概述

RoamQuest 是一款城市探索应用，为用户提供个性化的城市清单生成和旅行记录服务。

## 2. 订阅服务

### 订阅类型
RoamQuest 提供以下订阅计划：
- 月度订阅
- 季度订阅
- 年度订阅

### 订阅权益
订阅后，您将获得：
- 无限打卡权限
- 所有城市的完整访问
- 完整的旅行报告
- 高级功能体验

### 自动续订
所有订阅均为自动续订订阅。订阅将自动续订，除非您在当前订阅期结束前至少 24 小时取消订阅。

### 取消订阅
您可以通过以下方式取消订阅：
- 在 iOS 设置 > Apple ID > 订阅中管理
- 或访问：https://support.apple.com/HT202039

## 3. 退款政策

### Apple 管理退款
所有退款请求均通过 Apple App Store 处理。

### 退款请求
如需申请退款，请通过 Apple App Store 发起请求。

## 4. 用户责任

### 合法使用
您同意仅将本应用用于合法目的。
您不得：
- 复制、分发或逆向工程本应用
- 使用本应用进行任何非法活动

### 位置信息
您理解并同意位置信息仅用于提供个性化体验。

## 5. 免责声明

### 服务可用性
我们尽力保持服务的可用性，但不保证：
- 服务不间断
- 无错误或无缺陷
- 错误将被立即纠正

### 数据丢失
对于数据丢失或损坏，我们不对超出我们控制的数据丢失承担责任。

### 第三方服务
本应用使用以下第三方服务：
- Supabase（后端服务）
- Apple（订阅服务）
- Claude API（AI 生成服务）

我们对这些第三方服务的可用性或性能不承担责任。

## 6. 知识产权

### 应用内容
RoamQuest 应用及其所有内容均受知识产权保护。

### 用户生成内容
用户使用本应用生成的内容（清单、报告等）归用户所有。

## 7. 条款变更

### 更新通知
我们可能会不时更新本条款。重要变更将通过应用内通知告知您。

### 继续使用
更新后继续使用本应用即表示您接受新条款。

## 8. 争议解决

### 适用法律
本条款受您所在国家/地区法律管辖。

### 协商
对于任何争议，我们首先尝试友好协商解决。

## 9. 联系我们

如有疑问或需要支持，请联系：
- 邮箱: support@roamquest.app
```

### 托管方式

你可以使用以下方式托管隐私政策和服务条款：

1. **GitHub Pages**（免费）
   - 创建仓库
   - 添加 `privacy.md` 和 `terms.md`
   - 启用 GitHub Pages
   - 访问地址：`https://yourname.github.io/roamquest/privacy`

2. **Vercel / Netlify**（免费）
   - 直接部署静态文件
   - 自定义域名

3. **Notion**（付费）
   - 使用 Notion 托管文档
   - 可自定义样式

---

## 六、更新代码中的 URL

更新以下文件中的占位符 URL：

### 1. `subscription_page.dart`

将以下 URL 替换为实际地址：
```dart
// 第 719 行
'https://roamquest.app/terms'

// 第 734 行
'https://roamquest.app/privacy'

// 第 761 行
'https://support.apple.com/HT202039'
```

### 2. `Info.plist`

确保隐私政策 URL 正确：
```xml
<key>NSPrivacyPolicyLocationUsageDescription</key>
<string>访问我们的隐私政策以了解我们如何使用您的位置数据：https://roamquest.app/privacy</string>
```

---

## 七、构建 iOS 包

### 步骤 1: 准备环境

```bash
cd /Users/mac/Documents/codes/ai-project/roam_quest
flutter clean
flutter pub get
```

### 步骤 2: 使用 Xcode 构建

```bash
open ios/Runner.xcworkspace
```

在 Xcode 中：
1. 选择 **Product** → **Archive** (⌘⌘R)
2. 等待编译完成
3. 选择 **Distribute App**
4. 选择 **App Store Connect**
5. 选择正确的 Team 和 App
6. 点击 **Upload**

---

## 八、配置版本信息

### 在 App Store Connect 中配置

### 步骤 1: 选择版本

1. 进入 **TestFlight**
2. 上传的版本会出现在列表中

### 步骤 2: 填写版本信息

#### 版本信息（1.0.1）

| 字段 | 内容 |
|------|------|
| **What's New** | • 全新订阅模式<br>• 订阅到期提醒<br>• 改进的免费限制<br>• 隐私政策链接 |
| **Description** | 按月/季/年订阅解锁所有城市，无限打卡和精美报告 |

### 步骤 3: 设置价格

选择订阅组中的产品，为每个地区设置价格。

| 地区 | 月度 | 季度 | 年度 |
|------|-------|-------|-------|
| 中国大陆 | ¥28/月 | ¥78/季 | ¥278/年 |
| 中国香港 | ¥38/月 | ¥102/季 | ¥368/年 |
| 美国 | $4.99/月 | $13.49/季 | $47.99/年 |
| 欧盟 | €4.99/月 | €13.99/季 | €47.99/年 |

---

## 九、测试（必需）

### Sandbox 测试步骤

1. 创建 Sandbox 测试账号：
   - 进入 App Store Connect → **Users and Roles** → **Sandbox** → **+**
   - 创建 3 个测试账号

2. 配置 Xcode 测试：
   - Product → **Destination** → 选择测试设备
   - 修改 Signing 为自动管理

3. 安装测试版 App：
   - Product → **Run** (▶️)
   - 在测试设备上安装

4. 测试订阅功能：
   - 测试购买流程
   - 测试订阅续订
   - 测试恢复购买
   - 测试取消订阅

5. 验证功能：
   - ✅ 免费用户限制正常
   - ✅ 订阅后解锁所有城市
   - ✅ 订阅到期提醒正常
   - ✅ 隐私政策链接可访问

---

## 十、提交审核

### 提交前检查清单

| 检查项 | 状态 |
|---------|------|
| App Store 信息完整 | ✅ 需要完成 |
| 隐私政策 URL 可访问 | ✅ 需要配置 |
| 服务条款 URL 可访问 | ✅ 需要配置 |
| 订阅产品已创建 | ✅ 需要创建 |
| 价格已设置所有地区 | ✅ 需要设置 |
| 图标和截图已上传 | ✅ 需要上传 |
| Sandbox 测试通过 | ✅ 需要测试 |
| Info.plist 已更新 | ✅ 需要修改 |

### 提交审核

1. 在 App Store Connect 中选择版本
2. 点击 **Add for Review** (+)
3. 填写审核备注：
   ```
   按月订阅模式，支持自动续订，已配置隐私政策和服务条款。
   ```
4. 提交审核

---

## 十一、审核期间

### 审核时间
- iOS 审核时间：通常 1-3 个工作日
- 可能被要求提供补充信息
- 可能需要演示视频

### 可操作
审核期间仍可以：
- ✅ 测试新版本
- ✅ 拒绝旧版本
- ✅ 回复审核意见

---

## 十二、审核通过后

### 自动发布
- 审核通过后 App 将自动发布
- 通常需要 24 小时在 App Store 可见

### 准备
- 监控首次用户反馈
- 查看下载量和评分
- 准备处理用户问题

---

## 十三、重要提醒

### 订阅合规要求（Apple 必查）

| 要求 | 状态 |
|------|------|
| ✅ 提供了取消订阅的指引 | 代码中已添加链接 |
| ✅ 提供了隐私政策链接 | 需要配置真实 URL |
| ✅ 提供了服务条款链接 | 需要配置真实 URL |
| ⚠️ 订阅价格在所有地区一致 | 需要配置 |
| ⚠️ 订阅续订说明清晰 | 需要在描述中明确 |
| ⚠️ 提供了 24 小时取消提醒 | 需要在描述中说明 |
| ⚠️ iOS 14.5+ 配置了 NSAppTransparency | 需要添加到 Info.plist |

### 常见拒绝原因

| 原因 | 解决方法 |
|------|--------|
| 隐私政策链接无效 | 确保链接可访问 |
| 服务条款链接无效 | 确保链接可访问 |
| 缺少订阅管理指引 | 已在代码中添加 |
| 描述不准确 | 准确描述订阅模式 |
| 不支持的功能 | 移除不可用功能的描述 |
| 设计不符合规范 | 检查 App 设计指南 |

---

## 十四、支持联系

### 审核咨询
如遇到审核问题，可联系：
- **Apple Developer Support**: https://developer.apple.com/contact/
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/

### 用户支持
用户支持渠道：
- 邮箱: support@roamquest.app
- 可在 App Store Connect 中配置

---

**最后更新日期**: 2025年2月26日
**文档版本**: 1.0
