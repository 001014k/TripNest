// lib/services/supabase_manager.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../env.dart';

class SupabaseManager {
  static final SupabaseClient client = SupabaseClient(
    Env.supabaseUrl,
    Env.supabaseAnonKey,
  );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      // 기타 설정 추가 가능
    );
  }
}
