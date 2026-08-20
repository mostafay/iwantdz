import 'dart:ui';
import 'package:flutter/material.dart';

// تحكم خارجي بالصفحة: يسمح لأي كود خارجي بإصدار أمر إخفاء الحاوية
// مع تلاشي محتوى الصفحة (وانتظار انتهاء الحركة)، وأمر إظهار مرة أخرى
class BottomSheetsPageController {
  Future<void> Function()? _hideAndFadeImpl;
  VoidCallback? _showImpl;
  VoidCallback? _hideProfileCircleImpl;
  VoidCallback? _showProfileCircleImpl;

  void _attach({required Future<void> Function() hideAndFade, required VoidCallback show, required VoidCallback hideProfileCircle, required VoidCallback showProfileCircle}) {
    _hideAndFadeImpl = hideAndFade;
    _showImpl = show;
    _hideProfileCircleImpl = hideProfileCircle;
    _showProfileCircleImpl = showProfileCircle;
  }

  void _detach() {
    _hideAndFadeImpl = null;
    _showImpl = null;
    _hideProfileCircleImpl = null;
    _showProfileCircleImpl = null;
  }

  /// يخفي الحاوية ويلاشي محتوى الصفحة، ويُكمل الـ Future عند انتهاء الحركتين فعليًا
  Future<void> hideAndFade() => _hideAndFadeImpl?.call() ?? Future.value();

  /// يُظهر الحاوية مجددًا مع ظهور متدرج لمحتوى الصفحة
  void show() => _showImpl?.call();

  /// يخفي دائرة البروفايل بالانيميشن
  void hideProfileCircle() => _hideProfileCircleImpl?.call();

  /// يُظهر دائرة البروفايل بالانيميشن
  void showProfileCircle() => _showProfileCircleImpl?.call();
}

/// نمط شكل خلفية الحاوية:
/// - [solid]: الوضع الافتراضي الحالي (لون بنفسجي مصمت)
/// - [frostedGlass]: حاوية ضبابية شفافة (Glassmorphism) مع تمويه للخلفية
enum BottomSheetContainerStyle { solid, frostedGlass }

class BottomSheetsPage extends StatefulWidget {
  const BottomSheetsPage({
    super.key,
    this.popin = 50,
    this.downchildpading = 10,
    this.upchild,
    this.downchild,
    this.controller,
    this.topRadius = 40,
    this.isprofile = false,
    this.profileChild,
    this.candrop = false,
    this.profileCircleSize = 120,
    this.containerStyle = BottomSheetContainerStyle.solid,
    this.containerColor = Colors.deepPurple,
    this.frostedBlurSigma = 18,
  });
  final Widget? upchild;
  final Widget? downchild;
  final double downchildpading;
  final double topRadius;
  final bool isprofile;
  final bool candrop;

  /// محتوى يُعرض داخل دائرة البروفايل (مثل صورة المستخدم)، يظهر فقط عند isprofile = true
  final Widget? profileChild;

  /// قطر دائرة البروفايل
  final double profileCircleSize;

  final int popin;
  final BottomSheetsPageController? controller;

  /// نمط خلفية الحاوية: مصمت بلون محدد (افتراضي) أو ضبابي شفاف بدون لون
  final BottomSheetContainerStyle containerStyle;

  /// اللون الأساسي للحاوية، يُستخدم فقط في [BottomSheetContainerStyle.solid]
  /// (لا يُستخدم إطلاقًا في الوضع الضبابي [BottomSheetContainerStyle.frostedGlass])
  final Color containerColor;

  /// شدة التمويه عند استخدام [BottomSheetContainerStyle.frostedGlass]
  final double frostedBlurSigma;

  @override
  State<BottomSheetsPage> createState() => _BottomSheetsPageState();
}

class _BottomSheetsPageState extends State<BottomSheetsPage> with TickerProviderStateMixin {
  double _sheetPosition = 0.0;
  late AnimationController _animationController;
  late AnimationController _pageFadeController;
  late AnimationController _profileAnimationController; // حركة مستقلة خاصة بالدائرة فقط
  bool _manualProfileControl = false; // منع التحكم التلقائي عند التحكم اليدوي

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _pageFadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this, value: 0.0);
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
      value: 0.0,
    );
    _sheetPosition = (widget.popin / 100).clamp(0.0, 1.0);
    widget.controller?._attach(hideAndFade: _hideAndFadePage, show: _showPageWithFade, hideProfileCircle: _hideProfileCircle, showProfileCircle: _showProfileCircle);
    _scheduleInitialReveal();
  }

  void _scheduleInitialReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      if (size.height <= 0 || size.width <= 0) {
        _scheduleInitialReveal();
        return;
      }
      _showPageWithFade();
    });
  }

  @override
  void didUpdateWidget(covariant BottomSheetsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(hideAndFade: _hideAndFadePage, show: _showPageWithFade, hideProfileCircle: _hideProfileCircle, showProfileCircle: _showProfileCircle);
    }
    if (oldWidget.popin != widget.popin) {
      setState(() {
        _sheetPosition = (widget.popin / 100).clamp(0.0, 1.0);
      });
      // منع إعادة تشغيل انيميشن الدائرة عند التحكم اليدوي
      if (!_manualProfileControl) {
        _showPageWithFade();
      } else {
        // تحديث الحاوية فقط بدون التأثير على الدائرة
        _animationController.animateTo(_sheetPosition, curve: Curves.easeInOutQuint);
        _pageFadeController.animateTo(1.0, curve: Curves.easeInOut);
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _animationController.dispose();
    _pageFadeController.dispose();
    _profileAnimationController.dispose();
    super.dispose();
  }

  // يحرّك الشيت بشكل متحرك (animated) إلى النسبة المطلوبة
  void _showBottomSheet(double position) {
    setState(() {
      _sheetPosition = position;
    });
    _animationController.animateTo(position, curve: Curves.easeInOutQuint);
    if (widget.isprofile && !_manualProfileControl) {
      // في كل مرة تتحرك فيها الحاوية لموضع جديد (فتح أولي، تحديث popin، أو استقرار بعد السحب)
      // نعيد تشغيل حركة نزول الدائرة من جديد لتتبع الموضع الجديد
      _profileAnimationController.forward(from: 0.0);
    }
  }

  void _showPageWithFade() {
    _showBottomSheet(_sheetPosition);
    _pageFadeController.animateTo(1.0, curve: Curves.easeInOut);
    if (widget.isprofile) {
      // إعادة تعيين التحكم اليدوي للسماح بالحركة التلقائية
      _manualProfileControl = false;
      // حركة مستقلة تمامًا: منحنى ومدة خاصة بالدائرة، لا علاقة لها بمنحنى الحاوية
      _profileAnimationController.animateTo(1.0, curve: Curves.easeOutQuint);
    }
  }

  void _hideProfileCircle() {
    // نفس انيميشن إخفاء الدائرة عند مغادرة الصفحة (نحو الأعلى)
    _manualProfileControl = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    _profileAnimationController.animateTo(0.0, curve: Curves.easeInQuint);
  }

  void _showProfileCircle() {
    // نفس انيميشن إظهار الدائرة عند فتح الصفحة
    _manualProfileControl = true;
    _profileAnimationController.animateTo(1.0, curve: Curves.easeOutQuint);
  }

  Future<void> _hideAndFadePage() async {
    await Future.wait([
      _animationController.animateTo(0.0, curve: Curves.easeInOutQuint),
      _pageFadeController.animateTo(0.0, curve: Curves.easeInOut),
      if (widget.isprofile) _profileAnimationController.animateTo(0.0, curve: Curves.easeInQuint),
    ]);
  }

  // الـ Slider يحدد فقط النسبة المستهدفة التي سيظهر بها الشيت عند فتحه،
  // بدون أي تأثير على موضع الحاوية الحالي
  void _onSliderChanged(double value) {
    setState(() {
      _sheetPosition = value;
    });
  }

  // أثناء سحب مقبض الشيت: يحرّك الحاوية فقط، دون التأثير على قيمة الشريط
  void _onHandleDragUpdate(DragUpdateDetails details, double sheetHeight) {
    final delta = details.primaryDelta ?? 0.0;
    final newValue = (_animationController.value - delta / sheetHeight).clamp(0.0, 1.0);
    _animationController.value = newValue;
  }

  // عند رفع الإصبع: إكمال الحركة (snap) لأقرب نسبة مفتوحة أو الإغلاق التام،
  // دون التأثير على قيمة الشريط أيضًا
  void _onHandleDragEnd(DragEndDetails details) {
    final value = _animationController.value;
    double target;
    if (value < 0.15) {
      target = 0.0;
    } else if (value < 0.5) {
      target = 0.5;
    } else if (value < 0.85) {
      target = 0.75;
    } else {
      target = 1.0;
    }
    _animationController.animateTo(target, curve: Curves.easeInOutQuint);
  }

  double _profileCircleTop(double bodyHeight, double p) {
    final double r = widget.profileCircleSize / 2;
    final double topEdge = bodyHeight * (1 - _sheetPosition);
    final double restingTop = topEdge - r;
    final double hiddenTop = -bodyHeight;
    return hiddenTop * (1 - p) + restingTop * p;
  }

  bool get _isFrosted => widget.containerStyle == BottomSheetContainerStyle.frostedGlass;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyHeight = constraints.maxHeight;
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: FadeTransition(opacity: _pageFadeController, child: widget.upchild ?? const SizedBox.shrink()),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                if (_animationController.value <= 0) return const SizedBox.shrink();
                final currentHeight = bodyHeight * _animationController.value;

                // إذا كانت الحاوية تظهر بالكامل (تغطي كل المساحة) نلغي التدوير تمامًا
                final effectiveRadius = _animationController.value >= 1.0 ? 0.0 : widget.topRadius;
                final borderRadius = BorderRadius.vertical(top: Radius.circular(effectiveRadius));

                // بناء محتوى الحاوية (الديكور + الأطفال) بشكل مشترك بين الوضعين
                final containerBody = Container(
                  width: double.infinity,
                  height: bodyHeight,
                  padding: EdgeInsets.all(widget.downchildpading),
                  decoration: BoxDecoration(
                    // الوضع المصمت (solid) فقط هو من يحمل لونًا؛ الوضع الضبابي
                    // بدون أي لون خلفية إطلاقًا، الاعتماد كليًا على التمويه (BackdropFilter)
                    color: _isFrosted ? Colors.transparent : widget.containerColor,
                    borderRadius: borderRadius,
                    border: _isFrosted ? Border.all(color: Colors.white.withOpacity(0.25), width: 1) : null,
                    boxShadow: [],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: borderRadius,
                          child: widget.downchild ?? const SizedBox.shrink(),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (details) =>
                              widget.candrop ? _onHandleDragUpdate(details, bodyHeight) : null,
                          onVerticalDragEnd: widget.candrop ? _onHandleDragEnd : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: widget.candrop
                                  ? Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 255, 255, 255),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    )
                                  : Container(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: currentHeight,
                    child: ClipRect(
                      child: OverflowBox(
                        minHeight: bodyHeight,
                        maxHeight: bodyHeight,
                        alignment: Alignment.topCenter,
                        // نلف الحاوية بـ ClipRRect + BackdropFilter فقط في الوضع الضبابي
                        // كي يتم تمويه ما خلفها (upchild) دون التأثير على الوضع الافتراضي
                        child: _isFrosted
                            ? ClipRRect(
                                borderRadius: borderRadius,
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: widget.frostedBlurSigma,
                                    sigmaY: widget.frostedBlurSigma,
                                  ),
                                  child: containerBody,
                                ),
                              )
                            : containerBody,
                      ),
                    ),
                  ),
                );
              },
            ),
            // طبقة دائرة البروفايل: أمام الحاوية تمامًا، تتحرك بعكس اتجاهها
            // وتتوقف بمجرد أن يغطي نصفها الحاوية
            if (widget.isprofile)
              AnimatedBuilder(
                animation: _profileAnimationController, // مستقل تمامًا عن الحاوية
                builder: (context, child) {
                  final p = _profileAnimationController.value;
                  if (p <= 0) return const SizedBox.shrink();

                  // نحصر القيمة بين 0 و1 كي لا يكسر تجاوز easeOutBack المؤقت الموضعَ النهائي
                  final pClamped = p.clamp(0.0, 1.0);
                  final top = _profileCircleTop(bodyHeight, pClamped);

                  return Positioned(
                    left: 0,
                    right: 0,
                    top: top,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: widget.profileCircleSize,
                          height: widget.profileCircleSize,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.deepPurple, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: widget.profileChild,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
