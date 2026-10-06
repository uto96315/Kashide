import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/providers.dart';

class TopPage extends ConsumerWidget {
  const TopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(topProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFF3F6)],
          ),
        ),
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.52,
                child: Image.asset('images/splash_new.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              const Text(
                '気に入った歌詞から、曲に出会う',
                style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93)),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'はじめる',
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
