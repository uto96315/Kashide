import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/providers.dart';

class RegisterUserDetailsPage extends ConsumerWidget {
  const RegisterUserDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(registerUserDetailsProvider);
    final name = model.userNameController.text.trim();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F8),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              children: [
                const Spacer(),
                _AvatarPicker(image: model.imageFile, onTap: model.pickImage),
                const SizedBox(height: 28),
                TextField(
                  controller: model.userNameController,
                  maxLength: 50,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  onChanged: model.setUserName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                  cursorColor: mainColor,
                  decoration: const InputDecoration(
                    hintText: 'ユーザー名',
                    hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 18, fontWeight: FontWeight.w600),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFFFD6E4)),
                const SizedBox(height: 12),
                TextField(
                  controller: model.userIntroductionController,
                  maxLength: 160,
                  maxLines: 4,
                  minLines: 3,
                  onChanged: model.setUserIntroduction,
                  style: const TextStyle(fontSize: 17, height: 1.45, color: Color(0xFF1C1C1E)),
                  cursorColor: mainColor,
                  decoration: const InputDecoration(
                    hintText: '自己紹介を追加（任意）',
                    hintStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93)),
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.fromLTRB(8, 4, 8, 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Kashideの世界に入る',
                  loading: model.isLoading,
                  onPressed: name.isEmpty
                      ? null
                      : () async {
                          model.startLoading();
                          try {
                            await model.registerUserData();
                            if (!context.mounted) return;
                            Navigator.pushNamed(context, '/home');
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            model.endLoading();
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.onTap, this.image});

  final File? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFFFD0E0), width: 3),
              image: image == null ? null : DecorationImage(image: FileImage(image!), fit: BoxFit.cover),
            ),
            child: image == null ? const Icon(Icons.person, size: 72, color: Color(0xFFFFB3C7)) : null,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Text(
            image == null ? '画像を追加（任意）' : '画像を変更',
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
        ),
      ],
    );
  }
}
