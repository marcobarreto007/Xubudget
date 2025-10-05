import 'package:flutter/material.dart';

/// Simple responsive container that centers content and constrains max width
/// to improve readability on large screens (web/desktop), while using full
/// width on phones.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer(
      {super.key, required this.child, this.maxWidth = 1000});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > maxWidth;
        final padding =
            EdgeInsets.symmetric(horizontal: isWide ? 24 : 12, vertical: 8);
        final body = Padding(padding: padding, child: child);
        if (!isWide) return body;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: body,
          ),
        );
      },
    );
  }
}
