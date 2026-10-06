

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/howToUse/how_to_use_model.dart';
import 'package:str_gram_beta/providers.dart';

class HowToUsePage extends ConsumerWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(howToUseProvider);
    return Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      const ScreenTop(),
                      for(final question in model.questions)
                        Column(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide( color: Colors.grey.shade300 ),
                                )
                              ),
                              child: GestureDetector(
                                onTap: (){
                                  model.setSelected(question["id"]);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only( top: 15, bottom: 15 ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                        const SizedBox( width: 20 ),
                                        Text(question["title"], style: const TextStyle( fontSize: 16 )),
                                      ],
                                      ),
                                      Row(
                                      children: [
                                        Icon( question["id"] == model.selected ? Icons.keyboard_arrow_down : Icons.navigate_next, color: Colors.grey ),
                                        const SizedBox( width: 10 )
                                      ],
                                      ),
                                   ],
                                    ),
                                ),
                              ),
                            ),

                            // 回答表示エリア
                            model.selected == question["id"]
                                ? GestureDetector(
                                  onTap: (){
                                    model.removeSelected();
                                  },
                                  child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide( color: Colors.grey.shade300 )
                                        ),
                                        color: Colors.grey.shade200
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only( top: 20, bottom: 20, right: 20, left: 20 ),
                                        child: Text(
                                          question["answer"],
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.5,
                                          )
                                        ),
                                      )
                                    ),
                                )
                                : const SizedBox(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
  }
}
