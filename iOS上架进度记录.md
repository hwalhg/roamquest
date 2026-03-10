# RoamQuest iOS 上架进度记录

## 基本信息

| 项目 | 值 |
|------|-----|
| **Team ID** | GLY7GATTN5 |
| **Bundle ID** | com.roamquest.roamQuest |
| **版本号** | 1.0.0+1 |
| **隐私政策 URL** | https://roamquest.xyz/privacy |
| **服务条款 URL** | https://roamquest.xyz/terms |
| **支持 URL** | https://roamquest.xyz/support |

---

## 订阅产品配置

在 App Store Connect 中创建以下订阅产品：

| Product ID | 参考名称 | 建议价格 |
|------------|----------|----------|
| `com.roamquest.subscription.monthly` | Monthly Premium | $4.99/月 |
| `com.roamquest.subscription.quarterly` | Quarterly Premium | $13.49/季 |
| `com.roamquest.subscription.yearly` | Yearly Premium | $47.99/年 |

---

## App Store Connect 配置信息

### App 信息

| 字段 | 内容 |
|------|------|
| **Platform** | iOS, iPadOS |
| **Name** | RoamQuest |
| **Subtitle** | Explore Cities Your Way |
| **Primary Language** | English (U.S.) |
| **SKU** | ROAMQUEST001 |
| **Bundle ID** | com.roamquest.roamQuest |
| **Category** | Travel |
| **Support URL** | https://roamquest.xyz/support |
| **Privacy Policy URL** | https://roamquest.xyz/privacy |
| **Terms of Use URL** | https://roamquest.xyz/terms |

### App 描述 (Description)

```
Discover every city like a local with RoamQuest. Whether you're visiting a new destination or exploring your own hometown, RoamQuest generates personalized checklists of must-see landmarks, hidden gems, local cuisine, and unique experiences.

**Key Features:**
• AI-Powered City Lists: Get curated recommendations tailored to your interests
• Photo Check-Ins: Capture memories at each location and build your travel diary
• Beautiful Travel Reports: Share stunning photo collages of your adventures
• Unlimited Exploration: Premium users enjoy unlimited check-ins and access to all cities

**How It Works:**
1. Select your city
2. Receive a personalized 20-item checklist
3. Explore and check off locations with photos
4. Generate and share your travel report

Start your journey today and explore cities your way!

**Subscription Options:**
• Monthly: $4.99/month
• Quarterly: $13.49/quarter (save 10%)
• Yearly: $47.99/year (save 20%)

Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.
Manage your subscription in your Apple ID settings.

Privacy Policy: https://roamquest.xyz/privacy
Terms of Service: https://roamquest.xyz/terms
```

### 关键词

```
travel, city, exploration, checklist, guide, adventure
```

---

## 代码配置状态

| 项目 | 状态 | 说明 |
|------|------|------|
| Entitlements 文件 | ✅ 已完成 | `ios/Runner/Runner.entitlements` |
| Xcode 项目文件 | ✅ 已完成 | `ios/Runner.xcworkspace` |
| Bundle Identifier | ✅ 已配置 | `com.roamquest.roamQuest` |
| App 图标 | ✅ 已准备 | 1024x1024 PNG |
| 隐私政策 URL | ✅ 已配置 | Info.plist |
| 服务条款 URL | ✅ 已配置 | 代码中已配置 |
| 权限配置 | ✅ 已完成 | 位置、相机、照片库 |
| 国际化 | ✅ 已完成 | 中英双语 |

---

## 待办事项（需手动处理）

### App Store Connect

- [x] 创建订阅产品（3个）
- [x] 填写 App 名称和副标题
- [ ] 上传 App Store 截图（至少4张 iPhone 6.7"）
- [x] 设置订阅价格（已在订阅产品中设置）
- [ ] 选择发布地区

### 截图要求

| 设备 | 尺寸 | 格式 | 数量 |
|------|------|------|------|
| iPhone 6.7" | 1290 x 2796 px | PNG/JPG | 至少 4 张 |
| iPhone 6.5" | 1242 x 2688 px | PNG/JPG | 可选 |

### 截图建议内容

1. 首页 - 展示城市选择
2. 清单页 - 展示探索清单
3. 打卡页 - 展示拍照打卡功能
4. 报告页 - 展示精美旅行报告

---

## 打包上传命令

```bash
# 进入项目目录
cd /Users/mac/Documents/codes/ai-project/roam_quest

# 打开 Xcode
open ios/Runner.xcworkspace
```

然后在 Xcode 中：
1. 选择 **Product** → **Archive**
2. 等待编译完成
3. 选择 **Distribute App**
4. 选择 **App Store Connect**
5. 选择正确的 Team 和 App
6. 上传

---

## 订阅合规要求

| 要求 | 状态 |
|------|------|
| 提供取消订阅指引 | ✅ 代码中已添加 |
| 提供隐私政策链接 | ✅ 已配置 |
| 提供服务条款链接 | ✅ 已配置 |
| 订阅续订说明清晰 | ⚠️ 需在描述中添加 |
| iOS 14.5+ NSAppTransparency | ✅ 已配置 |

---

## 联系信息

- **开发者支持邮箱**: support@roamquest.xyz
- **Apple Developer**: https://developer.apple.com
- **App Store Connect**: https://appstoreconnect.apple.com

---

## 文档更新日志

| 日期 | 更新内容 |
|------|----------|
| 2026-03-05 | 初始创建，记录基础配置和进度 |
| 2026-03-06 | 添加 App 副标题 "Explore Cities Your Way" 和完整英文描述 |
