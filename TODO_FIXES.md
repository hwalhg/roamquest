# 开发修复任务清单

**生成日期:** 2026-03-18
**优先级:** P0 > P1 > P2

---

## P0 - 阻塞性问题 (必须立即修复)

### [ ] 1. 修复 home_page.dart 文件内容异常
**文件:** `lib/features/home/home_page.dart`
**严重程度:** 🔴 阻塞编译
**问题描述:**
- 文件内容异常，包含重复的代码片段注释
- 导致 20+ 个编译错误
- 影响：整个应用无法编译运行

**修复方案:**
1. 从 Git 历史恢复文件:
   ```bash
   git checkout HEAD~ lib/features/home/home_page.dart
   # 或查看历史版本:
   git log --oneline lib/features/home/home_page.dart
   ```

2. 或参考其他页面结构重新实现

3. 修复后验证:
   ```bash
   flutter analyze lib/features/home/home_page.dart
   flutter run
   ```

**预期代码结构:**
```dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/checklist.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/repositories/city_repository.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/subscription_status_service.dart';
import '../../l10n/app_localizations.dart';
import 'city_selection_bottom_sheet.dart';
import '../checklist/checklist_page.dart';
import '../subscription/city_subscription_page.dart';

/// Home page - Main entry for city exploration
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ... 实现
}
```

---

## P1 - 功能性问题 (建议尽快修复)

### [ ] 2. 添加 Uuid 导入
**文件:** `lib/data/services/storage_service.dart`
**位置:** 第 238 行

**修复前:**
```dart
final itemId = const Uuid().v4(); // ❌ Uuid 未导入
```

**修复后:**
```dart
// 在文件顶部添加:
import 'package:uuid/uuid.dart';
```

---

### [ ] 3. 批量替换废弃的 withOpacity() API

**影响文件:**
- `lib/features/auth/login_page.dart` (12 处)
- `lib/features/auth/profile_setup_page.dart` (6 处)
- `lib/features/checklist/checklist_page.dart` (4 处)
- `lib/features/checkin/checkin_page.dart` (1 处)
- `lib/features/home/city_selection_bottom_sheet.dart` (3 处)

**批量替换:**
```bash
# 查找所有使用 withOpacity 的地方
grep -rn "withOpacity" lib/features/

# 替换模式:
# .withOpacity(0.x) -> .withValues(alpha: 0.x)
# .withOpacity(0.xX) -> .withValues(alpha: 0.xX)
```

**手动修复示例:**
```dart
// 修复前
AppColors.textOnDark.withOpacity(0.2)

// 修复后
AppColors.textOnDark.withValues(alpha: 0.2)

// 修复前
color.withOpacity(0.5)

// 修复后
color.withValues(alpha: 0.5)
```

---

### [ ] 4. 修复 null 比较问题

**文件:** `lib/data/repositories/city_repository.dart`
**位置:** 第 21 行

**修复前:**
```dart
if (response == null) {  // ❌ Supabase 返回空列表
  AppLogger.warning('No cities found in database');
  return [];
}
```

**修复后:**
```dart
if (response.isEmpty) {  // ✅ 正确检查
  AppLogger.warning('No cities found in database');
  return [];
}
```

---

### [ ] 5. 修复 auth_service.dart 中的 null 比较

**文件:** `lib/data/services/auth_service.dart`
**位置:** 第 179, 201 行

**修复前:**
```dart
final response = await _client.from('profiles')
    .select()
    .eq('id', currentUserId!)
    .maybeSingle();  // 返回 null 或 Map

if (response == null) {  // ❌ 可能为空列表
  return null;
}
```

**修复后:**
```dart
if (response == null || (response is Map && response.isEmpty)) {
  return null;
}
```

---

## P2 - 代码清理 (有时间时修复)

### [ ] 6. 清理未使用的导入

**清理列表:**
```bash
# 移除以下未使用的导入:
lib/features/auth/login_page.dart:
  - import 'package:flutter/foundation.dart';  # kIsWeb 未使用
  - import 'package:geolocator/geolocator.dart';  # 未使用

lib/features/auth/profile_setup_page.dart:
  - import '../../core/constants/app_constants.dart';  # 未使用
  - import '../../data/models/profile.dart';  # 未使用

lib/features/checkin/checkin_page.dart:
  - import 'package:flutter/foundation.dart';  # kIsWeb 未使用
  - import 'package:geolocator/geolocator.dart';  # 未使用
```

---

### [ ] 7. 清理未使用的变量

**清理列表:**
- `lib/features/auth/login_page.dart`: `credential` 变量 (第 568 行)
- `lib/data/services/storage_service.dart`: `response` 变量 (第 86 行)
- `lib/features/checklist/checklist_page.dart`: `_isLoadingItems` 字段

---

### [ ] 8. 添加 const 优化

**优化建议:**
```dart
// 优化前
Container(
  color: AppColors.primary,  // AppColors.primary 已是 const
  child: Text('Hello'),
)

// 优化后
const Container(
  color: AppColors.primary,
  child: Text('Hello'),
)

// 优化前
Text('Title', style: AppTextStyles.h4)

// 优化后
Text('Title', style: AppTextStyles.h4)  // h4 已是 const
```

---

### [ ] 9. 调整 Widget 参数顺序

**文件:** `lib/core/widgets/app_bottom_sheet.dart`
**位置:** 第 34 行

**修复前:**
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: AppColors.surface,
  isScrollControlled: true,
  children: [  // ❌ children 应该在最后
    // ...
  ],
  isDismissible: true,
);
```

**修复后:**
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: AppColors.surface,
  isScrollControlled: true,
  isDismissible: true,
  builder: (context) => ...,  // ✅ 使用 builder 或调整参数顺序
);
```

---

### [ ] 10. 添加 LocationService 实现

**文件:** `lib/data/services/location_service.dart`
**问题:** 文件读取异常，内容不完整

**修复方案:**
```dart
import 'package:geolocator/geolocator.dart';
import '../../core/utils/app_logger.dart';

/// Service for location operations
class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('Location service disabled');
      return Future.error('Location service disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      AppLogger.warning('Location permission denied');
      return Future.error('Location permission denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
```

---

## 验证步骤

### 完成所有修复后执行:

```bash
# 1. 清理并重新获取依赖
flutter clean
flutter pub get

# 2. 运行静态分析
flutter analyze

# 3. 修复所有错误和警告

# 4. 运行测试
flutter test

# 5. 运行应用
flutter run
```

---

## 参考资源

- [Flutter 废弃 API 迁移指南](https://docs.flutter.dev/release/breaking-changes/color-withopacity-and-withalpha-deprecation)
- [Flutter 代码分析工具](https://dart.dev/guides/language/analysis-options)
- [Equatable 包文档](https://pub.dev/packages/equatable)
- [Supabase Flutter 文档](https://supabase.com/docs/reference/dart)

---

**最后更新:** 2026-03-18
