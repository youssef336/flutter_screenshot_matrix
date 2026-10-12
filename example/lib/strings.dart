import 'package:flutter/widgets.dart';

/// A tiny hand-rolled localization table (a real app would use intl / ARB).
class Strings {
  const Strings._(this._values);

  static const List<Locale> supported = <Locale>[Locale('en'), Locale('ar')];

  static Strings of(BuildContext context) {
    final String code = Localizations.localeOf(context).languageCode;
    return Strings._(_table[code] ?? _table['en']!);
  }

  final Map<String, String> _values;

  String get(String key) => _values[key] ?? key;

  static const Map<String, Map<String, String>> _table =
      <String, Map<String, String>>{
        'en': <String, String>{
          'welcome': 'Welcome back',
          'subtitle': 'Sign in to continue to your account',
          'email': 'Email',
          'password': 'Password',
          'signIn': 'Sign in',
          'forgot': 'Forgot password?',
          'noAccount': 'New here? Create an account',
          'profile': 'Profile',
          'name': 'Youssef Belal',
          'bio':
              'Flutter developer. Building tools that make UI bugs show up '
              'before users find them.',
          'followers': 'Followers',
          'following': 'Following',
          'posts': 'Posts',
          'follow': 'Follow',
          'message': 'Message',
          'verified': 'Verified creator',
          'settings': 'Settings',
          'account': 'Account',
          'notifications': 'Push notifications',
          'darkMode': 'Dark mode',
          'language': 'Language',
          'languageValue': 'English',
          'privacy': 'Privacy',
          'help': 'Help center',
          'logout': 'Log out',
        },
        'ar': <String, String>{
          'welcome': 'أهلاً بيك تاني',
          'subtitle': 'سجّل دخولك عشان تكمّل على حسابك',
          'email': 'البريد الإلكتروني',
          'password': 'كلمة السر',
          'signIn': 'تسجيل الدخول',
          'forgot': 'نسيت كلمة السر؟',
          'noAccount': 'أول مرة هنا؟ اعمل حساب جديد',
          'profile': 'الملف الشخصي',
          'name': 'يوسف بلال',
          'bio':
              'مطوّر Flutter. بيعمل أدوات بتخلّي مشاكل الواجهة تبان قبل ما '
              'المستخدمين يلاقوها.',
          'followers': 'المتابِعين',
          'following': 'بيتابع',
          'posts': 'المنشورات',
          'follow': 'متابعة الحساب',
          'message': 'إرسال رسالة خاصة',
          'verified': 'صانع محتوى موثّق رسميًا',
          'settings': 'الإعدادات',
          'account': 'الحساب',
          'notifications': 'الإشعارات',
          'darkMode': 'الوضع الليلي',
          'language': 'اللغة',
          'languageValue': 'العربية',
          'privacy': 'الخصوصية',
          'help': 'مركز المساعدة',
          'logout': 'تسجيل الخروج',
        },
      };
}
