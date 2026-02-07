# iOS App Store 上架检查清单

## 第一阶段：App Store Connect 配置

### App 基本信息
- [ ] 登录 https://appstoreconnect.apple.com/
- [ ] 创建新 App
- [ ] Bundle ID: `com.roamquest.roamQuest`
- [ ] 名称: RoamQuest
- [ ] SKU: roamquest001
- [ ] 平台: iOS

### App 信息填写
- [ ] 名称: RoamQuest
- [ ] 副标题: Explore Cities, Discover Wonders
- [ ] 类别: Travel (主), Lifestyle (副)
- [ ] 内容版权: RoamQuest © 2025
- [ ] 年龄分级: 完成问卷

### 定价与销售
- [ ] 价格: 免费
- [ ] 销售范围: 选择要上架的国家
- [ ] 发布日期: 手动控制

---

## 第二阶段：准备素材

### 必需素材
- [ ] App 图标 (1024x1024 px)
- [ ] iPhone 截图 3-10张 (1290x2796 px)
- [ ] iPad 截图 3-10张 (如支持 iPad)
- [ ] 应用描述文本
- [ ] 关键词
- [ ] 宣传文本 (170 字符)
- [ ] 支持 URL
- [ ] 营销 URL (可选)
- [ ] 隐私政策 URL ⚠️ 必需

### 应用描述 (英文)
```
RoamQuest - Your Ultimate Travel Companion

Discover curated experiences in every city you visit. RoamQuest generates personalized checklists of must-see landmarks, local foods, and cultural experiences.

KEY FEATURES:
• City Auto-Detection
• AI-Generated Travel Guides
• Photo Check-ins
• Visual Travel Reports
• Works Offline

Free tier includes 3 check-ins per city. Unlock unlimited access with a one-time purchase per city.

Download RoamQuest today and turn every trip into an adventure!
```

### 关键词
```
travel, city guide, checklist, trip planner, attractions, local food, cultural experiences, travel diary, vacation, tourism, sightseeing
```

---

## 第三阶段：配置内购产品

### 非消耗型产品 (每城市解锁)
- [ ] 产品 ID: `com.roamquest.city.unlock`
- [ ] 价格: $2.99
- [ ] 本地化名称: Unlock City Access
- [ ] 本地化描述: Unlock unlimited check-ins and full features for this city

---

## 第四阶段：Xcode 配置

### 签名和证书
- [ ] 打开 `ios/Runner.xcworkspace`
- [ ] Team: 选择你的开发者账号
- [ ] Signing: Automatically manage signing
- [ ] Provisioning profile: 自动生成

### Capabilities
- [ ] 添加 "Sign in with Apple"
- [ ] 添加 "In-App Purchase"
- [ ] 添加 "Location" (如需要)

### Deployment Info
- [ ] iOS Deployment Target: iOS 14.0+
- [ ] iPhone: 支持 (Portrait)
- [ ] iPad: 支持 (可选)

### Info.plist 检查
- [ ] NSLocationWhenInUseUsageDescription
- [ ] NSLocationAlwaysAndWhenInUseUsageDescription
- [ ] NSCameraUsageDescription
- [ ] NSPhotoLibraryUsageDescription
- [ ] NSPhotoLibraryAddUsageDescription

---

## 第五阶段：构建 Archive

### 测试构建
- [ ] 运行 `flutter build ios --release` 或在 Xcode 中 Product → Archive
- [ ] 确认构建成功，无错误

### 上传 Archive
- [ ] Window → Organizer
- [ ] 选择最新 Archive
- [ ] Distribute App → App Store Connect
- [ ] Upload

---

## 第六阶段：App 隐私配置

### 隐私详情
- [ ] 配置收集的数据类型:
  - [ ] Email (联系信息)
  - [ ] Precise Location (位置)
  - [ ] Photos (用户内容)
  - [ ] Device ID (标识符)
  - [ ] Usage Data (使用数据)

### 数据用途说明
- [ ] 产品个性化
- [ ] 应用功能
- [ ] 分析

---

## 第七阶段：提交审核

### 版本信息
- [ ] 版本号: 1.0.0
- [ ] 审核说明:
```
RoamQuest is a travel companion app that helps users discover attractions, local foods, and cultural experiences in cities they visit.

Test Account:
Email: [your test email]
Password: [your test password]
```

### 审核信息
- [ ] 完成所有必填项
- [ ] 上传截图
- [ ] 确认联系方式

### 提交
- [ ] 点击 "Submit for Review"
- [ ] 等待审核 (1-3天)

---

## 联系信息配置

### 支持信息 (必填)
- [ ] 支持 URL: https://roamquest.app/support 或 email: support@roamquest.app
- [ ] 营销 URL: https://roamquest.app (可选)

---

## 时间线预估

| 阶段 | 时间 |
|------|------|
| App Store Connect 配置 | 1-2 小时 |
| 素材准备 | 1-2 天 |
| 配置内购产品 | 30 分钟 |
| 构建和上传 Archive | 1 小时 |
| 配置隐私详情 | 30 分钟 |
| **总计** | **2-3 天** |
| App 审核 | 1-3 天 |

---

## 常见问题

### Q1: 隐私政策放在哪里？
**A**: 可以使用 GitHub Pages 免费托管，或者使用专业服务如 iubenda。

### Q2: 截图一定要英文吗？
**A**: 如果只上架美国/英国，英文即可。如果要上架多个国家，建议准备对应语言的截图。

### Q3: 首次审核需要多久？
**A**: 通常 1-3 个工作日。首次审核可能需要更长时间。

### Q4: 审核被拒怎么办？
**A**: 根据拒绝原因修改后重新提交，回复审核通常更快。

---

## 下一步行动

1. **今天**: 注册隐私政策 URL，准备截图
2. **明天**: 配置 App Store Connect 和内购产品
3. **后天**: 构建并上传 Archive

需要帮助随时联系！
