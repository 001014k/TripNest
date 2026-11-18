import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용자가 바뀌면 계정에 속한 프로바이더와 화면 탐색 상태를 다시 만듭니다.
/// 같은 사용자의 액세스 토큰 갱신 시 현재 화면을 유지합니다.
class AccountScope extends StatefulWidget {
  const AccountScope(
      {super.key, required this.builder, this.identities, this.initialUserId});
  final WidgetBuilder builder;
  final Stream<String?>? identities;
  final String? initialUserId;
  @override
  State<AccountScope> createState() => _AccountScopeState();
}

class _AccountScopeState extends State<AccountScope> {
  late String? _userId;
  StreamSubscription<String?>? _subscription;
  @override
  void initState() {
    super.initState();
    _userId = widget.identities == null
        ? Supabase.instance.client.auth.currentUser?.id
        : widget.initialUserId;
    _subscription = (widget.identities ??
            Supabase.instance.client.auth.onAuthStateChange
                .map((event) => event.session?.user.id))
        .listen((id) {
      if (!mounted || id == _userId) return;
      setState(() => _userId = id);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
      key: ValueKey(_userId), child: Builder(builder: widget.builder));
}
