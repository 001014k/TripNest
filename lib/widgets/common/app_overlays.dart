import 'package:flutter/material.dart';
import '../../design/app_design.dart';

/// Standard compact sheet with a fixed header and independently scrolling body.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppDesign.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      clipBehavior: Clip.antiAlias,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom) *
                  .82),
          child: builder(context),
        ),
      ),
    );

class AppSheet extends StatelessWidget {
  const AppSheet(
      {super.key,
      required this.title,
      this.subtitle,
      required this.children,
      this.footer});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title, style: AppDesign.headingMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(subtitle!, style: AppDesign.bodySmall),
                    ],
                  ])),
              IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 21)),
            ]),
          ),
          const Divider(height: 1, color: AppDesign.separator),
          Flexible(
              child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: children)),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(width: double.infinity, child: footer),
            ),
        ]),
      );
}

class AppSheetOption extends StatelessWidget {
  const AppSheetOption(
      {super.key,
      required this.title,
      required this.onTap,
      this.subtitle,
      this.icon,
      this.selected = false,
      this.destructive = false});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected, destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppDesign.travelStamp : AppDesign.primaryText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? AppDesign.secondaryBg : AppDesign.cardBg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          selected: selected,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: icon == null
              ? null
              : Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: AppDesign.secondaryBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 20, color: color),
                ),
          title:
              Text(title, style: AppDesign.bodyMedium.copyWith(color: color)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: AppDesign.bodySmall),
          trailing: Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              size: 20,
              color: selected ? AppDesign.primary : AppDesign.subtleText),
          onTap: onTap,
        ),
      ),
    );
  }
}

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog(
      {super.key,
      required this.title,
      required this.message,
      this.confirmLabel = '확인',
      this.destructive = false,
      this.icon = Icons.help_outline_rounded});
  final String title, message, confirmLabel;
  final bool destructive;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        backgroundColor: AppDesign.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: destructive
                      ? AppDesign.travelStamp.withValues(alpha: .08)
                      : AppDesign.secondaryBg,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon,
                  size: 24,
                  color:
                      destructive ? AppDesign.travelStamp : AppDesign.primary),
            )),
        title: Text(title, style: AppDesign.headingMedium),
        content: Text(message,
            style:
                AppDesign.bodyMedium.copyWith(color: AppDesign.secondaryText)),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor:
                      destructive ? AppDesign.travelStamp : AppDesign.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(88, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel)),
        ],
      );
}

class AppLoadingDialog extends StatelessWidget {
  const AppLoadingDialog({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Dialog(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 16),
            Flexible(child: Text(message, style: AppDesign.bodyMedium)),
          ]),
        )),
      );
}

class AppTextInputDialog extends StatefulWidget {
  const AppTextInputDialog(
      {super.key,
      required this.title,
      required this.hint,
      required this.submitLabel,
      this.subtitle,
      this.keyboardType,
      this.icon = Icons.edit_outlined});
  final String title, hint, submitLabel;
  final String? subtitle;
  final TextInputType? keyboardType;
  final IconData icon;
  @override
  State<AppTextInputDialog> createState() => _AppTextInputDialogState();
}

class _AppTextInputDialogState extends State<AppTextInputDialog> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _submitted = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted || !_form.currentState!.validate()) return;
    _submitted = true;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text(widget.title, style: AppDesign.headingMedium),
        content: Form(
            key: _form,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.subtitle != null) ...[
                    Text(widget.subtitle!, style: AppDesign.bodySmall),
                    const SizedBox(height: 16)
                  ],
                  TextFormField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: widget.keyboardType,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                        hintText: widget.hint,
                        prefixIcon: Icon(widget.icon, size: 20)),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? widget.hint
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ])),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
        ],
      );
}
