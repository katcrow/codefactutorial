import 'package:codefactory/common/const/data.dart';

class DataUtils {
  // chk : 무조건 static 이어야 한다.
  static pathToUrl(String value) {
    return 'http://$ip$value';
  }
}
