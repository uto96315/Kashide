import 'package:flutter/cupertino.dart';



class SearchResultModel extends ChangeNotifier {
  SearchResultModel(this.searchWord);

  String? searchWord;
}