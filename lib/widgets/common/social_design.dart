import 'package:flutter/material.dart';

const socialMuted = Color(0xFF81838C);
const socialLine = Color(0xFFEEEEF1);
const socialFill = Color(0xFFF5F5F7);

PreferredSizeWidget socialAppBar(String title, {List<Widget>? actions}) =>
    AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      leading: Builder(
          builder: (context) => IconButton(
              tooltip: '뒤로가기',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              })),
      actions: actions,
    );

class SocialAvatar extends StatelessWidget {
  const SocialAvatar(
      {super.key,
      required this.name,
      this.url,
      this.size = 48,
      this.online = false});
  final String name;
  final String? url;
  final double size;
  final bool online;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
        color: const Color(0xFFE9E9ED),
        child: Center(
            child: Text(name.isEmpty ? '?' : name.characters.first,
                style: TextStyle(
                    fontSize: size * .32,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF686A73)))));
    return SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
              child: ClipOval(
                  child: url != null && url!.startsWith('https://')
                      ? Image.network(url!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => fallback)
                      : fallback)),
          if (online)
            Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                    width: size * .22,
                    height: size * .22,
                    decoration: BoxDecoration(
                        color: const Color(0xFF89D665),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)))),
        ]));
  }
}

class SocialTabs extends StatelessWidget {
  const SocialTabs(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onChanged});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: socialFill, borderRadius: BorderRadius.circular(28)),
        child: Row(
            children: List.generate(
                labels.length,
                (i) => Expanded(
                    child: Semantics(
                        selected: selected == i,
                        child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () => onChanged(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 11, horizontal: 4),
                              decoration: BoxDecoration(
                                  color: selected == i
                                      ? const Color(0xFF202020)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(28)),
                              child: Text(labels[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected == i
                                          ? Colors.white
                                          : Colors.black)),
                            )))))),
      );
}

class SocialSearch extends StatelessWidget {
  const SocialSearch(
      {super.key,
      required this.hint,
      required this.onChanged,
      this.onSubmitted,
      this.controller});
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  @override
  Widget build(BuildContext context) => TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: socialMuted),
        prefixIcon: const Icon(Icons.search, size: 21),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFE3E4E9))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFE3E4E9))),
      ));
}

class SocialNotice extends StatelessWidget {
  const SocialNotice(
      {super.key,
      required this.title,
      required this.subtitle,
      this.icon = Icons.people_outline,
      this.onTap});
  final String title, subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: socialFill,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFE8E8EC),
                  child: Icon(icon, color: Colors.black, size: 25)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, height: 1.6, color: socialMuted)),
                  ])),
              if (onTap != null) const Icon(Icons.chevron_right, size: 21),
            ])),
      ));
}
