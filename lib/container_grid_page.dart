import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'mapscreen.dart';

class ContainerModel {
  final String id;
  final double defaultWidth;
  final double defaultHeight;
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;
  final Color color;
  final LatLng pos;

  ContainerModel({
    required this.id,
    required this.defaultWidth,
    required this.defaultHeight,
    required this.minWidth,
    required this.maxWidth,
    required this.minHeight,
    required this.maxHeight,
    required this.color,
    required this.pos,
  });
}

/// أنواع عرض الشبكة الثلاثة
enum GridDisplayMode {
  horizontal, // عرض أفقي مع تمرير أفقي (الحالي)
  verticalGrid, // عرض عمودي بتمرير عمودي بـ width محدود (Grid كما هو حالياً)
  verticalList, // عرض عمودي بتمرير عمودي بـ width لا نهائي (كل عنصر ياخذ العرض الكامل)
}

class ContainerGridPage extends StatefulWidget {
  final VoidCallback? onContainerSelected;
  final void Function(ContainerModel container, LatLng pos)? onContainerLongPress; // مُحدَّث
  final void Function(ContainerModel container, LatLng pos)? onContainerShodetaile; // مُحدَّث
  final VoidCallback? onScroll; // دالة تنفذ عند بدء التمرير
  final GridDisplayMode startMode;
  final bool showToggleButton;
  final double? cardHeight;
  final double bottomExtraSpace; // مسافة إضافية أسفل التمرير العمودي حتى لا يختفي آخر عنصر خلف شريط التنقل السفلي
  final List<ContainerModel>? externalContainers; // قائمة خارجية اختيارية

  const ContainerGridPage({
    super.key,
    this.onContainerSelected,
    this.onContainerLongPress,
    this.onContainerShodetaile,
    this.onScroll,
    this.startMode = GridDisplayMode.verticalGrid,
    this.showToggleButton = true,
    this.cardHeight,
    this.bottomExtraSpace = 140,
    this.externalContainers, // إضافة المعامل الجديد
  });

  @override
  State<ContainerGridPage> createState() => _ContainerGridPageState();
}

class _ContainerGridPageState extends State<ContainerGridPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late GridDisplayMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.startMode; // يأخذ القيمة الابتدائية من الودجت
    
    // استخدام القائمة الخارجية إذا تم توفيرها، وإلا استخدام القائمة الافتراضية
    if (widget.externalContainers != null && widget.externalContainers!.isNotEmpty) {
      containers = widget.externalContainers!;
    }
  }

  List<ContainerModel> containers = [
    ContainerModel(
      id: 'C1',
      defaultWidth: 100,
      defaultHeight: 100,
      minWidth: 50,
      maxWidth: 200,
      minHeight: 50,
      maxHeight: 200,
      color: Colors.blue.shade100,
      pos: const LatLng(42.3601, -71.0589),
    ),
    ContainerModel(
      id: 'C2',
      defaultWidth: 120,
      defaultHeight: 80,
      minWidth: 60,
      maxWidth: 180,
      minHeight: 40,
      maxHeight: 160,
      color: Colors.green.shade100,
      pos: const LatLng(38.9072, -77.0369),
    ),
    ContainerModel(
      id: 'C3',
      defaultWidth: 80,
      defaultHeight: 120,
      minWidth: 40,
      maxWidth: 160,
      minHeight: 60,
      maxHeight: 200,
      color: Colors.orange.shade100,
      pos: const LatLng(41.8781, -87.6298),
    ),
    ContainerModel(
      id: 'C4',
      defaultWidth: 100,
      defaultHeight: 100,
      minWidth: 50,
      maxWidth: 200,
      minHeight: 50,
      maxHeight: 200,
      color: Colors.purple.shade100,
      pos: const LatLng(34.0522, -118.2437),
    ),
    ContainerModel(
      id: 'C5',
      defaultWidth: 150,
      defaultHeight: 90,
      minWidth: 70,
      maxWidth: 220,
      minHeight: 50,
      maxHeight: 180,
      color: Colors.red.shade100,
      pos: const LatLng(29.7604, -95.3698),
    ),
    ContainerModel(
      id: 'C6',
      defaultWidth: 90,
      defaultHeight: 110,
      minWidth: 45,
      maxWidth: 170,
      minHeight: 55,
      maxHeight: 190,
      color: Colors.teal.shade100,
      pos: const LatLng(25.7617, -80.1918),
    ),
  ];

  // يدور بين الوضعين الجديدين فقط (الأفقي القديم مستثنى تمامًا من هذا الزر)
  void _cycleMode() {
    setState(() {
      switch (_mode) {
        case GridDisplayMode.verticalGrid:
          _mode = GridDisplayMode.verticalList;
          break;
        case GridDisplayMode.verticalList:
          _mode = GridDisplayMode.verticalGrid;
          break;
        case GridDisplayMode.horizontal:
          // لا يُستدعى عمليًا لأن الزر غير ظاهر في هذا الوضع
          break;
      }
    });
  }

  IconData get _toggleIcon {
    switch (_mode) {
      case GridDisplayMode.verticalGrid:
        return Icons.grid_view; // يعرض الوضع الحالي، اضغط للتالي
      case GridDisplayMode.verticalList:
        return Icons.view_agenda;
      case GridDisplayMode.horizontal:
        return Icons.grid_view; // غير مستخدم فعليًا (الزر مخفي في هذا الوضع)
    }
  }

  String get _toggleTooltip {
    switch (_mode) {
      case GridDisplayMode.verticalGrid:
        return 'شبكي (اضغط للتبديل إلى قائمة عريضة)';
      case GridDisplayMode.verticalList:
        return 'قائمة عريضة (اضغط للتبديل إلى شبكي)';
      case GridDisplayMode.horizontal:
        return '';
    }
  }

  bool get _isHorizontal => _mode == GridDisplayMode.horizontal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Padding(
            padding: _isHorizontal
                ? const EdgeInsets.all(20.0)
                : EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 6.0 + widget.bottomExtraSpace),
            child: switch (_mode) {
              GridDisplayMode.horizontal => _buildHorizontalList(),
              GridDisplayMode.verticalGrid => _buildGrid(),
              GridDisplayMode.verticalList => _buildVerticalFullWidthList(),
            },
          ),
          // زر التبديل يظهر فقط في الوضعين الجديدين (شبكي / قائمة عريضة)، ويختفي في الوضع الأفقي القديم
          if (widget.showToggleButton && !_isHorizontal)
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: Material(
                  color: Colors.black.withOpacity(0.35),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: Icon(_toggleIcon, color: Colors.white),
                    tooltip: _toggleTooltip,
                    onPressed: _cycleMode,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollStartNotification) {
          widget.onScroll?.call();
        }
        return false;
      },
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 6,
          childAspectRatio: 1.2,
        ),
        itemCount: containers.length,
        itemBuilder: (context, index) {
          final container = containers[index];
          return _buildContainerCard(container);
        },
      ),
    );
  }

  // عرض عمودي بـ width لا نهائي: كل عنصر ياخذ العرض الكامل المتاح للصفحة
  Widget _buildVerticalFullWidthList() {
    final double height = widget.cardHeight ?? 135;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollStartNotification) {
          widget.onScroll?.call();
        }
        return false;
      },
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: containers.length,
        itemBuilder: (context, index) {
          final container = containers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SizedBox(width: double.infinity, height: height, child: _buildContainerCard(container)),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalList() {
    final double height = widget.cardHeight ?? 135;
    return SizedBox(
      height: height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollStartNotification) {
            widget.onScroll?.call();
          }
          return false;
        },
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: containers.length,
          itemBuilder: (context, index) {
            final container = containers[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 150,
                height: height,
                child: height < 100 ? _buildCompactCard(container) : _buildContainerCard(container),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactCard(ContainerModel container) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: InkWell(
        onTap: () {
          MainNavigation.topos = container.pos;
          widget.onContainerSelected?.call();
        },
        onLongPress: () {
          widget.onContainerLongPress?.call(container, container.pos);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Container(width: 6, height: 20, color: container.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  container.id,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(const Distance().as(LengthUnit.Kilometer, container.pos, MainNavigation.newYork)).toStringAsFixed(0)} km',
                style: const TextStyle(fontSize: 10, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContainerCard(ContainerModel container) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: InkWell(
        onTap: () {
          MainNavigation.topos = container.pos;
          widget.onContainerSelected?.call();
        },
        onLongPress: () {
          widget.onContainerLongPress?.call(container, container.pos);
        },
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container visualization
              Container(
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                ),
              ),
              // Container properties
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${container.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Pos: ${container.pos.latitude.toStringAsFixed(4)}, ${container.pos.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dist: ${(const Distance().as(LengthUnit.Kilometer, container.pos, MainNavigation.newYork)).toStringAsFixed(2)} km',
                      style: const TextStyle(fontSize: 10, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        spacing: 1,
                        children: [
                          Container(
                            height: 26,
                            width: 40,
                            //  color: Colors.black,
                            child: IconButton(
                              onPressed: () {
                                print("container : ${container.id}");
                                if (MainNavigation.idopen == container.id) {
                                  widget.onContainerShodetaile?.call(container, container.pos);
                                }
                              },
                              icon: Icon(
                                Icons.download,
                                color: MainNavigation.idopen == container.id ? Colors.red : Colors.blueGrey,
                              ), // تصحيح: Icons.download وليس downoad
                              padding: EdgeInsets.zero, // لإزالة الحواف الزائدة
                              constraints: BoxConstraints(), // لإزالة القيود الافتراضية
                            ),
                          ),
                          Container(height: 26, width: 40, color: Colors.black),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
