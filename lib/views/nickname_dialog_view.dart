import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/nickname_dialog_viewmodel.dart';

class NicknameSetupPage extends StatelessWidget {
  const NicknameSetupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NicknameDialogViewModel>();

    return WillPopScope(
      onWillPop: () async => false, // ✅ 물리 뒤로가기 버튼 차단
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // ✅ AppBar 뒤로가기 버튼 제거
          title: const Text(
            '닉네임 설정',
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF121212),
          iconTheme: const IconThemeData(color: Colors.cyanAccent),
          elevation: 0,
        ),
        backgroundColor: const Color(0xFF121212),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                autofocus: true,
                onChanged: (val) => vm.nickname = val,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '닉네임 입력',
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  errorText: vm.error,
                  suffixIcon: vm.isChecking
                      ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : IconButton(
                    icon: const Icon(Icons.check, color: Colors.cyanAccent),
                    onPressed: vm.nickname.trim().isEmpty || vm.isSaving
                        ? null
                        : () => vm.checkNicknameAvailability(),
                  ),
                ),
              ),
              if (vm.nicknameStatusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        vm.isNicknameAvailable ? Icons.check_circle : Icons.error,
                        color: vm.isNicknameAvailable ? Colors.greenAccent : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vm.nicknameStatusMessage!,
                          style: TextStyle(
                            color: vm.isNicknameAvailable
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: vm.nickname.trim().isEmpty ||
                      vm.isSaving ||
                      !vm.isNicknameAvailable
                      ? null
                      : () async {
                    final success = await vm.saveNickname();
                    if (success) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                            (route) => false,
                      );
                    }
                  },
                  child: vm.isSaving
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
