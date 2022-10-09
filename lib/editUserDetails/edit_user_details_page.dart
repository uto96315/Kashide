import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'edit_user_details_model.dart';

class EditUserDetailsPage extends StatelessWidget {
   EditUserDetailsPage(this.userName, this.userAge,this.userIntroduction, this.userGender,this.userFavorite, this.userImageUrl, {super.key});
   String userName;
   String userAge;
   String userIntroduction;
   String userGender;
   List<dynamic> userFavorite;
   String userImageUrl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditUserDetailsModel>(
      create: (_) => EditUserDetailsModel(userName, userIntroduction, userGender, userAge, userFavorite, userImageUrl),
      child: GestureDetector(
        onTap: (){FocusScope.of(context).unfocus();},
        child: Scaffold(
          appBar: AppBar(
            title: const Text("アカウント編集"),
            backgroundColor: mainColor,
          ),
          body: Center(
            child:
            Consumer<EditUserDetailsModel>(builder: (context, model, child) {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      GestureDetector(
                        onTap: ()async{
                          await model.pickImage();
                        },

                        // アイコン画像
                        child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all( color: Colors.grey ),
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.grey.shade200,
                              image: (model.imageFile == null)
                                  ? DecorationImage(image: NetworkImage(model.userImageUrl!), fit: BoxFit.cover)
                                  : DecorationImage(image: FileImage(model.imageFile!), fit: BoxFit.cover),
                            ),
                            child: (model.imageFile != null)
                                ? null
                                : const Icon(Icons.person)
                        ),
                      ),


                      // ユーザーネーム入力欄
                      TextField(
                        maxLength: 50,
                        controller: model.userNameController,
                        decoration: const InputDecoration(labelText: "ユーザーネーム(必須)"),
                        onChanged: (text) {
                          model.setUserName(text);
                        },
                      ),
                      const SizedBox(height: 15),

                      // 自己紹介入力欄
                      TextField(
                        controller: model.userIntroductionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: "自己紹介(任意)"),
                        onChanged: (text) {
                          model.setUserName(text);
                        },
                      ),
                      const SizedBox(height: 15),

                      // 年代選択欄
                      Row(
                        children: const [
                          Text("年代",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black54)),
                          SizedBox(width: 10),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                        child: DropdownButton(
                            isExpanded: true,
                            value: model.userAge,
                            hint: const Text("選択してください(任意)",
                                style: TextStyle(fontSize: 15)),
                            items: [
                              for (int i = 1; i < 10; i++) ...{
                                DropdownMenuItem(
                                  value: "${i}0代",
                                  child: Text("${i}0代"),
                                )
                              },
                              const DropdownMenuItem(
                                  value: "99以上", child: Text("それ以上"))
                            ],
                            onChanged: (select) {
                              model.setUserAge(select ?? "error");
                            }),
                      ),
                      const SizedBox(height: 15),

                      // 性別入力欄
                      Row(
                        children: const [
                          Text("性別",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black54)),
                          SizedBox(width: 10),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                        child: DropdownButton(
                            isExpanded: true,
                            value: model.userGender,
                            hint: const Text("選択してください(任意)",
                                style: TextStyle(fontSize: 15)),
                            items: model.genderList
                                .map((String gender) => DropdownMenuItem(
                                value: gender, child: Text(gender ?? "")))
                                .toList(),
                            onChanged: (select) {
                              model.setUserGender(select ?? "error");
                            }),
                      ),
                      const SizedBox(height: 30),


                      // 興味選択欄　
                      Row(
                        children: const [
                          Text("興味があるジャンル(複数選択可能)",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black54)),
                          SizedBox(width: 10),
                        ],
                      ),
                      const SizedBox( height: 15 ),

                      // リストから生成
                      Wrap(
                        runSpacing: 15,
                        spacing: 10,
                        children: model.favoriteList.map((tag) {
                          final isSelected = model.userFavorite.contains(tag);
                          return InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(32)),
                            onTap: (){
                              if(isSelected) {
                                model.removeFavorite(tag);
                                debugPrint("remove $tag");
                              } else {
                                model.setFavorite(tag);
                                debugPrint("set $tag");
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radius.circular(32)),
                                border: Border.all(
                                  width: 2,
                                  color: (isSelected) ? mainColor : Colors.grey,
                                ),
                                color: isSelected ? mainColor : null,
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList()
                      ),
                      const SizedBox( height: 50 ),


                      // 登録ボタン
                      ElevatedButton(
                          onPressed: () async {

                            model.startLoading();

                            try {
                              await model.updateUserData();
                              Navigator.pushNamed(context, "/home");
                            } catch (e) {
                              final snackBar = SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(e.toString()),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            } finally {
                              model.endLoading();
                            }
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                        ),
                          child: const Padding(
                            padding: EdgeInsets.only(
                                top: 10, bottom: 10, left: 50, right: 50),
                            child: Text("登録する", style: TextStyle( fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ),
                      const SizedBox( height: 100 ),

                      // アカウント削除ボタン
                      SizedBox(
                        width: 200,
                        height: 40,
                        child: ElevatedButton(
                            onPressed: () async{
                              model.startLoading();

                              try {
                                await model.deleteUser();
                                Navigator.popUntil(context, (route) => route.isFirst);
                              } catch(e) {
                                print(e.toString());
                                final snackBar = SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(e.toString()),
                                );
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              } finally {
                                model.endLoading();
                              }
                            },
                          style: ElevatedButton.styleFrom( primary: Colors.red ),

                          child: const Text("アカウントを削除する"),
                        ),
                      ),
                      const SizedBox( height: 100 ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
