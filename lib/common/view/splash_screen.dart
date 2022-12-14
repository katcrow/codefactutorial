import 'package:codefactory/common/const/colors.dart';
import 'package:codefactory/common/dio/dio.dart';
import 'package:codefactory/common/layout/default_layout.dart';
import 'package:codefactory/common/secure_storage/secure_storage.dart';
import 'package:codefactory/common/view/root_tab.dart';
import 'package:codefactory/user/view/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../const/data.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  void deleteToken() async {
    final storage = ref.read(secureStorageProvider);
    await storage.deleteAll();
  }

  // -- info : important
  void checkToken() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken = await storage.read(key: REFRESH_TOKEN_KEY);
    final accessToken = await storage.read(key: ACCESS_TOKEN_KEY);

    // todo
    // final dio = Dio();
    final dio = ref.watch(dioProvider);
    try {
      final resp = await dio.post(
        "http://${ip}/auth/token",
        options: Options(
          headers: {'authorization': 'Bearer $refreshToken'},
        ),
      );
      //-- refresh 후 access token insert
      await storage.write(key: ACCESS_TOKEN_KEY, value: resp.data['accessToken']);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RootTab()),
        (route) => false,
      );
    } catch (e) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // deleteToken();
    checkToken();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      backgroundColor: PRIMARY_COLOR,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "asset/img/logo/logo.png",
              width: MediaQuery.of(context).size.width / 2,
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
