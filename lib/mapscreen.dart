import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'openroute_service.dart';
import 'container_grid_page.dart';
import 'config.dart';

// فئة مخصصة لإنشاء حركة سلسة بين نقطتين على الخريطة
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
    : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}

// فئة لتمثيل مدينة على الخريطة
class CityMarker {
  final String name;
  final String arabicName;
  final LatLng center;
  final Color color;

  CityMarker({
    required this.name,
    required this.arabicName,
    required this.center,
    required this.color,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route Map',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  MainNavigation({super.key, this.setstate});
  final Function()? setstate;
  static const LatLng newYork = LatLng(36.743204, 2.980974);
  static const LatLng washington = LatLng(38.9072, -77.0369);
  static LatLng? topos;
  static Widget? label;
  static Widget? maap;
  static Map<String, dynamic>? selected_posision; // معلومات الموقع المختار
  static double shieght = 0;
  static double shieghtDF = 0;
  static String idopen = '';
  static bool sineUp = false;
  static String sineKey = '';
  static String sineBID = '';
  static Map<String, dynamic> userdata = {};
  static bool IsrealySined = false;
  static Future<void> Function()? refreshCurrentPage;
  static Function()? externalSetstate; // دالة مشتركة
  static final ValueNotifier<Widget?> labelNotifier = ValueNotifier<Widget?>(
    null,
  );

  // 🔹 جديد: للتحكم في رفع/إنزال اللوحة المنبثقة في MapScreen من الخارج (مثلاً من main.dart)
  static final ValueNotifier<bool> controlPanelRaisedNotifier =
      ValueNotifier<bool>(false);
  static final ValueNotifier<bool> controlPanelRaisedNotifierP2 =
      ValueNotifier<bool>(false);
  static final ValueNotifier<bool> controlPanelRaisedNotifierP3 =
      ValueNotifier<bool>(false);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    MapScreen(key: ValueKey('map_${DateTime.now().millisecondsSinceEpoch}')),
    ContainerGridPage(onContainerSelected: _handleContainerSelected),
  ];

  void _handleContainerSelected() {
    setState(() {
      _currentIndex = 0;
      _pages[0] = MapScreen(
        key: ValueKey('map_${DateTime.now().millisecondsSinceEpoch}'),
        setstate: widget.setstate,
      );
      //  widget.setstate.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            //        widget.setstate?.call();
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Containers',
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.setstate,
    this.cameraOffsetPercent = 0.0,
    this.selectSinglePosition = false,
    this.showControlPanel = true,
    this.showMultipleAreas = false, // وضع عرض مناطق متعددة بدلاً من مسار
  });
  final Function()? setstate;
  final double
  cameraOffsetPercent; // Percentage of visible height to move (0.0 to 1.0)
  final bool selectSinglePosition; // وضع اختيار موقع واحد فقط
  final bool showControlPanel; // للتحكم في عرض المربع المنبثق
  final bool showMultipleAreas; // وضع عرض مناطق متعددة بدلاً من مسار
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final OpenRouteService _openRouteService = OpenRouteService(
    apiKey:
        'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjI2ZTRkMWU4N2FlYzQ1YTk5ODRkOTlkYjIwN2FmMjY1IiwiaCI6Im11cm11cjY0In0=',
  );

  LatLng? _startPoint;
  LatLng? _endPoint;
  LatLng? _selectedPosition; // الموقع المختار في وضع selectSinglePosition
  String? _selectedLocationName; // اسم الموقع المختار
  String? _startPointName; // اسم نقطة البداية
  String? _endPointName; // اسم نقطة النهاية
  List<LatLng> _routePoints = [];
  bool _isLoading = false;
  String _errorMessage = '';
  double _routeDistance = 0;
  double _routeDuration = 0;
  late bool _showControlPanel; // للتحكم في ظهور المربع المنبثق
  late AnimationController _cameraAnimationController;
  late Animation<LatLng> _cameraAnimation;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _showControlPanel = widget.showControlPanel;
    _cameraAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.showMultipleAreas) {
      // وضع عرض مناطق متعددة - عرض جميع المناطق على الخريطة
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // جلب المستخدمين من السيرفر
        await _fetchUsersFromServer();

        if (widget.cameraOffsetPercent != 0 && mounted) {
          // Calculate offset based on visible height at current zoom level
          final currentZoom = _mapController.camera.zoom;
          // Visible height in degrees ≈ 360 / (2^zoom)
          final visibleHeightDegrees = 360 / (1 << currentZoom.toInt());
          final offsetDegrees =
              visibleHeightDegrees * widget.cameraOffsetPercent;

          final currentCenter = _mapController.camera.center;
          _mapController.move(
            LatLng(
              currentCenter.latitude + offsetDegrees,
              currentCenter.longitude,
            ),
            _mapController.camera.zoom,
          );
        }
      });
    } else if (widget.selectSinglePosition) {
      // وضع اختيار موقع واحد فقط - لا نحتاج لنقاط البداية/النهاية
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (widget.cameraOffsetPercent != 0 && mounted) {
          // Calculate offset based on visible height at current zoom level
          final currentZoom = _mapController.camera.zoom;
          // Visible height in degrees ≈ 360 / (2^zoom)
          final visibleHeightDegrees = 360 / (1 << currentZoom.toInt());
          final offsetDegrees =
              visibleHeightDegrees * widget.cameraOffsetPercent;

          final currentCenter = _mapController.camera.center;
          _mapController.move(
            LatLng(
              currentCenter.latitude + offsetDegrees,
              currentCenter.longitude,
            ),
            _mapController.camera.zoom,
          );
        }
      });
    } else {
      // وضع المسار العادي
      _startPoint = MainNavigation.newYork;
      if (MainNavigation.topos != null) {
        _endPoint = MainNavigation.topos;
        MainNavigation.topos = null;
      } else {
        _endPoint = MainNavigation.washington;
      }
      // Auto-fetch route on app start
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // استخراج أسماء المواقع
        if (_startPoint != null && mounted) {
          _startPointName = await _getLocationName(_startPoint!);
          if (mounted) setState(() {});
        }
        if (_endPoint != null && mounted) {
          _endPointName = await _getLocationName(_endPoint!);
          if (mounted) setState(() {});
        }
        // Wait for route to be fetched, then move camera if offset is set
        await _fetchRoute();
        if (widget.cameraOffsetPercent != 0 && mounted) {
          // Calculate offset based on visible height at current zoom level
          final currentZoom = _mapController.camera.zoom;
          // Visible height in degrees ≈ 360 / (2^zoom)
          final visibleHeightDegrees = 360 / (1 << currentZoom.toInt());
          final offsetDegrees =
              visibleHeightDegrees * widget.cameraOffsetPercent;

          final currentCenter = _mapController.camera.center;
          _mapController.move(
            LatLng(
              currentCenter.latitude + offsetDegrees,
              currentCenter.longitude,
            ),
            _mapController.camera.zoom,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _cameraAnimationController.dispose();
    super.dispose();
  }

  // دالة للتحرك إلى مدينة معينة وتكبير الخريطة بحركة سلسة
  void _zoomToCity(CityMarker city) {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;

    _cameraAnimation = LatLngTween(begin: currentCenter, end: city.center)
        .animate(
          CurvedAnimation(
            parent: _cameraAnimationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _zoomAnimation = Tween<double>(begin: currentZoom, end: 12.0).animate(
      CurvedAnimation(
        parent: _cameraAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _cameraAnimationController.addListener(() {
      _mapController.move(_cameraAnimation.value, _zoomAnimation.value);
    });

    _cameraAnimationController.forward(from: 0);
  }

  // بيانات المدن المتعددة للعرض كدبابيس
  List<CityMarker> _cities = [];

  // دالة لجلب المستخدمين من السيرفر
  Future<void> _fetchUsersFromServer() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getAllUsersPositionsUrl),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['users'] != null) {
          final List<dynamic> users = data['users'];
          final List<CityMarker> userMarkers = [];
          final colors = [
            Colors.red,
            Colors.green,
            Colors.blue,
            Colors.orange,
            Colors.purple,
            Colors.pink,
            Colors.teal,
            Colors.amber,
          ];

          for (int i = 0; i < users.length; i++) {
            final user = users[i];
            final position = user['position'];
            if (position != null && position.isNotEmpty) {
              final coords = position.split(',');
              if (coords.length == 2) {
                final lat = double.tryParse(coords[0]);
                final lng = double.tryParse(coords[1]);
                if (lat != null && lng != null) {
                  userMarkers.add(
                    CityMarker(
                      name: user['username'] ?? 'Unknown',
                      arabicName: user['username'] ?? 'Unknown',
                      center: LatLng(lat, lng),
                      color: colors[i % colors.length],
                    ),
                  );
                }
              }
            }
          }

          if (mounted) {
            setState(() {
              _cities = userMarkers;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching users from server: $e');
      // استخدام البيانات الافتراضية في حالة الخطأ
      if (mounted) {
        setState(() {
          _cities = [
            CityMarker(
              name: 'New York',
              arabicName: 'نيويورك',
              center: LatLng(40.7128, -74.0060),
              color: Colors.red,
            ),
            CityMarker(
              name: 'Washington DC',
              arabicName: 'واشنطن',
              center: LatLng(38.9072, -77.0369),
              color: Colors.green,
            ),
            CityMarker(
              name: 'Chicago',
              arabicName: 'شيكاغو',
              center: LatLng(41.8781, -87.6298),
              color: Colors.blue,
            ),
            CityMarker(
              name: 'Los Angeles',
              arabicName: 'لوس أنجلوس',
              center: LatLng(34.0522, -118.2437),
              color: Colors.orange,
            ),
            CityMarker(
              name: 'Houston',
              arabicName: 'هيوستن',
              center: LatLng(29.7604, -95.3698),
              color: Colors.purple,
            ),
          ];
        });
      }
    }
  }

  // Example coordinates (New York to Washington DC)

  // دالة لاستخراج اسم الموقع من الإحداثيات باستخدام Nominatim API
  Future<String?> _getLocationName(LatLng point) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.mp'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'] as String;
        }
      }
      return null;
    } catch (e) {
      print('Error getting location name: $e');
      return null;
    }
  }

  Future<void> _fetchRoute() async {
    if (_startPoint == null || _endPoint == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please select both start and end points';
          MainNavigation.label = _buildControlPanel();
          MainNavigation.labelNotifier.value = _buildControlPanel();
          MainNavigation.externalSetstate?.call();
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _routePoints = [];
        _routeDistance = 0;
        _routeDuration = 0;
      });
    }

    try {
      final route = await _openRouteService.getDirections(
        _startPoint!.longitude,
        _startPoint!.latitude,
        _endPoint!.longitude,
        _endPoint!.latitude,
      );

      final routeInfo = await _openRouteService.getRouteInfo(
        _startPoint!.longitude,
        _startPoint!.latitude,
        _endPoint!.longitude,
        _endPoint!.latitude,
      );

      if (mounted) {
        setState(() {
          _routePoints = route;
          _routeDistance = routeInfo['distance'] ?? 0;
          _routeDuration = routeInfo['duration'] ?? 0;
          _isLoading = false;
        });
      }

      // Fit map to show the entire route
      if (mounted && _routePoints.isNotEmpty) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(_routePoints),
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch route: $e';
          _isLoading = false;
        });
      }
    }
    MainNavigation.label = _buildControlPanel();
    MainNavigation.labelNotifier.value = _buildControlPanel();
    MainNavigation.externalSetstate?.call();
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _errorMessage = '';
      _routeDistance = 0;
      _routeDuration = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          // عرض معلومات المدن في وضع المدن المتعددة
          if (widget.showMultipleAreas)
            Positioned(
              top: 30,
              left: 8,
              right: 8,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'المدن الأمريكية',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _cities
                              .map(
                                (city) => GestureDetector(
                                  onTap: () {
                                    _zoomToCity(city);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: city.color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: city.color,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: city.color,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          city.arabicName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // المربع المنبثق في أعلى الشاشة
          if (_showControlPanel && !widget.showMultipleAreas)
            ValueListenableBuilder<bool>(
              valueListenable: MainNavigation.controlPanelRaisedNotifier,
              builder: (context, isRaised, child) {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  top: isRaised
                      ? -140
                      : 30, // يرتفع للأعلى ويخرج من الشاشة عند isRaised = true
                  left: 8,
                  right: 8,
                  child: child!,
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // محتوى لوحة التحكم بمساحة ديناميكية قابل للتمرير
                        Positioned.fill(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(8),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: _buildControlPanel(),
                            ),
                          ),
                        ),
                        // زر الإغلاق في الزاوية العلوية
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () {
                              setState(() {
                                _showControlPanel = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _fetchRoute,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.directions),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(0),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Start: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              ClipRect(
                child: SizedBox(
                  width: 150,
                  child: _MarqueeText(
                    text: _startPointName ?? 'Loading...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'End: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              ClipRect(
                child: SizedBox(
                  width: 150,
                  child: _MarqueeText(
                    text: _endPointName ?? 'Loading...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_routeDistance > 0)
            Text(
              'Distance: ${(_routeDistance / 1000).toStringAsFixed(2)} km',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
          if (_routeDuration > 0)
            Text(
              'Duration: ${(_routeDuration / 60).toStringAsFixed(0)} min',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.black,
              ),
            ),
          if (_errorMessage.isNotEmpty)
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
          const Text(
            'Tap on map to set start/end points',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.showMultipleAreas
            ? LatLng(
                39.8283,
                -98.5795,
              ) // مركز الولايات المتحدة لعرض جميع المناطق
            : _startPoint ?? MainNavigation.newYork,
        initialZoom: widget.showMultipleAreas ? 4 : 5,
        minZoom: 2,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onTap: widget.showMultipleAreas
            ? null
            : (tapPosition, point) {
                print(
                  'Selected location: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                );
                setState(() {
                  if (widget.selectSinglePosition) {
                    // وضع اختيار موقع واحد فقط - تسجيل الموقع في MainNavigation.selected_posision
                    _selectedPosition = point; // حفظ الموقع محلياً لعرض الدبوس
                    print(
                      'Selected position saved: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                    );
                    // استخراج اسم الموقع وحفظ كل المعلومات
                    _getLocationName(point).then((name) {
                      if (mounted) {
                        setState(() {
                          _selectedLocationName = name;
                          print('Location name: $name');
                          // استخراج الجزء الأول فقط من العنوان (قبل أول فاصلة)
                          String shortName = name ?? 'Unknown location';
                          if (shortName.contains(',')) {
                            shortName = shortName.split(',')[0].trim();
                          }
                          // حفظ كل معلومات الموقع في Map
                          MainNavigation.selected_posision = {
                            'latitude': point.latitude,
                            'longitude': point.longitude,
                            'position': '${point.latitude},${point.longitude}',
                            'name': name ?? 'Unknown location',
                            'shortName': shortName, // الاسم المختصر
                          };
                          print(
                            'Full location info: ${MainNavigation.selected_posision}',
                          );
                        });
                      }
                    });
                  } else {
                    // وضع المسار العادي
                    if (_startPoint == null) {
                      _startPoint = point;
                      print(
                        'Start point set: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                      );
                      // استخراج اسم نقطة البداية
                      _getLocationName(point).then((name) {
                        if (mounted) {
                          setState(() {
                            _startPointName = name;
                          });
                        }
                      });
                    } else if (_endPoint == null) {
                      _endPoint = point;
                      print(
                        'End point set: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                      );
                      // استخراج اسم نقطة النهاية
                      _getLocationName(point).then((name) {
                        if (mounted) {
                          setState(() {
                            _endPointName = name;
                          });
                        }
                      });
                    } else {
                      _startPoint = point;
                      _endPoint = null;
                      _routePoints = [];
                      _startPointName = null;
                      _endPointName = null;
                      print(
                        'New start point: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                      );
                      // استخراج اسم نقطة البداية الجديدة
                      _getLocationName(point).then((name) {
                        if (mounted) {
                          setState(() {
                            _startPointName = name;
                          });
                        }
                      });
                    }
                    MainNavigation.label = _buildControlPanel();
                    MainNavigation.labelNotifier.value = _buildControlPanel();
                    MainNavigation.externalSetstate?.call();
                  }
                });
              },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mp',
        ),
        // عرض الدبابيس للمدن المتعددة
        if (widget.showMultipleAreas)
          MarkerLayer(
            markers: _cities
                .map(
                  (city) => Marker(
                    point: city.center,
                    width: 60,
                    height: 85,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            city.arabicName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(Icons.location_on, color: city.color, size: 36),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        MarkerLayer(
          markers: [
            if (_selectedPosition != null && widget.selectSinglePosition)
              Marker(
                point: _selectedPosition!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            if (_startPoint != null &&
                !widget.selectSinglePosition &&
                !widget.showMultipleAreas)
              Marker(
                point: _startPoint!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 40,
                ),
              ),
            if (_endPoint != null &&
                !widget.selectSinglePosition &&
                !widget.showMultipleAreas)
              Marker(
                point: _endPoint!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
          ],
        ),
        if (_routePoints.isNotEmpty && !widget.showMultipleAreas)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
      ],
    );
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
