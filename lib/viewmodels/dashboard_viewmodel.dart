import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardViewModel extends ChangeNotifier {
  int totalUsers = 0;
  int totalMarkers = 0;
  Map<String, int> userMarkersCount = {};

  Future<void> fetchDashboardData() async {
    final supabase = Supabase.instance.client;

    try {
      final users = await supabase.from('users').select('id, email') as List<
          dynamic>;

      totalUsers = users.length;
      totalMarkers = 0;
      userMarkersCount.clear();

      for (var user in users) {
        final userId = user['id'] as String;
        final email = user['email'] as String;

        final markers = await supabase
            .from('user_markers')
            .select('id')
            .eq('user_id', userId) as List<dynamic>;

        final count = markers.length;
        totalMarkers += count;
        userMarkersCount[email] = count;
      }

      notifyListeners();
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }
}