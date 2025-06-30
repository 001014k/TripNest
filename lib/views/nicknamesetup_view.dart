import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../viewmodels/nicknamesetup_viewmodel.dart';

class NicknameSetupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = supa.Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return Scaffold(
        body: Center(child: Text('사용자 정보가 없습니다. 다시 로그인 해주세요.')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => NicknameSetupViewModel(userId: userId),
      child: Scaffold(
        appBar: AppBar(
          title: Text('닉네임 설정'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<NicknameSetupViewModel>(
            builder: (context, vm, child) {
              return Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: '닉네임',
                      errorText: vm.errorMessage,
                      suffixIcon: vm.isChecking
                          ? CircularProgressIndicator()
                          : IconButton(
                        icon: Icon(Icons.check),
                        onPressed: vm.nickname.trim().isEmpty
                            ? null
                            : () => vm.checkNicknameAvailability(),
                      ),
                    ),
                    onChanged: (val) => vm.nickname = val,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: vm.isSaving
                        ? null
                        : () async {
                      final success = await vm.saveNickname();
                      if (success) {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    },
                    child: vm.isSaving
                        ? CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : Text('닉네임 저장'),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
