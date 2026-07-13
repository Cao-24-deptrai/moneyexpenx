import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final double borderWidth;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const GlassContainer({
    Key? key,
    required this.child,
    this.blur = 15,
    this.borderRadius = 16,
    this.borderWidth = 1.0,
    this.color = const Color(0x10FFFFFF),
    this.borderColor = const Color(0x1AFFFFFF),
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.05),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final double size;

  const GlassIconButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.iconColor = AppTheme.primaryYellow,
    this.size = 24,
  }) : super(key: key);

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GlassContainer(
            borderRadius: 12,
            padding: const EdgeInsets.all(10),
            color: const Color(0x15FFFFFF),
            borderColor: const Color(0x22FFFFFF),
            child: Icon(
              widget.icon,
              color: widget.iconColor,
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCardButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final Color color;
  final Color borderColor;

  const GlassCardButton({
    Key? key,
    required this.child,
    required this.onTap,
    this.borderRadius = 16,
    this.color = const Color(0x12FFFFFF),
    this.borderColor = const Color(0x1AFFFFFF),
  }) : super(key: key);

  @override
  State<GlassCardButton> createState() => _GlassCardButtonState();
}

class _GlassCardButtonState extends State<GlassCardButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GlassContainer(
        borderRadius: widget.borderRadius,
        color: widget.color,
        borderColor: widget.borderColor,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: AppTheme.primaryYellow.withOpacity(0.15),
            highlightColor: Colors.transparent,
            onTapDown: (_) => _controller.forward(),
            onTapCancel: () => _controller.reverse(),
            onTap: () {
              _controller.reverse();
              widget.onTap();
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
