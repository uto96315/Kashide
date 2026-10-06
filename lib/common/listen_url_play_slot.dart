import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/providers.dart';

/// 保存 URL が空のとき Apple Music を検索し、見つかったら [builder] に URL を渡す。
class ListenUrlPlaySlot extends ConsumerStatefulWidget {
  const ListenUrlPlaySlot({
    super.key,
    required this.storedUrl,
    required this.artist,
    required this.singName,
    required this.builder,
  });

  final String storedUrl;
  final String artist;
  final String singName;
  final Widget Function(BuildContext context, String? listenUrl) builder;

  @override
  ConsumerState<ListenUrlPlaySlot> createState() => _ListenUrlPlaySlotState();
}

class _ListenUrlPlaySlotState extends ConsumerState<ListenUrlPlaySlot> {
  String? _listenUrl;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(ListenUrlPlaySlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storedUrl != widget.storedUrl ||
        oldWidget.artist != widget.artist ||
        oldWidget.singName != widget.singName) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final url = await ref.read(listenUrlResolverProvider).resolve(
          storedUrl: widget.storedUrl,
          artist: widget.artist,
          singName: widget.singName,
        );
    if (mounted) setState(() => _listenUrl = url);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _listenUrl);
}
