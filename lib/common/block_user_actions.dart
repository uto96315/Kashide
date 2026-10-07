import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/providers.dart';

Future<void> blockUserFromFeed(BuildContext context, WidgetRef ref, String posterId) async {
  await ref.read(blockListProvider).blockUser(posterId);
  ref.read(timelineProvider).removePostsByPoster(posterId);
}
