import 'dart:async';
import 'package:flutter/material.dart';

/// AppLocalizations class for internationalization
class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  final Locale locale;

  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'appName': 'RoamQuest',
      'appSlogan': 'Explore cities, discover wonders',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'ok': 'OK',

      // Auth
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'continueWithApple': 'Continue with Apple',
      'appleOnlyAuthTitle': 'Sign in with Apple',
      'appleOnlyAuthSubtitle':
          'Use your Apple account to sign in securely and restore your subscription across devices.',
      'email': 'Email',
      'password': 'Password',
      'passwordMin': 'Password (min 6 characters)',
      'dontHaveAccount': "Don't have an account? ",
      'alreadyHaveAccount': 'Already have an account? ',
      'loginFailed': 'Login failed. Please check your credentials.',
      'signupFailed': 'Sign up failed. This email may already be in use.',
      'pleaseEnterEmail': 'Please enter your email',
      'pleaseEnterValidEmail': 'Please enter a valid email',
      'pleaseEnterPassword': 'Please enter your password',
      'passwordTooShort': 'Password must be at least 6 characters',

      // Home
      'createChecklist': 'Create Checklist',
      'detectLocation': '📍 Detect My Location',
      'selectFromList': '🏙️ Select from List',
      'recentExplorations': 'Recent Explorations',
      'startedCities': 'City Checklists',
      'customLists': 'Custom Checklists',
      'customListsHint': 'Keep your own routes, themes, and free-form spot lists here.',
      'noStartedCities': 'No city checklists yet',
      'startedCitiesHint': 'Create a city checklist to start tracking places.',
      'pullToRefreshLists': 'Pull down to refresh your lists',
      'completed': 'Completed',
      'experiences': 'experiences',
      'all': 'All',
      'progress': 'Exploration Progress',
      'share': 'Share',

      // Checklist
      'landmark': 'Landmark',
      'food': 'Food',
      'experience': 'Experience',
      'hiddenGem': 'Hidden Gem',
      'freeCheckin': 'FREE',
      'premiumOnly': 'Premium',
      'addSpot': 'Add Spot',
      'addCustomSpot': 'Add Spot',
      'addCustomSpotDesc':
          'Add your own spot to this checklist and check in right away.',
      'spotName': 'Spot Name',
      'spotNameHint': 'e.g. Sunset Pier',
      'spotLocation': 'Location or Note',
      'spotLocationHint': 'Optional note for this spot',
      'customSpotCategory': 'Category',
      'useCurrentLocation': 'Use Current Location',
      'currentLocationSaved': 'Current location saved for this spot',
      'currentLocationUnavailable':
          'Could not get your current location. You can still save the spot without coordinates.',
      'customSpotPrivateNote': 'Custom spots stay private to your checklist.',
      'customSpotBadge': 'Custom',
      'saveAndCheckin': 'Save and Check In',
      'createCustomChecklist': 'Create Custom Checklist',
      'createCustomChecklistDesc':
          'Create your own checklist without city or location limits.',
      'customChecklistTitle': 'Checklist Title',
      'customChecklistTitleHint': 'e.g. Weekend Photo Hunt',
      'customChecklistDescription': 'Description',
      'customChecklistDescriptionHint':
          'Optional notes, theme, or route for this list',
      'saveChecklistAndAddSpot': 'Create Checklist',
      'customChecklistEmptyTitle': 'Your custom checklist is ready',
      'customChecklistEmptyDesc':
          'Add your first spot to start building this list.',
      'emptyChecklistTitle': 'No spots yet',
      'emptyChecklistDesc': 'Add a spot to start this checklist.',
      'editChecklist': 'Edit Checklist',
      'pleaseEnterSpotName': 'Please enter a spot name',
      'pleaseEnterChecklistTitle': 'Please enter a checklist title',
      'farFromSpotTitle': 'Far from this spot?',
      'farFromSpotPrefix': 'You appear to be about',
      'farFromSpotSuffix': 'away from this spot. Continue anyway?',
      'continueAnyway': 'Continue Anyway',

      // Checkin
      'checkin': 'Check-in',
      'captureMoment': 'Capture the Moment',
      'captureMomentDesc': 'Take a photo to mark this experience as complete',
      'takePhoto': 'Take Photo',
      'selectFromGallery': 'Select from Gallery',
      'completeCheckin': 'Complete Check-in',
      'noPhotoSelected': 'No photo selected',
      'photoSelected': 'Photo selected',
      'checkinComplete': 'Check-in complete! Great job! 🎉',
      'checkinFailed': 'Check-in failed',

      // Report
      'shareDiary': 'Share Diary',
      'diary': 'Diary',
      'shareJourney': 'Share Your Journey',
      'experiencesIn': 'experiences in',
      'saveShareImage': 'Save & Share Image',
      'shareSuccess': 'Image captured! Sharing...',

      // Subscription
      'upgradePremium': 'Upgrade Premium',
      'unlockUnlimited': 'Unlock unlimited city exploration',
      'premiumFeatures': 'Premium Features',
      'restorePurchaseCompleted': 'Purchase restored',

      // Terms & Privacy
      'agreeToTerms': 'I agree to the Terms of Service and Privacy Policy',
      'mustAgreeToTerms':
          'Please agree to the Terms of Service and Privacy Policy',
      'unlimitedCheckin': 'Unlimited Check-ins',
      'unlimitedCheckinDesc': 'Complete all 20 experiences in each city',
      'fullReport': 'Full Reports',
      'fullReportDesc': 'Beautiful reports with all your memories',
      'downloadShare': 'Download & Share',
      'downloadShareDesc': 'Save reports and share with friends',
      'monthly': 'Monthly',
      'quarterly': 'Quarterly',
      'yearly': 'Yearly',
      'subscribeNow': 'Subscribe Now',
      'restorePurchase': 'Restore Purchase',
      'termsOfService': 'By subscribing, you agree to our',
      'termsAndPrivacy': 'Terms of Service and Privacy Policy',
      'autoRenew':
          'Subscription will auto-renew unless cancelled at least 24h before expiration. All cities are unlocked during subscription.',
      'howToCancel': 'How to cancel subscription?',
      'webNotSupported': 'Web platform does not support subscriptions',
      'webNotSupportedDesc':
          'Please use iOS or Android device for subscription',
      'paymentFailed': 'Payment failed',
      'paymentFailedDesc': 'Unable to complete purchase, please try again.',
      'welcomePremium': 'Welcome to Premium!',
      'unlimitedCity': 'You can now explore unlimited cities',
      'currentSubscription': 'Current subscription',
      'premiumAccessActiveDesc':
          'Your Premium access is active. Change or cancel your plan in Apple subscriptions.',
      'manageInApple': 'Manage in Apple',
      'statusLabel': 'Status',
      'planLabel': 'Plan',
      'renewalLabel': 'Renewal',
      'accessLabel': 'Access',
      'activeStatus': 'Active',
      'notSubscribedStatus': 'Not subscribed',
      'allCitiesUnlockedShort': 'All cities unlocked',
      'premiumAccess': 'Premium Access',
      'premiumAccessInactiveDesc':
          'Unlock all cities and unlimited check-ins.',
      'viewPremium': 'View Premium',
      'managePremium': 'Manage Premium',
      'privacyPolicy': 'Privacy Policy',
      'subscriptionExpiredStatus': 'Subscription Expired',
      'subscriptionExpiringSoonStatus': 'Expiring Soon',
      'subscriptionActiveStatus': 'Active Subscription',
      'renewsOn': 'Renews on',
      'expiredOn': 'Expired on',
      'appleManagesRenewals': 'Apple manages renewals and plan changes after',
      'appleManageBillingFallback':
          'Open Apple subscriptions to manage billing and plan changes',
      'startExploring': 'Start Exploring',
      'freeCity': 'This city is currently free to unlock!',
      'oneTimePurchase': 'One time purchase, permanent access',
      'freeTierRemaining': 'Free tier remaining:',
      'shareDiaryFree': 'Share your diary is always free!',
      'later': 'Later',
      'unlockFree': 'Unlock Free',
      'unlock': 'Unlock',

      // Premium Info
      'aboutPremium': 'About Premium',
      'freeTier': 'Free Tier',
      'freeTierDesc': 'Explore 5 experiences per city for free',
      'freeTierItems':
          '• 2 landmarks\n• 1 food\n• 1 experience\n• 1 hidden gem',
      'premiumTier': 'Premium',
      'premiumTierDesc': 'Unlock full experiences in each city',
      'premiumTierItems':
          '• All 20 experiences\n• Unlimited check-ins\n• Full reports\n• Download & share',
      'howToUnlock': 'How to Unlock',
      'step1': '1. Go to a city checklist',
      'step2': '2. Tap on any locked item',
      'step3': '3. Subscribe to unlock the entire city',

      // Subscription Info Page
      'unlockCity': 'Unlock City',
      'unlockAll20': 'Unlock all 20 experiences',
      'exploreCityEssence': 'Fully explore the essence of this city',
      'permanentAccess': 'Permanent Access',
      'oneTimeForever': 'Once unlocked, forever valid',
      'flexibleSubscription': 'Flexible Subscription',
      'payForInterestedCity': 'Only pay for cities you\'re interested in',
      'permanentSave': 'Permanently save check-in records',
      'photoLocationSafe': 'Photos and locations are safely saved',
      'shareDiaryTitle': 'Share exploration diary',
      'shareDiaryDesc': 'Generate beautiful reports to share with friends',
      'step1Title': 'Create checklist',
      'step1Desc': 'Choose the city you want to explore',
      'step2Title': 'Start checking in',
      'step2Desc': 'Complete 5 free experiences',
      'step3Title': 'Unlock city',
      'step3Desc': 'Unlock all content after reaching the limit',

      // Navigation
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'about': 'About',

      // Profile
      'editProfile': 'Edit Profile',
      'nickname': 'Nickname',
      'bio': 'Bio',
      'saveChanges': 'Save Changes',
      'logout': 'Logout',
      'logoutConfirm': 'Are you sure you want to logout?',

      // City Selection
      'selectCity': 'Select City',
      'noCitiesFound': 'No cities found',
      'searchCity': 'Search city...',

      // Common
      'back': 'Back',
      'close': 'Close',
      'next': 'Next',
      'done': 'Done',
      'retryLater': 'Retry Later',
    },
    'zh': {
      // App
      'appName': 'RoamQuest',
      'appSlogan': '探索城市，发现奇迹',
      'loading': '加载中...',
      'error': '错误',
      'retry': '重试',
      'cancel': '取消',
      'confirm': '确认',
      'save': '保存',
      'delete': '删除',
      'ok': '确定',

      // Auth
      'signIn': '登录',
      'signUp': '注册',
      'continueWithApple': '使用 Apple 登录',
      'appleOnlyAuthTitle': '使用 Apple 登录',
      'appleOnlyAuthSubtitle': '使用你的 Apple 账号安全登录，并在不同设备间恢复订阅。',
      'email': '邮箱',
      'password': '密码',
      'passwordMin': '密码（至少6位）',
      'dontHaveAccount': '还没有账号？',
      'alreadyHaveAccount': '已有账号？',
      'loginFailed': '登录失败，请检查账号密码',
      'signupFailed': '注册失败，该邮箱已被使用',
      'pleaseEnterEmail': '请输入邮箱',
      'pleaseEnterValidEmail': '请输入有效的邮箱',
      'pleaseEnterPassword': '请输入密码',
      'passwordTooShort': '密码至少需要6位',

      // Home
      'createChecklist': '创建清单',
      'detectLocation': '📍 定位当前城市',
      'selectFromList': '🏙️ 从列表选择',
      'recentExplorations': '最近探索',
      'startedCities': '城市清单',
      'customLists': '自定义清单',
      'customListsHint': '把你自己的路线、主题和自由景点清单放在这里。',
      'noStartedCities': '还没有城市清单',
      'startedCitiesHint': '创建一个城市清单，开始记录你的地点。',
      'pullToRefreshLists': '下拉刷新你的清单',
      'completed': '已完成',
      'experiences': '个体验',
      'all': '全部',
      'progress': '探索进度',
      'share': '分享',

      // Checklist
      'landmark': '地标',
      'food': '美食',
      'experience': '体验',
      'hiddenGem': '秘境',
      'freeCheckin': '免费',
      'premiumOnly': '订阅',
      'addSpot': '添加景点',
      'addCustomSpot': '添加景点',
      'addCustomSpotDesc': '把你自己的景点加入当前清单，并立即开始打卡。',
      'spotName': '景点名称',
      'spotNameHint': '例如：日落码头',
      'spotLocation': '位置或备注',
      'spotLocationHint': '可选的地点说明或备注',
      'customSpotCategory': '分类',
      'useCurrentLocation': '使用当前位置',
      'currentLocationSaved': '已为该景点保存当前位置',
      'currentLocationUnavailable': '无法获取当前位置。你仍然可以在没有坐标的情况下保存这个景点。',
      'customSpotPrivateNote': '自定义景点仅保存在你的当前清单中。',
      'customSpotBadge': '自定义',
      'saveAndCheckin': '保存并去打卡',
      'createCustomChecklist': '创建自定义清单',
      'createCustomChecklistDesc': '创建你自己的清单，不受城市或地理位置限制。',
      'customChecklistTitle': '清单标题',
      'customChecklistTitleHint': '例如：周末拍照路线',
      'customChecklistDescription': '清单说明',
      'customChecklistDescriptionHint': '可选的主题、路线或备注',
      'saveChecklistAndAddSpot': '创建清单',
      'customChecklistEmptyTitle': '你的自定义清单已创建',
      'customChecklistEmptyDesc': '先添加第一个景点，开始构建这份清单。',
      'emptyChecklistTitle': '还没有景点',
      'emptyChecklistDesc': '添加一个景点来开始这份清单。',
      'editChecklist': '编辑清单',
      'pleaseEnterSpotName': '请输入景点名称',
      'pleaseEnterChecklistTitle': '请输入清单标题',
      'farFromSpotTitle': '你离这个景点有点远？',
      'farFromSpotPrefix': '你当前距离这个景点大约',
      'farFromSpotSuffix': '，仍要继续打卡吗？',
      'continueAnyway': '仍然继续',

      // Checkin
      'checkin': '打卡',
      'captureMoment': '记录这一刻',
      'captureMomentDesc': '拍照完成此次体验',
      'takePhoto': '拍照',
      'selectFromGallery': '从相册选择',
      'completeCheckin': '完成打卡',
      'noPhotoSelected': '未选择照片',
      'photoSelected': '照片已选择',
      'checkinComplete': '打卡完成！做得好！🎉',
      'checkinFailed': '打卡失败',

      // Report
      'shareDiary': '分享日记',
      'diary': '日记',
      'shareJourney': '分享你的旅程',
      'experiencesIn': '个体验在',
      'saveShareImage': '保存并分享图片',
      'shareSuccess': '图片已捕获！正在分享...',

      // Subscription
      'upgradePremium': '升级高级版',
      'unlockUnlimited': '解锁无限城市探索',
      'premiumFeatures': '高级版功能',
      'restorePurchaseCompleted': '购买已恢复',

      // Terms & Privacy
      'agreeToTerms': '我同意服务条款和隐私政策',
      'mustAgreeToTerms': '请同意服务条款和隐私政策',
      'unlimitedCheckin': '无限打卡',
      'unlimitedCheckinDesc': '完成每个城市的全部20个体验',
      'fullReport': '完整报告',
      'fullReportDesc': '包含所有回忆的精美报告',
      'downloadShare': '下载与分享',
      'downloadShareDesc': '保存报告并与朋友分享',
      'monthly': '月付',
      'quarterly': '季付',
      'yearly': '年付',
      'savings': '节省',
      'subscribeNow': '立即订阅',
      'restorePurchase': '恢复购买',
      'termsOfService': '订阅即表示您同意我们的',
      'termsAndPrivacy': '服务条款和隐私政策',
      'autoRenew': '订阅将自动续订，除非在到期前至少24小时取消。订阅期间可解锁所有城市。',
      'howToCancel': '如何取消订阅？',
      'webNotSupported': 'Web平台暂不支持订阅',
      'webNotSupportedDesc': '请在iOS或Android设备上使用订阅功能',
      'paymentFailed': '支付失败',
      'paymentFailedDesc': '无法完成购买，请重试。',
      'welcomePremium': '欢迎升级高级版！',
      'unlimitedCity': '您现在可以无限探索城市',
      'currentSubscription': '当前订阅',
      'premiumAccessActiveDesc': '你的 Premium 已生效。套餐变更和取消请前往 Apple 订阅中管理。',
      'manageInApple': '前往 Apple 管理',
      'statusLabel': '状态',
      'planLabel': '套餐',
      'renewalLabel': '续期',
      'accessLabel': '权限',
      'activeStatus': '已生效',
      'notSubscribedStatus': '未订阅',
      'allCitiesUnlockedShort': '全部城市已解锁',
      'premiumAccess': 'Premium 权益',
      'premiumAccessInactiveDesc': '解锁全部城市和无限打卡。',
      'viewPremium': '查看 Premium',
      'managePremium': '管理 Premium',
      'privacyPolicy': '隐私政策',
      'subscriptionExpiredStatus': '订阅已过期',
      'subscriptionExpiringSoonStatus': '即将到期',
      'subscriptionActiveStatus': '订阅生效中',
      'renewsOn': '续期时间',
      'expiredOn': '过期时间',
      'appleManagesRenewals': 'Apple 会在此时间后管理续订和套餐变更',
      'appleManageBillingFallback': '前往 Apple 订阅管理账单和套餐变更',
      'startExploring': '开始探索',
      'freeCity': '此城市当前可免费解锁！',
      'oneTimePurchase': '一次性购买，永久访问',
      'freeTierRemaining': '免费版剩余：',
      'shareDiaryFree': '分享日记始终免费！',
      'later': '稍后',
      'unlockFree': '免费解锁',
      'unlock': '解锁',

      // Premium Info
      'aboutPremium': '关于高级版',
      'freeTier': '免费版',
      'freeTierDesc': '每个城市免费体验5个',
      'freeTierItems': '• 2个地标\n• 1个美食\n• 1个体验\n• 1个秘境',
      'premiumTier': '高级版',
      'premiumTierDesc': '解锁每个城市的全部体验',
      'premiumTierItems': '• 全部20个体验\n• 无限打卡\n• 完整报告\n• 下载与分享',
      'howToUnlock': '如何解锁',
      'step1': '1. 进入城市清单',
      'step2': '2. 点击任意锁定项目',
      'step3': '3. 订阅解锁整个城市',

      // Subscription Info Page
      'unlockCity': '解锁城市',
      'unlockAll20': '解锁所有 20 个体验',
      'exploreCityEssence': '完整探索这座城市的精华',
      'permanentAccess': '永久访问',
      'oneTimeForever': '一次解锁，永远有效',
      'flexibleSubscription': '灵活订阅',
      'payForInterestedCity': '只为感兴趣的城市付费',
      'permanentSave': '永久保存打卡记录',
      'photoLocationSafe': '照片和位置都会安全保存',
      'shareDiaryTitle': '分享探索日记',
      'shareDiaryDesc': '生成精美报告与朋友分享',
      'step1Title': '创建清单',
      'step1Desc': '选择你想探索的城市',
      'step2Title': '开始打卡',
      'step2Desc': '完成 5 个免费体验',
      'step3Title': '解锁城市',
      'step3Desc': '达到限制后即可解锁所有内容',

      // Navigation
      'home': '首页',
      'profile': '我的',
      'settings': '设置',
      'about': '关于',

      // Profile
      'editProfile': '编辑资料',
      'nickname': '昵称',
      'bio': '简介',
      'saveChanges': '保存更改',
      'logout': '退出登录',
      'logoutConfirm': '确定要退出登录吗？',

      // City Selection
      'selectCity': '选择城市',
      'noCitiesFound': '未找到城市',
      'searchCity': '搜索城市...',

      // Common
      'back': '返回',
      'close': '关闭',
      'next': '下一步',
      'done': '完成',
      'retryLater': '稍后重试',
    },
  };

  /// Get localized string by key
  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  /// Convenience getters for commonly used strings

  // App
  String get appName => get('appName');
  String get appSlogan => get('appSlogan');
  String get loading => get('loading');

  // Auth
  String get signIn => get('signIn');
  String get signUp => get('signUp');
  String get continueWithApple => get('continueWithApple');
  String get appleOnlyAuthTitle => get('appleOnlyAuthTitle');
  String get appleOnlyAuthSubtitle => get('appleOnlyAuthSubtitle');
  String get email => get('email');
  String get password => get('password');
  String get passwordMin => get('passwordMin');
  String get dontHaveAccount => get('dontHaveAccount');
  String get alreadyHaveAccount => get('alreadyHaveAccount');
  String get loginFailed => get('loginFailed');
  String get signupFailed => get('signupFailed');

  // Home
  String get createChecklist => get('createChecklist');
  String get detectLocation => get('detectLocation');
  String get selectFromList => get('selectFromList');
  String get recentExplorations => get('recentExplorations');

  // Checklist
  String get landmark => get('landmark');
  String get food => get('food');
  String get experience => get('experience');
  String get hiddenGem => get('hiddenGem');
  String get freeCheckin => get('freeCheckin');
  String get addSpot => get('addSpot');
  String get addCustomSpot => get('addCustomSpot');

  // Checkin
  String get checkin => get('checkin');
  String get captureMoment => get('captureMoment');
  String get captureMomentDesc => get('captureMomentDesc');
  String get takePhoto => get('takePhoto');
  String get selectFromGallery => get('selectFromGallery');
  String get completeCheckin => get('completeCheckin');
  String get noPhotoSelected => get('noPhotoSelected');

  // Subscription
  String get upgradePremium => get('upgradePremium');
  String get unlockUnlimited => get('unlockUnlimited');
  String get startExploring => get('startExploring');
  String get premiumFeatures => get('premiumFeatures');
  String get ok => get('ok');
  String get subscribeNow => get('subscribeNow');
  String get restorePurchase => get('restorePurchase');
  String get paymentFailed => get('paymentFailed');
  String get welcomePremium => get('welcomePremium');
  String get unlimitedCity => get('unlimitedCity');

  // Subscription Info Page
  String get freeTier => get('freeTier');
  String get freeTierDesc => get('freeTierDesc');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
