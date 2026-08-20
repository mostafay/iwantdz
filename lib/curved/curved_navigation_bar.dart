import 'package:universal_io/io.dart';
import 'dart:math';

import 'curved_navigation_bar_item.dart';
import 'src/nav_bar_item_widget.dart';
import 'src/nav_custom_clipper.dart';
import 'package:flutter/material.dart';

import 'src/nav_custom_painter.dart';

typedef _LetIndexPage = bool Function(int value);

class CurvedNavigationBar extends StatefulWidget {
  /// Defines the appearance of the [CurvedNavigationBarItem] list that are
  /// arrayed within the bottom navigation bar.
  final List<CurvedNavigationBarItem> items;

  /// Defines the appearance of the [CurvedNavigationBarItem] list that are
  /// arrayed within the bottom navigation bar when height is expanded.
  final List<CurvedNavigationBarItem>? items2;

  /// The index into [items] for the current active [CurvedNavigationBarItem].
  final int index;

  /// The color of the [CurvedNavigationBar] itself, default Colors.white.
  final Color color;

  /// The background color of floating button, default same as [color] attribute.
  final Color? buttonBackgroundColor;

  /// The color of [CurvedNavigationBar]'s background, default Colors.blueAccent.
  final Color backgroundColor;

  /// Called when one of the [items] is tapped.
  final ValueChanged<int>? onTap;

  /// Function which takes page index as argument and returns bool. If function
  /// returns false then page is not changed on button tap. It returns true by
  /// default.
  final _LetIndexPage letIndexChange;

  /// Curves interpolating button change animation, default Curves.easeOut.
  final Curve animationCurve;

  /// Duration of button change animation, default Duration(milliseconds: 600).
  final Duration animationDuration;

  /// Height of [CurvedNavigationBar].
  final double height;

  /// Max width of [CurvedNavigationBar].
  final double? maxWidth;

  /// Padding of icon in floating button.
  final double iconPadding;

  /// Check if [CurvedNavigationBar] has label.
  final bool hasLabel;

  CurvedNavigationBar({
    Key? key,
    required this.items,
    this.items2,
    this.index = 0,
    this.color = Colors.white,
    this.buttonBackgroundColor,
    this.backgroundColor = Colors.blueAccent,
    this.onTap,
    _LetIndexPage? letIndexChange,
    this.animationCurve = Curves.easeOut,
    this.animationDuration = const Duration(milliseconds: 600),
    this.iconPadding = 12.0,
    this.maxWidth,
    double? height,
  }) : letIndexChange = letIndexChange ?? ((_) => true),
       assert(items.isNotEmpty),
       assert(items2 == null || items2.isNotEmpty),
       assert(0 <= index && index < items.length),
       assert(items2 == null || 0 <= index && index < items2.length),
       assert(maxWidth == null || 0 <= maxWidth),
       height = height ?? (Platform.isAndroid ? 70.0 : 80.0),
       hasLabel = items.any((item) => item.label != null),
       super(key: key);

  @override
  CurvedNavigationBarState createState() => CurvedNavigationBarState();
}

class CurvedNavigationBarState extends State<CurvedNavigationBar> with SingleTickerProviderStateMixin {
  late double _startingPos;
  late int _endingIndex;
  late double _pos;
  late Widget _icon;
  late AnimationController _animationController;
  late int _length;
  double _buttonHide = 0;

  List<CurvedNavigationBarItem> get _currentItems => widget.items2 ?? widget.items;

  @override
  void initState() {
    super.initState();
    _icon = _currentItems[widget.index].child;
    _length = _currentItems.length;
    _pos = widget.index / _length;
    _startingPos = widget.index / _length;
    _endingIndex = widget.index;
    _animationController = AnimationController(vsync: this, value: _pos);
    _animationController.addListener(() {
      setState(() {
        _pos = _animationController.value;
        final endingPos = _endingIndex / _currentItems.length;
        final middle = (endingPos + _startingPos) / 2;
        if ((endingPos - _pos).abs() < (_startingPos - _pos).abs()) {
          _icon = _currentItems[_endingIndex].child;
        }
        _buttonHide = (1 - ((middle - _pos) / (_startingPos - middle)).abs()).abs();
      });
    });
  }

  @override
  void didUpdateWidget(CurvedNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if items2 changed
    if (oldWidget.items2 != widget.items2) {
      setState(() {
        _length = _currentItems.length;
        _endingIndex = widget.index;
        _icon = _currentItems[widget.index].child;
        // عند التبديل من items2 إلى items، نقوم بتحديث فوري لظهور الدائرة
        if (widget.items2 == null) {
          _pos = widget.index / _length;
          _startingPos = _pos;
          _animationController.value = _pos;
        }
        // عند التبديل إلى items2، لا نقوم بتحديث _pos
      });
    }
    if (oldWidget.index != widget.index) {
      final newPosition = widget.index / _length;
      _startingPos = _pos;
      _endingIndex = widget.index;
      // لا نقوم بتحديث الأنيميشن في وضع items2
      if (widget.items2 == null) {
        _animationController.animateTo(newPosition, duration: widget.animationDuration, curve: widget.animationCurve);
      }
    }
    if (!_animationController.isAnimating) {
      _icon = _currentItems[_endingIndex].child;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);

    // وضع الإعدادات: شريط بسيط بدون قص ودون تدوير
    if (widget.items2 != null) {
      return SizedBox(
        height: widget.height,
        child: Container(
          color: widget.color,
          child: Column(
            children: [
              // الأزرار في أعلى الحاوية
              Container(
                height: 75.0,
                constraints: BoxConstraints(minHeight: 75.0, maxHeight: 75.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _currentItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == widget.index;
                    return Expanded(
                      child: InkWell(
                        onTap: () => _buttonTap(index),
                        child: Container(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(maxHeight: 62.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    isSelected ? Colors.red : Colors.grey,
                                    BlendMode.srcIn,
                                  ),
                                  child: item.child,
                                ),
                              ),
                              if (item.label != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Text(
                                    item.label!.length > 12 ? item.label!.substring(0, 12) : item.label!,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style:
                                        item.labelStyle?.copyWith(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 9,
                                          height: 1.0,
                                        ) ??
                                        TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 9,
                                          height: 1.0,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // المساحة المتبقية
              Expanded(child: Container()),
            ],
          ),
        ),
      );
    }

    // الوضع العادي: شريط منحني مع القص والتدوير
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = min(constraints.maxWidth, widget.maxWidth ?? constraints.maxWidth);
          return Align(
            alignment: textDirection == TextDirection.ltr ? Alignment.bottomLeft : Alignment.bottomRight,
            child: Container(
              color: widget.backgroundColor,
              width: maxWidth,
              child: ClipRect(
                clipper: NavCustomClipper(deviceHeight: MediaQuery.sizeOf(context).height),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    // Floating button circle
                    Positioned(
                      bottom: widget.height - 105.0,
                      left: textDirection == TextDirection.rtl ? null : _pos * maxWidth,
                      right: textDirection == TextDirection.rtl ? _pos * maxWidth : null,
                      width: maxWidth / _length,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, (_buttonHide.isNaN ? 0 : (_buttonHide - 1)) * 80),
                          child: Material(
                            color: widget.buttonBackgroundColor ?? widget.color,
                            type: MaterialType.circle,
                            child: Padding(padding: EdgeInsets.all(widget.iconPadding), child: _icon),
                          ),
                        ),
                      ),
                    ),
                    // Background
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CustomPaint(
                        painter: NavCustomPainter(
                          startingLoc: _pos,
                          itemsLength: _length,
                          color: widget.color,
                          textDirection: Directionality.of(context),
                          hasLabel: widget.hasLabel,
                          fixedHeight: 75.0,
                        ),
                        child: Container(height: widget.height),
                      ),
                    ),
                    // Unselected buttons
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: SizedBox(
                        height: 75.0,
                        child: Row(
                          children: _currentItems.map((item) {
                            return NavBarItemWidget(
                              onTap: _buttonTap,
                              position: _pos,
                              length: _length,
                              index: _currentItems.indexOf(item),
                              child: Center(child: item.child),
                              label: item.label,
                              labelStyle: item.labelStyle,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void setPage(int index) {
    _buttonTap(index);
  }

  void _buttonTap(int index) {
    if (!widget.letIndexChange(index) || _animationController.isAnimating) {
      return;
    }
    if (widget.onTap != null) {
      widget.onTap!(index);
    }
    final newPosition = index / _length;
    setState(() {
      _startingPos = _pos;
      _endingIndex = index;
      // إلغاء حركة الدائرة المنبثقة عند استخدام items2
      if (widget.items2 != null) {
        // لا نقوم بتحديث _pos في وضع الإعدادات
        // الدائرة تبقى في موقعها
        _icon = _currentItems[index].child;
      } else {
        _animationController.animateTo(newPosition, duration: widget.animationDuration, curve: widget.animationCurve);
      }
    });
  }
}
