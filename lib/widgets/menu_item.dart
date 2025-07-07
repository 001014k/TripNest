import 'package:flutter/material.dart';

class MenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  State<MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue;
    final Color primaryContainerColor = Colors.blue.shade100;
    final Color onSurfaceColor = Colors.black87;
    final Color onSurfaceVariantColor = Colors.black54;

    final textTheme = Theme.of(context).textTheme;

    final bool showBox = widget.isSelected || _isPressed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            setState(() {
              _isPressed = value;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: showBox ? primaryContainerColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: showBox
                  ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
              border: Border.all(
                color: showBox ? primaryColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: showBox
                        ? primaryColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: showBox
                        ? (widget.iconColor ?? primaryColor)
                        : (widget.iconColor ?? onSurfaceVariantColor),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: showBox
                        ? (widget.textColor ?? primaryColor)
                        : (widget.textColor ?? onSurfaceColor),
                    fontWeight: showBox ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (widget.isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
