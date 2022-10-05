import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/top/top_page.dart';
import 'register_user_details_model.dart';

class RegisterUserDetailsPage extends StatelessWidget {
  const RegisterUserDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegisterUserDetailsModel>(
      create: (_) => RegisterUserDetailsModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("アカウント情報"),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Consumer<RegisterUserDetailsModel>(
                builder: (context, model, child) {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  children: [
                    const SizedBox(height: 50),

                    GestureDetector(
                      onTap: ()async{
                        await model.pickImage();
                      },

                      // 画像
                      child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all( color: Colors.grey ),
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.grey.shade200,
                            image: (model.imageFile != null)
                                ? DecorationImage(image: FileImage(model.imageFile!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: (model.imageFile != null)
                              ? null
                              : const Icon(Icons.person)
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text("タップで画像を変更"),
                    const SizedBox(height: 50),

                    // ユーザーネーム入力欄
                    TextField(
                      maxLength: 50,
                      controller: model.userNameController,
                      decoration:
                          const InputDecoration(labelText: "ユーザーネーム(必須)"),
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
                    const SizedBox(height: 100),

                    // 登録ボタン
                    ElevatedButton(
                        onPressed: () async {
                          model.startLoading();

                          try {
                            await model.registerUserData();
                            Navigator.pushNamed(context, "/home");
                          } catch (e) {
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
                        child: const Padding(
                          padding: EdgeInsets.only(
                              top: 10, bottom: 10, left: 50, right: 50),
                          child: Text(
                            "登録する",
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        )),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
