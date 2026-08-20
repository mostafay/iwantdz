// ملف إعدادات التطبيق
class AppConfig {
  // عنوان IP السيرفر
  static const String serverUrl = 'http://192.168.0.167:3000';
  
  // روابط API
  static String get loginUrl => '$serverUrl/api/login-user';
  static String get registerUrl => '$serverUrl/api/register-user';
  static String get loginByOidUrl => '$serverUrl/api/login-by-oid';
  static String get updateUserPositionUrl => '$serverUrl/api/update-user-position';
  static String get getAllUsersPositionsUrl => '$serverUrl/api/get-all-users-positions';
  static String get updateUserBidUrl => '$serverUrl/api/update-user-bid'; // لتغيير BID يدوياً لأغراض الاختبار
}
