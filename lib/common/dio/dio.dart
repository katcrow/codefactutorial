import 'package:codefactory/common/const/data.dart';
import 'package:codefactory/common/secure_storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  final storage = ref.watch(secureStorageProvider);

  dio.interceptors.add(
    CustomInterceptor(storage: storage),
  );

  return dio;
});

class CustomInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  CustomInterceptor({
    required this.storage,
  });

  /**
   * 1) 요청을 보낼때
   * 요청이 보내질때마다
   * 만약에 요청의 Header 에 accessToken: true 라는 값이 있다면
   * 실제 토큰을 가져와서 (storage 에서) authorization : Bearer $token 으로
   * 헤더를 변경한다.
   */
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('[REQ] [${options.method}] ${options.uri}');

    // info : accessToken
    if (options.headers['accessToken'] == 'true') {
      // 헤더 삭제
      options.headers.remove('accessToken');

      // 로컬 저장소의 헤더 값 조회
      final token = await storage.read(key: ACCESS_TOKEN_KEY);

      // 실제 토큰으로 대체
      options.headers.addAll({
        'authorization': 'Bearer $token',
      });
    }
    // info : refreshToken
    if (options.headers['refreshToken'] == 'true') {
      // 헤더 삭제
      options.headers.remove('refreshToken');

      // 로컬 저장소의 헤더 값 조회
      final token = await storage.read(key: REFRESH_TOKEN_KEY);

      // 실제 토큰으로 대체
      options.headers.addAll({
        'authorization': 'Bearer $token',
      });
    }
    return super.onRequest(options, handler);
  }

  /**
   * 2) 응답을 받을때
   */
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('[RES] [${response.requestOptions.method}] ${response.requestOptions.uri}');

    return super.onResponse(response, handler);
  }

  /**
   * 3) 에러가 났을때
   */
  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    /**
     * 401에러가 났을때 (status code)
     * 토큰을 재발급 받는 시도를 하고 토큰이 재발급되면
     * 다시 새로운 토큰으로 요청을 한다.
     */
    print('[ERR] [${err.requestOptions.method}] ${err.requestOptions.uri}');

    final refreshToken = await storage.read(key: REFRESH_TOKEN_KEY);
    // refreshToken 이 아예 없으면 에러를 던진다.
    if (refreshToken == null) {
      // 에러를 던질때는 handler.reject 를 사용한다.
      return handler.reject(err);
    }

    final isStatus401 = err.response?.statusCode == 401;
    final isPathRefresh = err.requestOptions.path == '/auth/token';
    if (isStatus401 && !isPathRefresh) {
      final dio = Dio();
      try {
        final resp = await dio.post(
          'http://$ip/auth/token',
          options: Options(headers: {
            'authorization': 'Bearer $refreshToken',
          }),
        );
        final accessToken = resp.data['accessToken'];
        final options = err.requestOptions;
        // info : 토큰 변경하기
        options.headers.addAll({
          'authorization': 'Bearer $accessToken',
        });
        await storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);

        // info : 요청 재전송
        final response = await dio.fetch(options);
        return handler.resolve(response); // 실제 에러가 없었던거 같이 실행된다.
      } on DioError catch (e) {
        return handler.reject(e);
      }
    }
    return handler.reject(err);
  }
}
