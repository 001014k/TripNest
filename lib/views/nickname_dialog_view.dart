import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/nickname_dialog_viewmodel.dart';

class NicknameDialogView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NicknameDialogViewModel>();

    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      title: const Text(
        '닉네임 설정',
        style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            onChanged: (val) => vm.nickname = val,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '닉네임 입력',
              hintStyle: TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              errorText: vm.error,
              suffixIcon: vm.isChecking
                  ? Padding(
                padding: const EdgeInsets.all(12.0),
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
                        color: vm.isNicknameAvailable ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: vm.isSaving
              ? null
              : () async {
            final success = await vm.saveNickname();
            if (success) Navigator.of(context).pop();
          },
          child: vm.isSaving
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 3),
          )
              : const Text(
            '저장',
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
