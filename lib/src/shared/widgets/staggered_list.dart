import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Fades + slides each child in with a small per-item delay, for list-style
/// content (dashboard lists, grade rows, notification rows). Not itself
/// scrollable — wrap it in the surrounding ListView/Column.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDelay;

  const StaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 40),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          _StaggeredItem(index: i, itemDelay: itemDelay, child: children[i]),
      ],
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Duration itemDelay;
  final Widget child;

  const _StaggeredItem({
    required this.index,
    required this.itemDelay,
    required this.child,
  });

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.base);
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.standard);
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: AppMotion.standard));
    Future.delayed(widget.itemDelay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
