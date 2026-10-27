import 'package:supabase_flutter/supabase_flutter.dart';

class SecuritySettingsViewModel {
  SecuritySettingsViewModel() {
    final user = Supabase.instance.client.auth.currentUser;
    email = user?.email;
    final connected = <String>{};
    for (final identity in user?.identities ?? const []) {
      final provider = identity.provider.toLowerCase();
      if (provider.isNotEmpty) connected.add(provider);
    }
    _addProvider(connected, user?.appMetadata['provider']);
    _addProvider(connected, user?.appMetadata['providers']);
    providers = connected;
  }

  late final String? email;
  late final Set<String> providers;
  int get connectedCount =>
      providers.intersection({'email', 'google', 'kakao'}).length;

  void _addProvider(Set<String> providers, Object? value) {
    if (value is String && value.isNotEmpty) {
      providers.add(value.toLowerCase());
    } else if (value is List) {
      for (final item in value) {
        _addProvider(providers, item);
      }
    }
  }
}
