import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iwantdz/BottomSheets.dart';
import 'package:iwantdz/container_grid_page.dart';
import 'package:iwantdz/curved/curved_navigation_bar.dart';
import 'package:iwantdz/curved/curved_navigation_bar_item.dart';
import 'package:iwantdz/mapscreen.dart';
import 'package:iwantdz/sign.dart';
import 'package:iwantdz/curved/src/storage_helper.dart';
import 'package:iwantdz/config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:iwantdz/map_screen.dart'; // Uncomment if MapScreen exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedOid = await StorageHelper.loadOid();
  final savedBID = await StorageHelper.loadBID();
  MainNavigation.sineKey = savedOid;
  MainNavigation.sineBID = savedBID;
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: BottomNavBar()));
}

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  int _page = 0;
  int _page2 = 0; // متغير منفصل للصفحات الموسعة
  int _Oldpage = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  Key _navBarKey = UniqueKey(); // لتغيير المفتاح عند التبديل بين الأوضاع
  final BottomSheetsPageController _sheetController =
      BottomSheetsPageController();
  // Changed: Initialize with default value instead of late
  bool mune_opned = false;
  bool showAddPost = false;
  bool showProfile = false;
  bool _isLoading = false;
  double refresh_hieght = 0;
  double refresh_hieghtP3 = 0;
  double refresh_hieghtP2 = 0;
  late AnimationController _navBarHeightController;
  late Animation<double> _navBarHeightAnimation;
  bool _navBarAnimationInitialized = false;
  late AnimationController _downChildHeightController;
  late AnimationController _downChildHeightControllerP2;
  late Animation<double> _downChildHeightAnimation;
  late Animation<double> _downChildHeightAnimationP2;
  late AnimationController _downChildHeightControllerP3;
  late Animation<double> _downChildHeightAnimationP3;
  late AnimationController _instantNotificationController;
  late Animation<double> _instantNotificationAnimation;
  String _instantNotificationMessage = 'إشعار جديد';
  Color _instantNotificationColor = Colors.green.withOpacity(0.8);
  final ValueNotifier<int> _downChildRefreshNotifier = ValueNotifier<int>(0);
  String _dropdownValue2 = '1';
  String _dropdownValue = 'Item 1';
  String HOST = '192.168.0.167';
  bool _showMapInContent = false;
  List<String> _imageUrls = []; // قائمة روابط الصور
  final ImagePicker _imagePicker = ImagePicker(); // لاختيار الصور من المعرض
  final TextEditingController _hostController1 = TextEditingController();
  final TextEditingController _hostController2 = TextEditingController();
  bool _isNavBarAnimationComplete = false; // لمراقبة انتهاء انيميشن الارتفاع
  bool _isNotificationMode = false; // لتمييز وضع الإشعارات عن الإعدادات
  bool _isPopupNotification =
      false; // لتمييز الإشعارات المنبثقة عن الإشعارات داخل الشريط
  OverlayEntry? _notificationOverlay; // للمنبثق الحقيقي
  Map<String, dynamic> Settings = {
    'settings_enabled': true,
    'location_enabled': true,
  }; // متغير الإعدادات

  // Controllers for addPost
  final TextEditingController _postNameController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _postInfoController = TextEditingController();

  // Timers for heartbeat and notifications
  Timer? _heartbeatTimer;
  Timer? _notificationTimer;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _activeUsers = [];
  List<Map<String, dynamic>> _userNotifications = [];
  bool _isLoadingActiveUsers = false;
  bool _isLoadingNotifications = false;
  bool _isListeningToNotifications = false;
  bool _isListeningToActiveUsers = false;
  StreamSubscription? _activeUsersStreamSubscription;

  @override
  void initState() {
    super.initState();

    // تهيئة قائمة الصور
    _imageUrls = List.generate(
      3,
      (index) => 'https://picsum.photos/100/100?random=$index',
    );

    _navBarHeightController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    // تهيئة فورية بقيمة افتراضية آمنة عشان الـ build الأول ما ينهارش
    _navBarHeightAnimation =
        Tween<double>(
            begin: 75.0,
            end: 550.0, // قيمة افتراضية معقولة لحد ما ناخد الحجم الحقيقي
          ).animate(
            CurvedAnimation(
              parent: _navBarHeightController,
              curve: Curves.easeInOutQuint,
            ),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() {
                _isNavBarAnimationComplete = true;
                _navBarKey = UniqueKey(); // تغيير المفتاح عند التوسع
              });
            } else if (status == AnimationStatus.dismissed) {
              setState(() {
                _isNavBarAnimationComplete = false;
                _page2 = 0; // إعادة تعيين _page2 عند الغلق
                _navBarKey = UniqueKey(); // تغيير المفتاح عند الغلق
              });
            }
          });

    // Load saved HOST and initialize controllers, then try login
    _loadHostAndLogin();

    // تهيئة AnimationControllers للارتفاع
    _downChildHeightController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _downChildHeightAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _downChildHeightController,
        curve: Curves.easeInOut,
      ),
    );

    _downChildHeightControllerP2 = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _downChildHeightAnimationP2 = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _downChildHeightControllerP2,
        curve: Curves.easeInOut,
      ),
    );

    _downChildHeightControllerP3 = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _downChildHeightAnimationP3 = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _downChildHeightControllerP3,
        curve: Curves.easeInOut,
      ),
    );

    // تهيئة AnimationController للإشعارات الآنية - منفصل عن الإعدادات
    _instantNotificationController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _instantNotificationAnimation = Tween<double>(begin: 75, end: 175).animate(
      CurvedAnimation(
        parent: _instantNotificationController,
        curve: Curves.easeInOut,
      ),
    );

    MainNavigation.refreshCurrentPage = _refreshCurrentPage;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final double newHeight = MediaQuery.of(context).size.height;

    // تجاهل القيم الوهمية (0 أو أقل من حد منطقي لأي جهاز حقيقي)
    if (newHeight < 200) return;

    MainNavigation.shieght = newHeight;
    final double newShieghtDF = (newHeight - 640).round().toDouble();

    // حدّث بس لو القيمة اتغيرت فعليًا (أول مرة، أو لو الشاشة اترورتيت)
    if (MainNavigation.shieghtDF != newShieghtDF ||
        !_navBarAnimationInitialized) {
      MainNavigation.shieghtDF = newShieghtDF;

      setState(() {
        _navBarHeightAnimation =
            Tween<double>(
              begin: 75.0,
              end: 550.0 + MainNavigation.shieghtDF * 0.97,
            ).animate(
              CurvedAnimation(
                parent: _navBarHeightController,
                curve: Curves.easeInOutQuint,
              ),
            );
        _navBarAnimationInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    // Update connection status to offline when app closes
    _updateConnectionStatusToOffline();

    _postNameController.dispose();
    _prixController.dispose();
    _postInfoController.dispose();
    _heartbeatTimer?.cancel();
    _notificationTimer?.cancel();
    _stopNotificationListener();
    _stopActiveUsersListener();
    _navBarHeightController.dispose();
    _downChildHeightController.dispose();
    _downChildHeightControllerP3.dispose();
    _instantNotificationController.dispose();
    if (MainNavigation.refreshCurrentPage == _refreshCurrentPage) {
      MainNavigation.refreshCurrentPage = null;
    }
    super.dispose();
  }

  Future<void> _logout() async {
    await StorageHelper.clearOid();
    await StorageHelper.clearBID();
    MainNavigation.sineKey = '';
    MainNavigation.sineBID = '';
    MainNavigation.IsrealySined = false;
    await _switchToPage(0);
    setState(() {
      _page2 = 0; // إعادة تعيين _page2 عند تسجيل الخروج
    });
  }

  Future<void> _loadHostAndLogin() async {
    // Load saved HOST and initialize controllers
    final savedHost = await StorageHelper.loadHost();
    setState(() {
      HOST = savedHost;
      final hostParts = HOST.split('.');
      if (hostParts.length >= 4) {
        _hostController1.text = hostParts[2];
        _hostController2.text = hostParts[3];
      }
    });

    // Now try login with the loaded HOST
    _tryLoginByOid();
  }

  // دالة الإشعارات الآنية - تستخدم _navBarHeightController مع حساب ديناميكي للارتفاع
  // أنماط الألوان: success (أخضر), warning (أصفر), error (أحمر)
  Future<void> _showInstantNotification({
    String message = 'إشعار جديد',
    String type = 'success',
  }) async {
    // تحديد اللون حسب النوع
    Color notificationColor;
    switch (type) {
      case 'warning':
        notificationColor = Colors.yellow.withOpacity(0.8);
        break;
      case 'error':
        notificationColor = Colors.red.withOpacity(0.8);
        break;
      case 'success':
      default:
        notificationColor = Colors.green.withOpacity(0.8);
        break;
    }

    // إذا كان القائمة مفتوحة، استخدم Overlay للمنبثق الحقيقي
    if (mune_opned) {
      // تحديث رسالة الإشعار واللون
      setState(() {
        _instantNotificationMessage = message;
        _instantNotificationColor = notificationColor;
      });

      // إنشاء OverlayEntry للمنبثق
      _notificationOverlay = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: notificationColor, width: 1),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // إضافة Overlay
      Overlay.of(context).insert(_notificationOverlay!);

      // إزالة Overlay بعد 3 ثواني
      Future.delayed(Duration(seconds: 3), () {
        _notificationOverlay?.remove();
        _notificationOverlay = null;
      });
    } else {
      // تحديث رسالة الإشعار واللون والوضع
      setState(() {
        _instantNotificationMessage = message;
        _instantNotificationColor = notificationColor;
        _isNotificationMode = true;
        _isPopupNotification = false;
      });

      // تشغيل الأنيميشن للأمام (توسيع الشريط)
      await _navBarHeightController.forward();

      // انتظار لعرض الإشعار لمدة 3 ثواني
      await Future.delayed(Duration(seconds: 3));

      // تشغيل الأنيميشن للخلف (إغلاق الشريط)
      await _navBarHeightController.reverse();

      // إعادة تعيين الحالة
      setState(() {
        _isNotificationMode = false;
        _isPopupNotification = false;
      });
    }
  }

  Future<void> _tryLoginByOid() async {
    final oid = MainNavigation.sineKey;
    if (oid.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://$HOST:3000/api/login-by-oid');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'Oid': oid}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout after 10 seconds');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // حفظ بيانات المستخدم في MainNavigation.userdata
          if (data['user'] != null) {
            MainNavigation.userdata = data['user'];
          }

          // حفظ OID الجديد إذا كان موجوداً
          if (data['oid'] != null) {
            final newOid = data['oid'];
            MainNavigation.sineKey = newOid;
            await StorageHelper.saveOid(newOid);
          }

          // حفظ BID إذا كان موجوداً
          if (data['user'] != null && data['user']['BID'] != null) {
            final bid = data['user']['BID'];
            MainNavigation.sineBID = bid;
            await StorageHelper.saveBID(bid);
          }

          MainNavigation.IsrealySined = true;
          setState(() {});

          // Start heartbeat and notification polling after successful login
          _startHeartbeat();
          _startNotificationPolling();
          _startActiveUsersListener();

          // Update connection status immediately to add user to ActiveUsers
          await _updateConnectionStatus();

          _fetchActiveUsers();
          _fetchUserNotifications();
        } else {
          _showLoginRetryDialog(data['message'] ?? 'فشل الاتصال');
        }
      } else {
        _showLoginRetryDialog('خطأ في الاتصال بالسيرفر');
      }
    } on TimeoutException catch (e) {
      _showLoginRetryDialog(
        'انتهت مهلة الاتصال بالسيرفر. تأكد من أن السيرفر يعمل على $HOST:3000',
      );
    } catch (e) {
      _showLoginRetryDialog('خطأ في الاتصال: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLoginRetryDialog(String errorMessage) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('فشل الاتصال التلقائي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hostController1,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '192.168.',
                      hintText: '92',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hostController2,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '.',
                      hintText: '20',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final newHost =
                    '192.168.${_hostController1.text}.${_hostController2.text}';
                setState(() {
                  HOST = newHost;
                });
                await StorageHelper.saveHost(newHost);
                _showInstantNotification(
                  message: 'HOST updated to: $HOST',
                  type: 'success',
                );
                Navigator.of(context).pop();
                _tryLoginByOid(); // إعادة المحاولة بالـ HOST الجديد
              },
              child: Text('حفظ وإعادة المحاولة'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tryLoginByOid(); // إعادة المحاولة
            },
            child: Text('إعادة المحاولة'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // امسح الـ Oid المحفوظ وأجبر المستخدم على تسجيل الدخول يدوياً
              await StorageHelper.clearOid();
              await StorageHelper.clearBID();
              MainNavigation.sineKey = '';
              MainNavigation.sineBID = '';
              MainNavigation.IsrealySined = false;
              setState(() {});
              _showInstantNotification(
                message: 'تم مسح البيانات المحفوظة',
                type: 'warning',
              );
            },
            child: Text('مسح البيانات المحفوظة'),
          ),
        ],
      ),
    );
  }

  // نفس مبدأ _switchToPage (إغلاق بالانيميشن ثم فتح بالانيميشن) لكن بدون تغيير _page
  Future<void> _refreshCurrentPage() async {
    await _sheetController.hideAndFade();
    setState(
      () {},
    ); // القيمة (مثلاً MainNavigation.sineUp) اتغيرت مسبقًا من الطرف اللي طلب التحديث
    _sheetController.show();
  }

  // Refresh page with animation and height adjustment
  Future<void> refreshPageWithAnim() async {
    await refreshDownChildOnly(30);
  }

  // Partial refresh for _pageDownChild only
  // شغّلنا الأنيميشن فعليًا هنا بدل الاكتفاء بتغيير المتغيّر:
  // (المشكلة الأصلية: begin/end كانا ثابتين على صفر ولم يكن أي كود يحرّك الـ Controller)
  Future<void> refreshDownChildOnly(double _refresh_hieght) async {
    refresh_hieght = _refresh_hieght;
    _downChildHeightAnimation =
        Tween<double>(
          begin: _downChildHeightAnimation.value,
          end: refresh_hieght,
        ).animate(
          CurvedAnimation(
            parent: _downChildHeightController,
            curve: Curves.easeInOut,
          ),
        );
    _downChildRefreshNotifier.value++;
    await _downChildHeightController.forward(from: 0);
  }

  Future<void> refreshDownChildOnlyP3(double _refresh_hieghtP3) async {
    refresh_hieghtP3 = _refresh_hieghtP3;
    _downChildHeightAnimationP3 =
        Tween<double>(
          begin: _downChildHeightAnimationP3.value,
          end: refresh_hieghtP3,
        ).animate(
          CurvedAnimation(
            parent: _downChildHeightControllerP3,
            curve: Curves.easeInOut,
          ),
        );
    _downChildRefreshNotifier.value++;

    // 🔹 جديد: أرسل أمر للخريطة لرفع أو إنزال اللوحة المنبثقة بأنيميشن
    if (_refresh_hieghtP3 == 80) {
      MainNavigation.controlPanelRaisedNotifier.value =
          true; // رفع اللوحة للأعلى
    } else if (_refresh_hieghtP3 == 40) {
      MainNavigation.controlPanelRaisedNotifier.value =
          false; // إنزال اللوحة للأسفل
    }

    await _downChildHeightControllerP3.forward(from: 0);
  }

  Future<void> refreshDownChildOnlyP2(double _refresh_hieghtP2) async {
    refresh_hieghtP2 = _refresh_hieghtP2;
    _downChildHeightAnimationP2 =
        Tween<double>(
          begin: _downChildHeightAnimationP2.value,
          end: refresh_hieghtP2,
        ).animate(
          CurvedAnimation(
            parent: _downChildHeightControllerP2,
            curve: Curves.easeInOut,
          ),
        );
    _downChildRefreshNotifier.value++;

    // 🔹 جديد: أرسل أمر للخريطة لرفع أو إنزال اللوحة المنبثقة بأنيميشن
    if (_refresh_hieghtP2 == 80) {
      MainNavigation.controlPanelRaisedNotifierP2.value =
          true; // رفع اللوحة للأعلى
    } else if (_refresh_hieghtP2 == 40) {
      MainNavigation.controlPanelRaisedNotifierP2.value =
          false; // إنزال اللوحة للأسفل
    }

    await _downChildHeightControllerP3.forward(from: 0);
  }

  Widget _pageContent(int index) {
    if (index == 0) {
      if (MainNavigation.sineKey == '') {
        return ValueListenableBuilder<Widget?>(
          valueListenable: MainNavigation.labelNotifier,
          builder: (context, label, child) {
            return Container(
              color: Colors.blueAccent,
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        // زر القائمة (يسار)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              // اعتمد على status الحقيقي بدل التبديل الأعمى
                              if (_navBarHeightController.status ==
                                      AnimationStatus.completed ||
                                  _navBarHeightController.status ==
                                      AnimationStatus.forward) {
                                _navBarHeightController.reverse();
                                mune_opned = false;
                              } else {
                                _navBarHeightController.forward();
                                mune_opned = true;
                              }
                            });
                          },
                          icon: Icon(
                            mune_opned ? Icons.close : Icons.menu,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),

                        // المساحة الشفافة في المنتصف
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (mune_opned) {
                                setState(() {
                                  mune_opned = !mune_opned;
                                  _navBarHeightController.reverse();
                                });
                              }
                            },
                            child: Container(
                              height: 60,
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        if (!MainNavigation.IsrealySined)
                          _isLoading
                              ? SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: _tryLoginByOid,
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  tooltip: 'Reload',
                                ),
                        // زر الملف الشخصي (يمين)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              showProfile = !showProfile;
                              showAddPost =
                                  false; // Close addPost when opening profile
                            });
                          },
                          icon: Icon(
                            Icons.notifications,
                            color: showProfile ? Colors.white54 : Colors.amber,
                            size: 40,
                          ),
                          tooltip: showProfile
                              ? 'Close notifications'
                              : 'Open notifications',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10 + MainNavigation.shieghtDF * 0.3),
                  Text(
                    MainNavigation.userdata['username'] ??
                        "musTa : ${MainNavigation.shieght.toStringAsFixed(0)}",
                    style: TextStyle(fontFamily: 'niblora', fontSize: 25),
                  ),
                ],
              ),
            );
          },
        );
      }
      return ValueListenableBuilder<Widget?>(
        valueListenable: MainNavigation.labelNotifier,
        builder: (context, label, child) {
          // Show map when _showMapInContent is true
          if (_showMapInContent) {
            return MainNavigation.maap ?? Container(color: Colors.blue);
          }

          return Container(
            color: Colors.blue,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        // زر القائمة (يسار)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              // اعتمد على status الحقيقي بدل التبديل الأعمى
                              if (_navBarHeightController.status ==
                                      AnimationStatus.completed ||
                                  _navBarHeightController.status ==
                                      AnimationStatus.forward) {
                                _navBarHeightController.reverse();
                                mune_opned = false;
                              } else {
                                _navBarHeightController.forward();
                                mune_opned = true;
                              }
                            });
                          },
                          icon: Icon(
                            mune_opned ? Icons.close : Icons.menu,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),

                        // المساحة الشفافة في المنتصف
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (mune_opned) {
                                setState(() {
                                  mune_opned = !mune_opned;
                                  _navBarHeightController.reverse();
                                });
                              }
                            },
                            child: Container(
                              height: 60,
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        if (!MainNavigation.IsrealySined)
                          _isLoading
                              ? SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: _tryLoginByOid,
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  tooltip: 'Reload',
                                ),
                        // زر الملف الشخصي (يمين)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              showProfile = !showProfile;
                              showAddPost =
                                  false; // Close addPost when opening profile
                            });
                          },
                          icon: Icon(
                            Icons.notifications,
                            color: showProfile ? Colors.white54 : Colors.amber,
                            size: 40,
                          ),
                          tooltip: showProfile
                              ? 'Close notifications'
                              : 'Open notifications',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10 + MainNavigation.shieghtDF * 0.3),
                  Text(
                    MainNavigation.userdata['username'] ??
                        "musTa : ${MainNavigation.shieght.toStringAsFixed(0)}",
                    style: TextStyle(fontFamily: 'niblora', fontSize: 25),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    if (index == 2) {
      return ValueListenableBuilder<Widget?>(
        valueListenable: MainNavigation.labelNotifier,
        builder: (context, label, child) {
          return Container(
            color: Colors.blueAccent,
            child: MainNavigation.maap,
          );
        },
      );
    }
    if (index == 3) {
      return ValueListenableBuilder<Widget?>(
        valueListenable: MainNavigation.labelNotifier,
        builder: (context, label, child) {
          return Container(
            color: Colors.blueAccent,
            child: MainNavigation.maap,
          );
        },
      );
    }
    if (index == 4) {
      return MapScreen(
        key: ValueKey('map_${DateTime.now().millisecondsSinceEpoch}'),
        showMultipleAreas: true,
        showControlPanel: false,
      );
    }
    /**if (index == 3) {
      return ValueListenableBuilder<Widget?>(
        valueListenable: MainNavigation.labelNotifier,
        builder: (context, label, child) {
          return Container(
            color: Colors.blueAccent,
            child: Align(
              alignment: Alignment.topLeft,
              child: label ?? Text(index.toString(), style: const TextStyle(color: Colors.white, fontSize: 48)),
            ),
          );
        },
      );
    }*/
    return Container(
      color: Colors.blueAccent,
      child: Center(
        child: Text(
          index.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 48),
        ),
      ),
    );
  }

  Widget Notfy() {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 80),
          SizedBox(
            height: 260 + MainNavigation.shieghtDF * 0.4,
            width: 300,
            child: Container(
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.black, width: 0.5),
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () => _fetchUserNotifications(),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Expanded(
                    child: _isLoadingNotifications
                        ? Center(child: CircularProgressIndicator())
                        : _userNotifications.isEmpty
                        ? Center(
                            child: Text(
                              'No notifications',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              spacing: 1,
                              mainAxisSize: MainAxisSize.min,
                              children: _userNotifications.map((notification) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: notification['isRead'] == true
                                        ? Colors.white10
                                        : Colors.white70,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: notification['isRead'] == true
                                          ? Colors.white24
                                          : Colors.black,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification['message'] ??
                                                  'No message',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                fontWeight:
                                                    notification['isRead'] ==
                                                        true
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (notification['isRead'] == false)
                                            GestureDetector(
                                              onTap: () =>
                                                  _markNotificationAsRead(
                                                    notification['id'],
                                                  ),
                                              child: Icon(
                                                Icons.mark_email_read,
                                                size: 16,
                                                color: Colors.amber,
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        spacing: 5,
                                        children: [
                                          Text(
                                            'From: ${notification['senderUsername'] ?? notification['senderBID']?.substring(0, 8) ?? notification['senderOid']?.substring(0, 8) ?? 'Unknown'}',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          Text(
                                            'Type: ${notification['type'] ?? 'info'}',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.white54,
                                            ),
                                          ),
                                          Text(
                                            'Expires: ${_formatDateTime(notification['notificationEnd'])}',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80), // مسافة أسفل الحاوية
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  List<Widget> proline(String item, String value) {
    return [
      Row(
        children: [
          Flexible(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: Container(
                //  width: double.infinity,
                height: 100,
                color: Colors.transparent,
                child: Center(
                  child: Text(item, style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.black),
          Flexible(
            flex: 1,
            child: SizedBox(
              height: 40,
              child: Container(
                //  width: double.infinity,
                height: 100,
                color: Colors.transparent,
                child: Center(
                  child: Text(value, style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
      Container(height: 1, width: 560, color: Colors.black),
    ];
  }

  Widget monthes() {
    //  return Text("ppppp");
    bool TearNoPosision =
        MainNavigation.userdata['position'].toString() == '' ||
        MainNavigation.userdata['position'].toString() == 'null';
    return Align(
      alignment: Alignment.topCenter,
      child: (MainNavigation.userdata.isNotEmpty && TearNoPosision)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      if (MainNavigation.selected_posision != null)
                        SizedBox(
                          height: 20,
                          child: _MarqueeText(
                            text:
                                MainNavigation.selected_posision?['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: 270 + MainNavigation.shieghtDF * 0.4,
                        width: 300,
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.black, width: 0.5),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12.0),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              spacing: 7 + MainNavigation.shieghtDF * 0.04,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 45,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // أولاً إخفاء الدائرة بالانيميشن
                                            _sheetController
                                                .hideProfileCircle();
                                            // انتظار انتهاء انيميشن الدائرة (600ms)
                                            await Future.delayed(
                                              const Duration(milliseconds: 600),
                                            );
                                            // إخفاء المحتوى بانيميشن التلاشي
                                            // await _sheetController.hideAndFade();
                                            // إنشاء الخريطة وتغيير الحالة
                                            setState(() {
                                              MainNavigation.maap = MapScreen(
                                                key: ValueKey(
                                                  'map_${DateTime.now().millisecondsSinceEpoch}',
                                                ),
                                                cameraOffsetPercent:
                                                    -(0.3 +
                                                        MainNavigation
                                                                .shieghtDF *
                                                            0.0017),
                                                selectSinglePosition:
                                                    true, // وضع اختيار موقع واحد فقط
                                                showControlPanel: false,
                                              );
                                              _showMapInContent = true;
                                            });
                                            // إظهار المحتوى الجديد
                                            // _sheetController.show();
                                            // تحريك الحاوية فعليًا لأسفل (كانت مجرد تعيين متغيّر بدون تشغيل الأنيميشن)
                                            await refreshDownChildOnly(
                                              -45,
                                            ); // Lower _pageDownChild by 40%
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                          ),
                                          child: Text(
                                            'Get Position',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 1,
                                        child: DropdownButton<String>(
                                          value: _dropdownValue,
                                          hint: const Text(
                                            'Select item',
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          dropdownColor: Colors.black87,
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.white54,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Item 1',
                                              child: Text('Item 1'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Item 2',
                                              child: Text('Item 2'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Item 3',
                                              child: Text('Item 3'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Item 4',
                                              child: Text('Item 4'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Item 5',
                                              child: Text('Item 5'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _dropdownValue = value!;
                                            });
                                          },
                                          isExpanded: true,
                                          underline: Container(
                                            height: 1,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(
                                  height: 40,
                                  child: TextField(
                                    //  controller: _passwordController,
                                    // obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Post Info',
                                      hintStyle: const TextStyle(
                                        color: Colors.white54,
                                      ),
                                      //    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                                      filled: true,
                                      fillColor: Colors.white10,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(9),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                //-- list of picters
                                // FIX: removed the surrounding Expanded() here.
                                // This Column lives inside a SingleChildScrollView, which gives
                                // unbounded height -> Expanded/Flexible with a flex factor cannot
                                // resolve against "infinity" and crashes with the RenderFlex
                                // "incoming height constraints are unbounded" assertion.
                                // The SizedBox below already pins an explicit height (35), so no
                                // flex wrapper is needed.
                                SizedBox(
                                  height: 35,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final position = MainNavigation
                                          .selected_posision?['position'];

                                      // تحديث الموقع محلياً
                                      setState(() {
                                        MainNavigation.userdata['position'] =
                                            position;
                                      });

                                      // تحديث الموقع في قاعدة البيانات
                                      if (position != null &&
                                          MainNavigation.sineKey.isNotEmpty) {
                                        try {
                                          final response = await http.post(
                                            Uri.parse(
                                              AppConfig.updateUserPositionUrl,
                                            ),
                                            headers: {
                                              'Content-Type':
                                                  'application/json',
                                            },
                                            body: jsonEncode({
                                              'Oid': MainNavigation.sineKey,
                                              'position': position,
                                            }),
                                          );

                                          if (response.statusCode == 200) {
                                            final data = jsonDecode(
                                              response.body,
                                            );
                                            if (data['success'] == true &&
                                                data['user'] != null) {
                                              print(
                                                '✅ Position updated successfully in database',
                                              );
                                              // تحديث بيانات المستخدم من الاستجابة
                                              MainNavigation.userdata =
                                                  data['user'];
                                              setState(() {});
                                            }
                                          } else {
                                            print(
                                              '❌ Failed to update position: ${response.statusCode}',
                                            );
                                          }
                                        } catch (e) {
                                          print(
                                            '❌ Error updating position: $e',
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                    child: Text(
                                      'Ok',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      //  const SizedBox(height: 80), // مسافة أسفل الحاوية
                    ],
                  ),
                ),
                const SizedBox(height: 80), // مسافة أسفل الحاوية
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 80),
                SizedBox(
                  height: 265 + MainNavigation.shieghtDF * 0.4,
                  width: 300,
                  child: Container(
                    padding: const EdgeInsets.all(9.0),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.black, width: 0.5),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(12.0),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        //  spacing: 10,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!(MainNavigation.userdata.isNotEmpty &&
                              MainNavigation.userdata['position'].toString() ==
                                  'null'))
                            if (MainNavigation.userdata.isNotEmpty)
                              ...MainNavigation.userdata.entries.expand(
                                (entry) => proline(
                                  entry.key,
                                  entry.value?.toString() ?? 'N/A',
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80), // مسافة أسفل الحاوية
              ],
            ),
    );
  }

  Widget addPost() {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 60),
          if (MainNavigation.selected_posision != null)
            SizedBox(
              height: 20,
              child: _MarqueeText(
                text: MainNavigation.selected_posision?['name'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          SizedBox(
            height: 270 + MainNavigation.shieghtDF * 0.4,
            width: 300,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.black, width: 0.5),
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 7 + MainNavigation.shieghtDF * 0.04,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // FIX (overflow): same fixed-width issue as monthes() above.
                    // 200 + 10 + 100 = 310px > the ~279px the Row actually gets.
                    // Switched to Expanded with flex ratios so it never overflows.
                    SizedBox(
                      height: 45,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButton<String>(
                              value: _dropdownValue2,
                              hint: const Text(
                                'Select item',
                                style: TextStyle(color: Colors.white54),
                              ),
                              dropdownColor: Colors.black87,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white54,
                              ),
                              style: const TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                  value: '1',
                                  child: Text('hour'),
                                ),
                                DropdownMenuItem(
                                  value: '2',
                                  child: Text('2hours'),
                                ),
                                DropdownMenuItem(
                                  value: '24',
                                  child: Text('day'),
                                ),
                                DropdownMenuItem(
                                  value: '720',
                                  child: Text('month'),
                                ),
                                DropdownMenuItem(
                                  value: '8760',
                                  child: Text('year'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _dropdownValue2 = value!;
                                });
                              },
                              isExpanded: true,
                              underline: Container(
                                height: 1,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: DropdownButton<String>(
                              value: _dropdownValue,
                              hint: const Text(
                                'Select item',
                                style: TextStyle(color: Colors.white54),
                              ),
                              dropdownColor: Colors.black87,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white54,
                              ),
                              style: const TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Item 1',
                                  child: Text('Item 1'),
                                ),
                                DropdownMenuItem(
                                  value: 'Item 2',
                                  child: Text('Item 2'),
                                ),
                                DropdownMenuItem(
                                  value: 'Item 3',
                                  child: Text('Item 3'),
                                ),
                                DropdownMenuItem(
                                  value: 'Item 4',
                                  child: Text('Item 4'),
                                ),
                                DropdownMenuItem(
                                  value: 'Item 5',
                                  child: Text('Item 5'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _dropdownValue = value!;
                                });
                              },
                              isExpanded: true,
                              underline: Container(
                                height: 1,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 180,
                          height: 40,
                          child: TextField(
                            controller: _postNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Post Name',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(9),
                                  bottomLeft: Radius.circular(9),
                                  topRight: Radius.zero,
                                  bottomRight: Radius.zero,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        SizedBox(
                          width: 90,
                          height: 40,
                          child: TextField(
                            controller: _prixController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Prix',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(9),
                                  bottomRight: Radius.circular(9),
                                  topLeft: Radius.zero,
                                  bottomLeft: Radius.zero,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _postInfoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Post Info',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    //-- list of picters
                    // FIX: removed the surrounding Expanded() here.
                    // Same issue as above — this Column is inside a SingleChildScrollView
                    // (unbounded height), so Expanded cannot resolve. The SizedBox already
                    // fixes the height to 60, making Expanded unnecessary and unsafe.
                    SizedBox(
                      height: 60,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...List.generate(_imageUrls.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          _imageUrls[index].startsWith('http')
                                          ? Image.network(
                                              _imageUrls[index],
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: Colors.grey,
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.white54,
                                                      ),
                                                    );
                                                  },
                                            )
                                          : Image.file(
                                              File(_imageUrls[index]),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: Colors.grey,
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.white54,
                                                      ),
                                                    );
                                                  },
                                            ),
                                    ),
                                    Positioned(
                                      top: -5,
                                      right: -5,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _imageUrls.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            // زر إضافة صورة جديدة
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white54,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white54,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 35,
                            child: ElevatedButton(
                              onPressed: () async {
                                await _addTaskToDatabase();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: Text(
                                'Ok',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 35,
                            child: ElevatedButton(
                              onPressed: () async {
                                // أولاً إخفاء الدائرة بالانيميشن
                                _sheetController.hideProfileCircle();
                                // انتظار انتهاء انيميشن الدائرة (600ms)
                                await Future.delayed(
                                  const Duration(milliseconds: 600),
                                );
                                // إخفاء المحتوى بانيميشن التلاشي
                                // await _sheetController.hideAndFade();
                                // إنشاء الخريطة وتغيير الحالة
                                setState(() {
                                  MainNavigation.maap = MapScreen(
                                    key: ValueKey(
                                      'map_${DateTime.now().millisecondsSinceEpoch}',
                                    ),
                                    cameraOffsetPercent:
                                        -(0.3 +
                                            MainNavigation.shieghtDF * 0.0017),
                                    selectSinglePosition:
                                        true, // وضع اختيار موقع واحد فقط
                                    showControlPanel: false,
                                  );
                                  _showMapInContent = true;
                                });
                                // إظهار المحتوى الجديد
                                // _sheetController.show();
                                // تحريك الحاوية فعليًا لأسفل (كانت مجرد تعيين متغيّر بدون تشغيل الأنيميشن)
                                await refreshDownChildOnly(
                                  -45,
                                ); // Lower _pageDownChild by 40%
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: Text(
                                'Get Position',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          //  const SizedBox(height: 80), // مسافة أسفل الحاوية
        ],
      ),
    );
  }

  void getpos() async {
    // طباعة معلومات الموقع المختار

    // إخفاء الخريطة واستبدالها بالصفحة الأصلية
    setState(() {
      _showMapInContent = false;
    });
    // إعادة ارتفاع الحاوية البنفسجية (تشغيل الأنيميشن فعليًا رجوعًا إلى الصفر)
    await refreshDownChildOnly(0);
    // انتظار انتهاء انيميشن الحاوية
    await Future.delayed(const Duration(milliseconds: 600));
    // إظهار الدائرة بالانيميشن (نحو الأسفل)
    _sheetController.showProfileCircle();
  }

  // دالة لاختيار صور متعددة من المعرض
  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty && mounted) {
        setState(() {
          for (var image in images) {
            _imageUrls.add(image.path);
          }
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  // دالة لإضافة مهمة إلى قاعدة البيانات
  Future<void> _addTaskToDatabase() async {
    // تحضير البيانات
    final order = _postNameController.text.trim();
    final orderType = _dropdownValue;
    final orderUser = MainNavigation.userdata['username'] ?? '';
    final orderIndex = int.tryParse(_prixController.text) ?? 0;
    final orderPosision = MainNavigation.selected_posision?['position'] ?? '';
    final orderPrex = _prixController.text.trim();
    final orderOther = jsonEncode(_imageUrls);
    final orderInfo = _postInfoController.text.trim();

    // توليد OrderOid عشوائي
    final orderOid =
        'ORD-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';

    // تاريخ البدء - التاريخ الحالي
    final orderDate = DateTime.now();
    final orderDateFormatted =
        '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')} ${orderDate.hour.toString().padLeft(2, '0')}:${orderDate.minute.toString().padLeft(2, '0')}:${orderDate.second.toString().padLeft(2, '0')}';

    // تاريخ الانتهاء - التاريخ الحالي + المدة (بالساعات)
    final hours = int.tryParse(_dropdownValue2) ?? 1;
    final orderLast = orderDate.add(Duration(hours: hours));
    final orderLastFormatted =
        '${orderLast.year}-${orderLast.month.toString().padLeft(2, '0')}-${orderLast.day.toString().padLeft(2, '0')} ${orderLast.hour.toString().padLeft(2, '0')}:${orderLast.minute.toString().padLeft(2, '0')}:${orderLast.second.toString().padLeft(2, '0')}';

    try {
      final requestData = {
        'tableName': 'Taskes',
        'data': {
          'Order': order,
          'OrderType': orderType,
          'OrderUser': orderUser,
          'OrderIndex': orderIndex,
          'OrderPosision': orderPosision,
          'Orderdate': orderDateFormatted,
          'OrderLast': orderLastFormatted,
          'OrderPrex': orderPrex,
          'OrderOid': orderOid,
          'OrderOther': orderOther,
          'Orderinfo': orderInfo,
        },
      };

      final response = await http.post(
        Uri.parse('http://$HOST:3000/api/insert-row'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          _showInstantNotification(
            message: 'Task added successfully',
            type: 'success',
          );
        }
        // مسح الحقول
        _postNameController.clear();
        _prixController.clear();
        _postInfoController.clear();
        setState(() {
          _imageUrls = [];
        });
      } else {
        if (mounted) {
          _showInstantNotification(
            message: 'Failed to add task',
            type: 'error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showInstantNotification(message: 'Error: $e', type: 'error');
      }
    }
  }

  // Heartbeat function to update connection status
  void _startHeartbeat() {
    _heartbeatTimer?.cancel(); // Cancel existing timer if any
    _heartbeatTimer = Timer.periodic(Duration(minutes: 2), (timer) async {
      if (MainNavigation.sineKey.isNotEmpty) {
        await _updateConnectionStatus();
      }
    });
  }

  // Update connection status
  Future<void> _updateConnectionStatus() async {
    if (MainNavigation.sineKey.isEmpty) {
      print('❌ Cannot update connection status: sineKey is empty');
      return;
    }

    try {
      final connectionData = {
        'Oid': MainNavigation.sineKey,
        'BID': MainNavigation.sineBID,
        'username': MainNavigation.userdata['username'] ?? '',
        'status': 'online',
      };

      print('📡 Updating connection status: $connectionData');

      final response = await http.post(
        Uri.parse('http://$HOST:3000/api/update-connection-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(connectionData),
      );

      if (response.statusCode == 200) {
        print('✅ Connection status updated successfully');
      } else {
        print('❌ Failed to update connection status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Heartbeat error: $e');
    }
  }

  // Update connection status to offline (called when app closes)
  Future<void> _updateConnectionStatusToOffline() async {
    if (MainNavigation.sineKey.isEmpty) {
      print('❌ Cannot update connection status to offline: sineKey is empty');
      return;
    }

    try {
      final connectionData = {
        'Oid': MainNavigation.sineKey,
        'BID': MainNavigation.sineBID,
        'username': MainNavigation.userdata['username'] ?? '',
        'status': 'offline',
      };

      print('📡 Updating connection status to offline: $connectionData');

      // Don't await the response to avoid blocking the dispose process
      http
          .post(
            Uri.parse('http://$HOST:3000/api/update-connection-status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(connectionData),
          )
          .then((response) {
            if (response.statusCode == 200) {
              print('✅ Connection status updated to offline successfully');
            } else {
              print(
                '❌ Failed to update connection status to offline: ${response.statusCode}',
              );
            }
          })
          .catchError((e) {
            print('❌ Error updating connection status to offline: $e');
          });
    } catch (e) {
      print('❌ Error in offline status request: $e');
    }
  }

  // Start notification polling
  void _startNotificationPolling() {
    _notificationTimer?.cancel(); // Cancel existing timer if any
    _startNotificationListener();
  }

  // Start SSE notification listener
  void _startNotificationListener() async {
    if (_isListeningToNotifications) return;

    try {
      _isListeningToNotifications = true;

      // Connect to SSE endpoint
      final request = http.Request(
        'GET',
        Uri.parse(
          'http://$HOST:3000/api/notifications-stream?BID=${MainNavigation.sineBID}',
        ),
      );

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final stream = response.stream;
        stream.transform(utf8.decoder).transform(const LineSplitter()).listen((
          line,
        ) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6); // Remove 'data: ' prefix
            try {
              final json = jsonDecode(data);

              if (json['type'] == 'notification') {
                final notification = json['notification'];

                // Check if notification already exists to avoid duplicates
                final notificationId = notification['id'];
                final alreadyExists = _userNotifications.any(
                  (n) => n['id'] == notificationId,
                );

                if (!alreadyExists) {
                  // Update notifications list
                  setState(() {
                    _userNotifications.insert(0, notification);
                  });

                  // Show instant notification
                  if (mounted) {
                    _showInstantNotification(
                      message: '${notification['message'] ?? ''}',
                      type: 'warning',
                    );
                  }
                }
              }
            } catch (e) {
              // Ignore parsing errors
            }
          }
        });
      } else {
        _isListeningToNotifications = false;
      }
    } catch (e) {
      _isListeningToNotifications = false;
    }
  }

  // Stop SSE notification listener
  void _stopNotificationListener() {
    _isListeningToNotifications = false;
  }

  // Start SSE active users listener
  void _startActiveUsersListener() async {
    if (_isListeningToActiveUsers) return;

    try {
      _isListeningToActiveUsers = true;

      // Connect to SSE endpoint for active users
      final request = http.Request(
        'GET',
        Uri.parse(
          'http://$HOST:3000/api/active-users-stream?BID=${MainNavigation.sineBID}',
        ),
      );

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final stream = response.stream;
        _activeUsersStreamSubscription = stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
              if (line.startsWith('data: ')) {
                final data = line.substring(6); // Remove 'data: ' prefix
                try {
                  final json = jsonDecode(data);

                  if (json['type'] == 'active_users_update') {
                    // Update active users list directly from SSE data
                    if (mounted) {
                      setState(() {
                        _activeUsers = List<Map<String, dynamic>>.from(
                          json['users'] ?? [],
                        );
                      });
                      print(
                        '👥 Active users updated via SSE: ${_activeUsers.length} users',
                      );
                    }
                  } else if (json['type'] == 'user_joined') {
                    // User joined - add to list and refresh
                    if (mounted) {
                      _fetchActiveUsers();
                      print(
                        '👤 User joined: ${json['user']?['username'] ?? 'Unknown'}',
                      );
                    }
                  } else if (json['type'] == 'user_left') {
                    // User left - refresh list
                    if (mounted) {
                      _fetchActiveUsers();
                      print(
                        '👤 User left: ${json['user']?['username'] ?? 'Unknown'}',
                      );
                    }
                  }
                } catch (e) {
                  // Ignore parsing errors
                }
              }
            });

        _activeUsersStreamSubscription!.onError((error) {
          print('❌ Active users stream error: $error');
          _isListeningToActiveUsers = false;
          // إعادة تحميل قائمة المستخدمين النشطين عند حدوث خطأ
          if (mounted) {
            _fetchActiveUsers();
          }
        });

        _activeUsersStreamSubscription!.onDone(() {
          print('Active users stream closed');
          _isListeningToActiveUsers = false;
          // إعادة تحميل قائمة المستخدمين النشطين عند إغلاق الاتصال
          if (mounted) {
            _fetchActiveUsers();
          }
        });
      }
    } catch (e) {
      print('❌ Error starting active users listener: $e');
      _isListeningToActiveUsers = false;
    }
  }

  // Stop SSE active users listener
  void _stopActiveUsersListener() {
    _isListeningToActiveUsers = false;
    _activeUsersStreamSubscription?.cancel();
    _activeUsersStreamSubscription = null;
  }

  // Fetch notifications
  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://$HOST:3000/api/get-notifications?Oid=${MainNavigation.sineKey}&unreadOnly=true',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['notifications'] != null && data['notifications'].length > 0) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(
              data['notifications'],
            );
          });

          // Show instant notification for new notifications
          if (mounted) {
            _showInstantNotification(
              message: 'You have ${_notifications.length} new notification(s)',
              type: 'warning',
            );
          }
        }
      }
    } catch (e) {
      print('❌ Notification polling error: $e');
    }
  }

  // Fetch user notifications for Notfy widget
  Future<void> _fetchUserNotifications() async {
    if (_isLoadingNotifications) return; // Prevent duplicate calls

    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final username = MainNavigation.userdata['username'] ?? '';
      final isAdmin = username.toLowerCase() == 'admin';

      // If admin, fetch all notifications without filtering
      final url = isAdmin
          ? 'http://$HOST:3000/api/get-notifications?BID=all'
          : 'http://$HOST:3000/api/get-notifications?BID=${MainNavigation.sineBID}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userNotifications = List<Map<String, dynamic>>.from(
            data['notifications'] ?? [],
          );
        });
      }
    } catch (e) {
      print('❌ Error fetching user notifications: $e');
    } finally {
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  // Mark notification as read
  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('http://$HOST:3000/api/mark-notification-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'notificationId': notificationId}),
      );

      if (response.statusCode == 200) {
        print('✅ Notification marked as read');
        setState(() {
          _userNotifications = _userNotifications.map((n) {
            if (n['id'] == notificationId) {
              n['isRead'] = true;
            }
            return n;
          }).toList();
        });
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Fetch active users
  Future<void> _fetchActiveUsers() async {
    if (_isLoadingActiveUsers) return; // Prevent duplicate calls

    setState(() {
      _isLoadingActiveUsers = true;
    });

    try {
      // Trigger server-side refresh (this will broadcast to all clients)
      await http.post(
        Uri.parse('http://$HOST:3000/api/refresh-active-users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'BID': MainNavigation.sineBID}),
      );

      // Wait a moment for SSE broadcast, then fetch directly as fallback
      await Future.delayed(Duration(milliseconds: 500));

      // Fallback: fetch directly if SSE hasn't updated yet
      // Check if BID is available before making the request
      if (MainNavigation.sineBID == null || MainNavigation.sineBID.isEmpty) {
        print('⚠️ Cannot fetch active users: BID is empty or undefined');
        setState(() {
          _activeUsers = [];
        });
      } else {
        final response = await http.get(
          Uri.parse(
            'http://$HOST:3000/api/get-active-users?BID=${MainNavigation.sineBID}',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _activeUsers = List<Map<String, dynamic>>.from(data['users'] ?? []);
          });
          print('📊 Active users fetched (fallback): ${_activeUsers.length}');
        }
      }
    } catch (e) {
      print('❌ Error fetching active users: $e');
    } finally {
      setState(() {
        _isLoadingActiveUsers = false;
      });
    }
  }

  // Show send message dialog
  void _showSendMessageDialog(Map<String, dynamic> user) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Message to ${user['username'] ?? 'User'}'),
        content: TextField(
          controller: messageController,
          decoration: InputDecoration(
            hintText: 'Enter your message',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                _sendMessage(user['Oid'], messageController.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  // Get user BID from active users list
  String _getUserBID(String targetOid) {
    final user = _activeUsers.firstWhere(
      (u) => u['Oid'] == targetOid,
      orElse: () => {},
    );
    return user['BID']?.toString() ?? '';
  }

  // Send message to user
  Future<void> _sendMessage(String targetOid, String message) async {
    try {
      final response = await http.post(
        Uri.parse('http://$HOST:3000/api/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'targetOid': targetOid,
          'senderOid': MainNavigation.sineKey,
          'senderBID': MainNavigation.sineBID,
          'targetBID': _getUserBID(targetOid),
          'message': message,
          'type': 'message',
          'durationMinutes': 5, // Messages expire after 5 minutes
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _showInstantNotification(
            message: 'Message sent successfully (expires in 5 minutes)',
            type: 'success',
          );
        }
      } else {
        if (mounted) {
          _showInstantNotification(
            message: 'Failed to send message',
            type: 'error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showInstantNotification(message: 'Error: $e', type: 'error');
      }
    }
  }

  Widget _pageDownChild(int page) {
    final bool isSamePage = _Oldpage == page;
    _Oldpage = page;
    return ValueListenableBuilder<int>(
      valueListenable: _downChildRefreshNotifier,
      builder: (context, _, child) {
        _Oldpage = page;
        switch (page) {
          case 0:
            if (MainNavigation.sineKey == '') {
              return LoginContent();
            }
            //  if (newpage != _Oldpage)
            if (!isSamePage) {
              int down0 = 1;
              // تاكد ما اذا كان ارتفاع الحاوية البنفسجية 80 ام لا، اذا لم يكن شغل انيميشن الارتفاع الى 80
              if (_downChildHeightAnimation.value <= down0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showMapInContent = false;
                  refreshDownChildOnly(down0.toDouble());
                });
              }
            }
            return Stack(
              children: [
                // المحتوى الأساسي
                if (_showMapInContent)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          getpos();
                        },
                        icon: Icon(
                          Icons.cancel_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          getpos();
                        },
                        icon: Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                _SwitchableContentWidget(
                  showAddPost: showAddPost,
                  showProfile: showProfile,
                  monthes: monthes(),
                  addPost: addPost(),
                  profile: Notfy(),
                  onToggle: () {},
                ),

                // 🔹 الزر في أسفل الشاشة
                Positioned(
                  bottom:
                      270 +
                      MainNavigation.shieghtDF * 0.4, // مسافة من أسفل الشاشة
                  left: 280,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            showAddPost = !showAddPost;
                            showProfile =
                                false; // Close profile when opening addPost
                          });
                        },
                        backgroundColor: Colors.amber, // 🔹 لون الخلفية Amber
                        foregroundColor:
                            Colors.black, // 🔹 لون الأيقونة (أسود للتباين)
                        child: const Icon(Icons.add, size: 20),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          case 1:
            return LoginContent();
          case 2:
            return ValueListenableBuilder<Widget?>(
              valueListenable: MainNavigation.labelNotifier,
              builder: (context, label, child) {
                if (0 > 0) {
                  return Container(
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            refreshDownChildOnly(0);
                          },
                          icon: Icon(
                            Icons.close,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // إنشاء قائمة من 10 حاويات مع مواقع عشوائية من الجزائر
                final algeriaContainers = List.generate(10, (index) {
                  final random = Random();
                  // حدود الجزائر الجغرافية تقريباً
                  final double minLat = 19.0; // جنوب الجزائر
                  final double maxLat = 37.0; // شمال الجزائر
                  final double minLng = -8.0; // غرب الجزائر
                  final double maxLng = 12.0; // شرق الجزائر

                  final double lat =
                      minLat + random.nextDouble() * (maxLat - minLat);
                  final double lng =
                      minLng + random.nextDouble() * (maxLng - minLng);

                  final colors = [
                    Colors.blue.shade100,
                    Colors.green.shade100,
                    Colors.orange.shade100,
                    Colors.purple.shade100,
                    Colors.red.shade100,
                    Colors.teal.shade100,
                    Colors.indigo.shade100,
                    Colors.amber.shade100,
                    Colors.cyan.shade100,
                    Colors.lime.shade100,
                  ];

                  return ContainerModel(
                    id: 'ALG${index + 1}',
                    defaultWidth: 100 + random.nextInt(50).toDouble(),
                    defaultHeight: 100 + random.nextInt(50).toDouble(),
                    minWidth: 50,
                    maxWidth: 200,
                    minHeight: 50,
                    maxHeight: 200,
                    color: colors[index],
                    pos: (index + 1) == 4
                        ? LatLng(36.459449, 2.749841)
                        : LatLng(lat, lng),
                  );
                });

                return ContainerGridPage(
                  externalContainers:
                      algeriaContainers, // تمرير القائمة الخارجية
                  startMode: GridDisplayMode
                      .horizontal, // يبدأ مباشرة بالعرض الأفقي هنا
                  showToggleButton: true,
                  onContainerSelected: () {
                    setState(() {
                      //  _selectedIndex = 0; // أو رقم تبويب الخريطة عندك
                    });
                  },
                  onContainerLongPress: (container, pos) {
                    setState(() {
                      MainNavigation.idopen = container.id;
                      MainNavigation.topos = pos; // يحدد الوجهة الجديدة للخريطة
                      MainNavigation.maap = MapScreen(
                        key: ValueKey(
                          'map_${DateTime.now().millisecondsSinceEpoch}',
                        ),
                        cameraOffsetPercent:
                            -(0.3 +
                                MainNavigation.shieghtDF *
                                    0.0017), // Move up by 30% of visible height
                        showControlPanel: false,
                      );
                    });
                  },
                  onContainerShodetaile: (container, pos) {
                    refreshDownChildOnlyP2(30);
                  },
                );
              },
            );
          case 3:
            return Column(
              children: [
                SizedBox(height: 20),
                Expanded(
                  child: ContainerGridPage(
                    startMode: GridDisplayMode
                        .verticalGrid, // أو horizontal / verticalList حسب المطلوب
                    showToggleButton: true,
                    onScroll: () {
                      refreshDownChildOnlyP3(80);
                    },
                    onContainerSelected: () {
                      setState(() {
                        //  _selectedIndex = 0; // أو رقم تبويب الخريطة عندك
                      });
                    },
                    onContainerLongPress: (container, pos) {
                      setState(() {
                        MainNavigation.idopen = container.id;
                        MainNavigation.topos =
                            pos; // يحدد الوجهة الجديدة للخريطة
                        MainNavigation.maap = MapScreen(
                          key: ValueKey(
                            'map_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                          cameraOffsetPercent:
                              -(0.0 +
                                  MainNavigation.shieghtDF *
                                      0.0017), // Move up by 30% of visible height
                        );
                      });
                      refreshDownChildOnlyP3(40);
                    },
                    onContainerShodetaile: (container, pos) {
                      refreshDownChildOnlyP3(40);
                    },
                  ),
                ),
              ],
            );

          case 4:
            return MapScreen(
              key: ValueKey('map_${DateTime.now().millisecondsSinceEpoch}'),
              showMultipleAreas: true,
              showControlPanel: false,
            );
          case 5:
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const Icon(Icons.person, size: 48, color: Colors.white),
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(
                      Icons.logout_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                    tooltip: 'Logout',
                  ),
                  const Text(
                    'Personal Content',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            );
          default:
            return const Center(child: Text('Unknown Page'));
        }
      },
    );
  }

  double _pagedownchildpading(int page) {
    switch (page) {
      case 3:
        return 0;
      default:
        return 10;
    }
  }

  double _pagetopRadius(int page) {
    if (MainNavigation.sineKey != '' && page == 0) return 0;
    return 50;
  }

  int _pagepopin(int page) {
    switch (page) {
      case 0:
        // Apply animated height to lower _pageDownChild
        if (MainNavigation.sineKey == '')
          return (MainNavigation.sineUp
                  ? 70 - MainNavigation.shieghtDF * 0.06
                  : 60 - MainNavigation.shieghtDF * 0.06)
              .round();
        return (70 + _downChildHeightAnimation.value.round()).clamp(0, 100);
      case 1:
        return (MainNavigation.sineUp
                ? 70 - MainNavigation.shieghtDF * 0.06
                : 60 - MainNavigation.shieghtDF * 0.06)
            .round();
      case 2:
        return (40 - (MainNavigation.shieghtDF * 0.06).round()) +
            _downChildHeightAnimationP2.value.round();
      case 3:
        // Use animated height for P3
        return _downChildHeightAnimationP3.value.round() == 0
            ? 80
            : _downChildHeightAnimationP3.value.round();
      case 4:
        return 0;
      case 5:
        return 100;
      default:
        return 50;
    }
  }

  Future<void> _switchToPage(int index) async {
    if (index == _page) return;

    // Reset showAddPost when switching to page 0
    if (index == 0 && showAddPost) {
      setState(() {
        showAddPost = false;
      });
    }

    await _sheetController.hideAndFade();
    setState(() {
      _page = index;
    });
    _sheetController.show();
  }

  Future<void> _switchToPage2(int index) async {
    if (index == _page2) return;

    setState(() {
      _page2 = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // <-- هذا هو المفتاح
      backgroundColor:
          Colors.transparent, // أو أي لون تريده يظهر خلف الـ nav bar
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _navBarHeightAnimation,
            builder: (context, child) {
              // حساب الارتفاع بناءً على الوضع
              double calculatedHeight;
              if (_isNotificationMode && !_isPopupNotification) {
                // نطاق الإشعارات: 75 إلى 175 (فقط للإشعارات داخل الشريط)
                double progress = _navBarHeightController.value;
                calculatedHeight = 75.0 + (100.0 * progress);
              } else {
                // نطاق الإعدادات: 75 إلى 550+ (أو للإشعارات المنبثقة)
                calculatedHeight = _navBarHeightAnimation.value;
              }

              return CurvedNavigationBar(
                backgroundColor: Colors.transparent,
                color: Colors.amber,
                key: _navBarKey,
                index: _isNavBarAnimationComplete ? _page2 : _page,
                height: calculatedHeight,
                items: [
                  CurvedNavigationBarItem(
                    child: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  CurvedNavigationBarItem(
                    child: Icon(Icons.ac_unit),
                    label: 'Home',
                  ),
                  CurvedNavigationBarItem(
                    child: Icon(Icons.search),
                    label: 'Search',
                  ),
                  CurvedNavigationBarItem(
                    child: Icon(Icons.chat_bubble_outline),
                    label: 'Chat',
                  ),
                  CurvedNavigationBarItem(
                    child: Icon(Icons.newspaper),
                    label: 'Feed',
                  ),
                  CurvedNavigationBarItem(
                    child: Icon(Icons.perm_identity),
                    label: 'Personal',
                  ),
                ],
                items2: _isNavBarAnimationComplete
                    ? [
                        CurvedNavigationBarItem(
                          child: Icon(Icons.settings),
                          label: 'Settings',
                        ),
                        CurvedNavigationBarItem(
                          child: Icon(Icons.notifications),
                          label: 'Notifications',
                        ),
                        CurvedNavigationBarItem(
                          child: Icon(Icons.favorite),
                          label: 'Favorites',
                        ),
                        CurvedNavigationBarItem(
                          child: Icon(Icons.bookmark),
                          label: 'Bookmarks',
                        ),
                        CurvedNavigationBarItem(
                          child: Icon(Icons.history),
                          label: 'History',
                        ),
                        CurvedNavigationBarItem(
                          child: Icon(Icons.more_horiz),
                          label: 'More',
                        ),
                      ]
                    : null,
                buttonBackgroundColor: Colors.amber,
                animationCurve: Curves.easeInOut,
                animationDuration: Duration(milliseconds: 600),
                onTap: (index) => _isNavBarAnimationComplete
                    ? _switchToPage2(index)
                    : _switchToPage(index),
                letIndexChange: (index) => true,
              );
            },
          ),
          // الزر الجديد في الفراغ أسفل الصف الأول من CurvedNavigationBar
          if (_isNavBarAnimationComplete && !_isNotificationMode)
            AnimatedBuilder(
              animation: _navBarHeightAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 75, // ارتفاع صف الأزرار في CurvedNavigationBar
                  left: 20,
                  right: 20,
                  child: AnimatedOpacity(
                    opacity: _isNavBarAnimationComplete ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: _getSettingsPageContent(_page2),
                  ),
                );
              },
            ),
          // محتوى الإشعار الآني داخل الشريط (فقط عندما القائمة مغلقة)
          if (_isNotificationMode && !_isPopupNotification)
            AnimatedBuilder(
              animation: _navBarHeightAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 75, // ارتفاع صف الأزرار في CurvedNavigationBar
                  left: 20,
                  right: 20,
                  child: AnimatedOpacity(
                    opacity: _isNotificationMode ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _instantNotificationColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _instantNotificationMessage,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _downChildHeightController,
          _downChildHeightControllerP3,
        ]),
        builder: (context, child) {
          return BottomSheetsPage(
            controller: _sheetController,
            upchild: _pageContent(_page),
            downchild: _pageDownChild(_page),
            popin: _pagepopin(_page),
            downchildpading: _pagedownchildpading(_page),
            topRadius: _pagetopRadius(_page),
            isprofile: _page == 0 && MainNavigation.sineKey != '',
            candrop: _page == 3,
            //  candrop: true,
            // ** containerStyle: BottomSheetContainerStyle.frostedGlass, // 2) ضبابي شفاف بدون لون
            // ** frostedBlurSigma: 28,
          );
        },
      ),
    );
  }

  Widget _getSettingsPageContent(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return Column(
          children: [
            // البطاقة الأولى
            Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enable Aouto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Switch(
                    value: Settings['settings_enabled'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        Settings['settings_enabled'] = value;
                      });
                      _showInstantNotification(
                        message: 'تم تغيير حالة Switch: $value',
                        type: 'warning',
                      );
                    },
                    activeColor: Colors.purple,
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'D to E',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {},
                    onLongPress: () async {
                      try {
                        final response = await http.post(
                          Uri.parse(
                            'http://$HOST:3000/api/export-to-google-sheets',
                          ),
                          headers: {'Content-Type': 'application/json'},
                        );
                        if (response.statusCode == 200) {
                          _showInstantNotification(
                            message: 'تم تصدير البيانات إلى Google Sheets',
                            type: 'success',
                          );
                        } else {
                          _showInstantNotification(
                            message: 'فشل التصدير',
                            type: 'error',
                          );
                        }
                      } catch (e) {
                        _showInstantNotification(
                          message: 'خطأ في تصدير البيانات: $e',
                          type: 'error',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'E to D',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {},
                    onLongPress: () async {
                      try {
                        print(
                          ' send ${'http://$HOST:3000/api/import-json-to-mysql'}',
                        );
                        final response = await http.post(
                          Uri.parse(
                            'http://$HOST:3000/api/import-json-to-mysql',
                          ),
                          headers: {'Content-Type': 'application/json'},
                        );

                        if (response.statusCode == 200) {
                          _showInstantNotification(
                            message: 'تم استيراد البيانات من JSON إلى MySQL',
                            type: 'success',
                          );
                        } else {
                          _showInstantNotification(
                            message: 'فشل الاستيراد',
                            type: 'error',
                          );
                        }
                      } catch (e) {
                        _showInstantNotification(
                          message: 'خطأ في استيراد البيانات: $e',
                          type: 'error',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // البطاقة الثانية
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enable Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Switch(
                    value: Settings['location_enabled'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        Settings['location_enabled'] = value;
                      });
                      _showInstantNotification(
                        message: 'تم تغيير حالة Location Switch: $value',
                        type: 'warning',
                      );
                    },
                    activeColor: Colors.purple,
                  ),
                ],
              ),
            ),
            // عنصر تغيير HOST
            Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '192.168.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        width: 50,
                        child: TextField(
                          controller: _hostController1,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        width: 50,
                        child: TextField(
                          controller: _hostController2,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newHost =
                          '192.168.${_hostController1.text}.${_hostController2.text}';
                      setState(() {
                        HOST = newHost;
                      });
                      await StorageHelper.saveHost(newHost);
                      _showInstantNotification(
                        message: 'HOST updated to: $HOST',
                        type: 'success',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Active Users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '(${_activeUsers.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  _isLoadingActiveUsers
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(Icons.refresh, size: 20),
                          onPressed: () => _fetchActiveUsers(),
                        ),
                ],
              ),
            ),
            if (_activeUsers.isEmpty && !_isLoadingActiveUsers)
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No active users',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            if (_isLoadingActiveUsers)
              Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ..._activeUsers.map((user) {
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['username'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Oid: ${user['Oid']?.substring(0, 8)}...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Status: ${user['status'] ?? 'online'}',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.message, size: 20, color: Colors.blue),
                      onPressed: () => _showSendMessageDialog(user),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      case 2:
        return Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favorite Item 1',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.favorite, color: Colors.red),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favorite Item 2',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.favorite_border, color: Colors.red),
                ],
              ),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bookmark 1',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.bookmark, color: Colors.green),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bookmark 2',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.bookmark_border, color: Colors.green),
                ],
              ),
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History Item 1',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.history, color: Colors.orange),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History Item 2',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.history, color: Colors.orange),
                ],
              ),
            ),
          ],
        );
      case 5:
        return Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'More Options',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.more_horiz, color: Colors.purple),
                ],
              ),
            ),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }
}

class _SwitchableContentWidget extends StatefulWidget {
  final VoidCallback onToggle;
  final bool showAddPost;
  final bool showProfile;
  final Widget monthes;
  final Widget addPost;
  final Widget profile;

  const _SwitchableContentWidget({
    required this.onToggle,
    required this.showAddPost,
    required this.showProfile,
    required this.monthes,
    required this.addPost,
    required this.profile,
  });

  @override
  _SwitchableContentWidgetState createState() =>
      _SwitchableContentWidgetState();
}

class _SwitchableContentWidgetState extends State<_SwitchableContentWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuint),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void didUpdateWidget(_SwitchableContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showAddPost != widget.showAddPost ||
        oldWidget.showProfile != widget.showProfile) {
      // Change animation direction based on transition
      Offset beginOffset;

      // Determine which widget was shown before and which is shown now
      bool wasAddPost = oldWidget.showAddPost;
      bool wasProfile = oldWidget.showProfile;
      bool isAddPost = widget.showAddPost;
      bool isProfile = widget.showProfile;

      if (isAddPost && !wasAddPost) {
        // Transition to addPost: from right
        beginOffset = Offset(1.0, 0.0);
      } else if (isProfile && !wasProfile) {
        // Transition to profile: from left
        beginOffset = Offset(-1.0, 0.0);
      } else if (!isAddPost && !isProfile) {
        // Transition to monthes: from opposite direction
        if (wasAddPost) {
          // From addPost to monthes: to right (slide out to right)
          beginOffset = Offset(-1.0, 0.0);
        } else if (wasProfile) {
          // From profile to monthes: to left (slide out to left)
          beginOffset = Offset(1.0, 0.0);
        } else {
          // Default
          beginOffset = Offset(1.0, 0.0);
        }
      } else {
        // Default
        beginOffset = Offset(1.0, 0.0);
      }

      _slideAnimation = Tween<Offset>(begin: beginOffset, end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuint),
          );
      _controller.reset();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;
    if (widget.showAddPost) {
      currentWidget = widget.addPost;
    } else if (widget.showProfile) {
      currentWidget = widget.profile;
    } else {
      currentWidget = widget.monthes;
    }
    return SlideTransition(position: _slideAnimation, child: currentWidget);
  }
}

// Widget لعرض نص متحرك من اليسار إلى اليمين
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value * 100, 0),
          child: Text(
            widget.text,
            style: widget.style,
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
        );
      },
    );
  }
}
