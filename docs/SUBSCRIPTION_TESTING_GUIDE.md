# RoamQuest iOS 订阅功能真机测试指南

## 文档信息

- **创建日期**: 2024-03-24
- **版本**: 1.0
- **适用范围**: iOS 真机沙盒测试

---

## ⚠️ 重要开发规范

**禁止自动提交到 GitHub**:
- 所有代码更改必须经过用户审核后才能提交
- **绝对禁止**自动执行 `git commit` 或 `git push`
- 修改代码后，仅使用 `git diff` 展示变更，等待用户确认
- 用户明确同意后，才能执行提交操作

---

## 目录

1. [沙盒测试账号申请](#一沙盒测试账号申请)
2. [测试前准备](#二测试前准备)
3. [测试场景](#三测试场景)
4. [问题排查](#四问题排查)
5. [测试记录模板](#五测试记录模板)

---

## 一、沙盒测试账号申请

### 1.1 访问 App Store Connect

1. 打开浏览器，访问 [App Store Connect](https://appstoreconnect.apple.com)
2. 使用您的 Apple 开发者账号登录

### 1.2 创建沙盒测试账号

**步骤**:

1. 在 App Store Connect 首页，点击 **Users and Roles**（用户和角色）
2. 在侧边栏中，点击 **Sandbox Testers**（沙盒测试员）
3. 点击页面左上角的蓝色 **+** 按钮
4. 填写表单：

| 字段 | 说明 | 示例 |
|------|------|------|
| **Name** | 测试员姓名 | Test User |
| **Email** | 邮箱地址（必须是未被注册 Apple ID 的邮箱） | test+roamquest@example.com |
| **Password** | 临时密码 | Test123456! |
| **Confirm Password** | 确认密码 | Test123456! |
| **Security Question** | 安全问题 | What is your favorite color? |
| **Security Answer** | 安全答案 | Blue |
| **Date of Birth** | 出生日期（可选） | 1990-01-01 |
| **App Store Territory** | 应用商店地区 | China |

5. 点击 **Create**（创建）

### 1.3 沙盒账号使用说明

⚠️ **重要提示**:

- 沙盒测试账号的邮箱**不能**已经注册为 Apple ID
- 沙盒账号只能用于测试，**无法**购买真实的应用
- 每个开发者账号最多可以创建 **100 个**沙盒测试账号
- 沙盒账号**永久有效**，除非您主动删除
- 沙盒账号**不会**收到真实费用的扣款

### 1.4 测试账号记录

创建完成后，请记录以下信息：

```
测试账号 1:
邮箱: _________________
密码: _________________

测试账号 2:
邮箱: _________________
密码: _________________
```

---

## 二、测试前准备

### 2.1 App Store Connect 检查清单

在开始真机测试前，请确认以下项目：

- [ ] 订阅产品已创建并配置完成
  - [ ] 月付: `com.roamquest.subscription.monthly` - $4.99
  - [ ] 季付: `com.roamquest.subscription.quarterly` - $13.49
  - [ ] 年付: `com.roamquest.subscription.yearly` - $47.99

- [ ] 所有订阅产品状态为以下之一：
  - **"Ready for Sale"**（准备销售）
  - **"Approved for Testing"**（批准用于测试）

- [ ] 至少创建 1 个沙盒测试账号

### 2.2 Xcode 项目检查

- [ ] Bundle Identifier 与 App Store Connect 中配置的一致
- [ ] **In-App Purchase** Capability 已添加到项目中
- [ ] Team 配置正确（选择您的开发团队）
- [ ] 代码签名配置正确

### 2.3 测试设备准备

- [ ] 准备一台 iOS 真机（iPhone 或 iPad）
  - ⚠️ **注意**: iOS 模拟器**不支持** IAP 测试
- [ ] 设备系统版本 >= iOS 14.0
- [ ] 设备已**退出**真实的 App Store 账号
  - 路径: 设置 → iTunes Store 与 App Store → 退出
- [ ] 设备系统时间设置为**自动**
  - 路径: 设置 → 通用 → 日期与时间 → 自动设置

### 2.4 应用准备

- [ ] 清理应用数据（或删除应用重新安装）
- [ ] 通过 Xcode 或 TestFlight 安装最新版本应用
- [ ] 确认应用可以正常启动和登录

---

## 三、测试场景

### 场景 1: 首次购买订阅 ✨

**测试目的**: 验证用户首次购买订阅的完整流程

**测试步骤**:

1. 确保 iOS 设备已退出真实 App Store 账号
2. 清理应用数据或重新安装应用
3. 通过 Xcode 运行应用到真机
4. 使用 Apple Sign In 登录应用
5. 在应用中导航到 **Premium** 或 **Subscription** 页面
6. 选择一个订阅方案（推荐先测试月付）
7. 点击 **"Subscribe Now"**（立即订阅）按钮
8. 系统会弹出 Apple 登录界面
9. 输入沙盒测试账号的邮箱和密码
10. 使用 Face ID / Touch ID 或密码确认购买

**验证点**:

- [ ] 购买成功提示正确显示
  - 显示 "Welcome to Premium!" 或类似消息
  - 显示无限城市探索的说明

- [ ] 订阅状态正确更新
  - 应用内显示 "Active Subscription" 或 "Premium" 状态
  - 过期日期显示正确（当前日期 + 30 天）

- [ ] Premium 功能可用
  - 可以无限打卡（不受免费额度限制）
  - 所有付费内容已解锁

- [ ] 订阅信息持久化
  - 退出应用后重新打开，订阅状态仍然有效

**预期结果示例**:
```
✅ Welcome to Premium!
✅ You can now explore unlimited cities
✅ Expires: 2024-04-23 (30 days remaining)
```

**可能遇到的问题**:

| 问题 | 解决方案 |
|------|----------|
| 产品列表为空 | 检查 App Store Connect 中产品状态，等待 15-30 分钟 |
| 无法登录沙盒账号 | 确认设备已退出真实 App Store 账号 |
| 购买失败 | 检查 Bundle Identifier 和代码签名 |

---

### 场景 2: 恢复购买 🔄

**测试目的**: 验证用户在换设备或重装应用后可以恢复购买

**测试步骤**:

1. 确保已完成场景 1（已有购买记录）
2. 删除应用（长按应用图标 → 删除应用）
3. 通过 Xcode 重新安装应用
4. 使用相同的账号登录应用（Apple Sign In）
5. 导航到 **Premium** 或 **Subscription** 页面
6. 点击 **"Restore Purchase"**（恢复购买）按钮
7. 等待恢复完成

**验证点**:

- [ ] 恢复成功提示显示
  - 显示 "Purchase restored" 或类似消息

- [ ] 订阅状态自动恢复
  - 应用识别到之前的订阅
  - 显示正确的订阅类型（月付/季付/年付）

- [ ] 过期日期与之前购买一致
  - 日期计算基于原始购买日期
  - 剩余天数显示正确

- [ ] Premium 功能立即可用
  - 无需重新付费
  - 可以继续使用所有 Premium 功能

**预期结果**:
```
✅ Purchase restored successfully
✅ Your subscription is active
✅ Expires: 2024-04-23
```

---

### 场景 3: 切换订阅方案 🔄

**测试目的**: 验证用户可以从低级方案升级到高级方案

**测试步骤**:

1. 确保当前有活跃的月付订阅
2. 导航到 **Premium** 或 **Subscription** 页面
3. 选择年付方案（或季付）
4. 点击 **"Subscribe Now"** 按钮
5. 确认升级操作

**验证点**:

- [ ] 系统提示确认升级
  - 显示升级说明
  - 显示新价格和生效日期

- [ ] 新订阅方案生效
  - 订阅类型更新为年付
  - 月付订阅被替换（不会并发收费）

- [ ] 过期日期正确更新
  - 年付：当前日期 + 365 天
  - 或基于原订阅周期延长

---

### 场景 4: 订阅即将过期提醒 ⚠️

**测试目的**: 验证订阅过期前 3 天的提醒功能

**测试步骤**:

**方法一：时间旅行（推荐）**

1. 购买月付订阅后
2. 打开 iOS 设置 → 通用 → 日期与时间
3. 关闭**自动设置**
4. 手动将日期**前进 27 天**
5. 返回应用，重新打开
6. 导航到 **Premium** 或 **Subscription** 页面

**方法二：实际等待**

1. 购买订阅后等待 27 天
2. 打开应用检查

**验证点**:

- [ ] 显示"即将过期"状态
  - 状态文本: "Expiring Soon" 或类似
  - 图标: 黄色警告图标

- [ ] 显示剩余天数
  - "X days remaining"
  - "3 days remaining"

- [ ] 提示续费
  - 显示续费提醒
  - 提供重新订阅选项

---

### 场景 5: 订阅已过期 ❌

**测试目的**: 验证订阅过期后的功能限制

**测试步骤**:

1. 购买月付订阅
2. 打开 iOS 设置 → 通用 → 日期与时间
3. 关闭**自动设置**
4. 手动将日期**前进 31 天**
5. 返回应用，重新打开
6. 尝试使用 Premium 功能（如无限打卡）

**验证点**:

- [ ] 订阅显示"已过期"状态
  - 状态文本: "Subscription Expired" 或类似
  - 图标: 红色错误图标

- [ ] Premium 功能受限
  - 无限打卡功能被禁用
  - 显示付费墙/订阅提示

- [ ] 免费额度仍可用
  - 每个分类 1 次免费打卡仍可用
  - 不影响基础功能

- [ ] 提示重新订阅
  - 显示订阅页面入口
  - 提供订阅选项

---

### 场景 6: 取消订阅 ⏹️

**测试目的**: 验证取消订阅后的行为

**测试步骤**:

1. 购买订阅
2. 在 iOS 设备上打开设置
3. 点击顶部的 **Apple ID**
4. 点击 **Subscriptions**（订阅）
5. 找到 RoamQuest 订阅
6. 点击 **Cancel Subscription**（取消订阅）
7. 确认取消

**验证当前周期结束前**:

- [ ] Premium 功能仍可用
  - 订阅在当前周期结束前仍然有效
  - 可以正常使用所有功能

**验证当前周期结束后**:

1. 等待订阅周期结束（或修改设备时间）
2. 重新打开应用

- [ ] 订阅已过期
  - 显示"已过期"状态
  - Premium 功能不可用

- [ ] 提示重新订阅
  - 显示订阅页面
  - 提供续费选项

---

### 场景 7: 多设备同步 🔄

**测试目的**: 验证订阅在多个设备间同步

**测试步骤**:

1. 在设备 A 上购买订阅
2. 在设备 B 上安装应用
3. 使用相同的 Apple ID 登录设备 B 的 App Store
4. 在设备 B 上打开应用
5. 使用相同的 Supabase 账号登录
6. 导航到 **Premium** 页面
7. 点击 **"Restore Purchase"**

**验证点**:

- [ ] 设备 B 识别到订阅
- [ ] Premium 功能在设备 B 上可用
- [ ] 订阅状态与设备 A 一致

---

## 四、问题排查

### 问题 1: 产品未找到

**错误信息**:
- "Products not found"
- 产品列表为空
- "No products available"

**可能原因**:
1. App Store Connect 中产品未正确配置
2. 产品 ID 与代码中不一致
3. 产品状态未就绪
4. 配置缓存未更新

**解决方案**:

1. **检查产品配置**
   ```
   App Store Connect → My Apps → RoamQuest → Subscriptions
   ```
   - 确认产品 ID 正确
   - 确认产品状态为 "Ready for Sale" 或 "Approved for Testing"

2. **检查代码中的产品 ID**
   ```dart
   // lib/core/constants/app_constants.dart
   class SubscriptionProducts {
     static const String monthly = 'com.roamquest.subscription.monthly';
     static const String quarterly = 'com.roamquest.subscription.quarterly';
     static const String yearly = 'com.roamquest.subscription.yearly';
   }
   ```
   - 确认与 App Store Connect 中的产品 ID 完全一致

3. **等待配置生效**
   - Apple 的配置可能需要 15-30 分钟生效
   - 删除应用后重新安装

4. **检查日志**
   ```bash
   flutter logs | grep -i "product\|subscription"
   ```

---

### 问题 2: 沙盒账号登录失败

**错误信息**:
- "Cannot connect to iTunes Store"
- "Your account information is not valid"

**可能原因**:
1. 设备未退出真实 App Store 账号
2. 沙盒账号邮箱已被注册为 Apple ID
3. 沙盒账号密码错误

**解决方案**:

1. **确认设备已退出真实账号**
   ```
   设置 → iTunes & App Store → 查看是否已登录
   ```
   - 如果已登录，点击账号 → 退出

2. **验证沙盒账号**
   - 确认邮箱未被注册为 Apple ID
   - 尝试创建新的沙盒测试账号

3. **重启设备**
   - 完全关闭设备并重新启动

4. **检查网络连接**
   - 确保设备连接到稳定的网络

---

### 问题 3: 购买失败

**错误信息**:
- "Purchase Failed"
- "Unable to complete purchase"

**可能原因**:
1. Bundle Identifier 不匹配
2. In-App Purchase Capability 未添加
3. 代码签名配置错误
4. Team 配置问题

**解决方案**:

1. **检查 Bundle Identifier**
   - Xcode → 项目 → Target → General
   - 确认 Bundle Identifier 与 App Store Connect 一致

2. **检查 In-App Purchase Capability**
   - Xcode → 项目 → Target → Signing & Capabilities
   - 确认已添加 **In-App Purchase**

3. **检查 Team 配置**
   - Xcode → 项目 → Target → Signing & Capabilities
   - Team: 选择您的开发团队

4. **重新生成证书**
   - Xcode → Preferences → Accounts
   - 选择您的账号 → Download Manual Profiles

5. **清理并重新构建**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

### 问题 4: 订阅状态不更新

**症状**:
- 购买成功但应用未识别订阅
- 订阅状态显示为 Free

**解决方案**:

1. **检查订阅存储**
   - 确认 SharedPreferences 正确保存
   - 检查 `subscription_is_active` 和 `subscription_end_date`

2. **检查订阅验证逻辑**
   ```dart
   // lib/data/repositories/subscription_repository.dart
   Future<void> checkSubscriptionStatus() async {
     // 检查本地存储的订阅状态
   }
   ```

3. **手动触发状态检查**
   - 退出应用并重新打开
   - 点击"恢复购买"

4. **查看日志**
   ```bash
   flutter logs | grep -i "subscription\|premium"
   ```

---

## 五、测试记录模板

### 测试执行记录

使用以下模板记录您的测试过程：

| 测试场景 | 测试时间 | 测试结果 | 备注 | 问题记录 |
|---------|---------|---------|------|----------|
| 场景 1: 首次购买 | | ☐ 通过 ☐ 失败 | | |
| 场景 2: 恢复购买 | | ☐ 通过 ☐ 失败 | | |
| 场景 3: 切换方案 | | ☐ 通过 ☐ 失败 | | |
| 场景 4: 即将过期 | | ☐ 通过 ☐ 失败 | | |
| 场景 5: 已过期 | | ☐ 通过 ☐ 失败 | | |
| 场景 6: 取消订阅 | | ☐ 通过 ☐ 失败 | | |
| 场景 7: 多设备同步 | | ☐ 通过 ☐ 失败 | | |

### 订阅状态记录

购买成功后，记录以下信息：

```json
{
  "测试场景": "首次购买",
  "产品 ID": "com.roamquest.subscription.monthly",
  "产品名称": "月付订阅",
  "价格": "$4.99",
  "交易 ID": "2000000123456789",
  "购买时间": "2024-03-24 10:30:00",
  "开始日期": "2024-03-24",
  "结束日期": "2024-04-23",
  "自动续订": true,
  "设备型号": "iPhone 15 Pro",
  "iOS 版本": "iOS 17.4",
  "应用版本": "1.0.0"
}
```

### 问题记录模板

如果测试中发现问题，使用以下模板记录：

```
问题描述:
-
-

重现步骤:
1.
2.
3.

预期行为:
-
-

实际行为:
-
-

错误日志:
-

截图/视频:
-
-
```

---

## 六、完成测试后

### 6.1 清理测试数据

测试完成后，建议执行以下清理操作：

- [ ] 删除测试订阅记录
  - 设备设置 → Apple ID → Subscriptions → 取消测试订阅

- [ ] 清理应用内测试数据
  - 删除应用或清除应用数据

- [ ] 恢复设备系统时间
  - 设置 → 通用 → 日期与时间 → 自动设置

- [ ] 重新登录真实 App Store 账号
  - 设置 → iTunes & App Store

### 6.2 上线前检查清单

- [ ] 所有测试场景通过
- [ ] 沙盒测试账号正常工作
- [ ] 产品配置正确
- [ ] Bundle Identifier 正确
- [ ] 代码签名配置正确
- [ ] 隐私政策 URL 已配置
- [ ] 应用审核信息完整
- [ ] 应用描述和截图准备完毕

---

## 七、参考资源

### 官方文档

- [Apple In-App Purchase 编程指南](https://developer.apple.com/in-app-purchase/)
- [App Store Connect 帮助](https://help.apple.com/app-store-connect/)
- [TestFlight 测试指南](https://help.apple.com/app-store-connect/#/devdc42b1b02)

### 相关文件

**代码文件**:
- `lib/data/repositories/subscription_repository.dart` - IAP 处理逻辑
- `lib/features/subscription/subscription_page.dart` - 订阅页面
- `lib/core/constants/app_constants.dart` - 产品 ID 配置

**测试文件**:
- `test/unit/data/models/subscription_model_test.dart` - 模型测试
- `test/unit/data/repositories/subscription_repository_test.dart` - 仓库测试
- `test/widgets/subscription/subscription_page_widget_test.dart` - Widget 测试

### 测试脚本

```bash
# 在真机上运行应用
flutter run --release

# 查看 IAP 相关日志
flutter logs | grep -i "subscription\|purchase\|iap\|premium"

# 运行单元测试
flutter test

# 生成测试覆盖率报告
flutter test --coverage
```

---

## 八、常见问题 FAQ

### Q1: 沙盒账号会真的扣费吗？

**A**: 不会。沙盒测试账号是专门用于测试的，不会产生真实费用。即使显示扣款金额，也只是模拟，不会实际扣款。

### Q2: 测试账号需要使用真实的邮箱吗？

**A**: 需要。但这个邮箱不能是已经注册为 Apple ID 的邮箱。建议使用 `test+别名@域名.com` 格式。

### Q3: 可以在模拟器上测试 IAP 吗？

**A**: 不可以。IAP 必须在真机上测试。模拟器不支持应用内购买。

### Q4: 沙盒订阅多久会过期？

**A**: 取决于您购买的订阅类型：
- 月付：30 天后过期
- 季付：90 天后过期
- 年付：365 天后过期

### Q5: 如何加速测试过期场景？

**A**: 可以通过修改设备系统时间来模拟时间流逝：
1. 设置 → 通用 → 日期与时间
2. 关闭"自动设置"
3. 手动调整日期
4. 重启应用

### Q6: 购买记录在哪里查看？

**A**:
- 设备上：设置 → Apple ID → Subscriptions
- App Store Connect：Sales and Trends

---

*文档最后更新: 2024-03-24*
