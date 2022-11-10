import 'package:codefactory/common/const/data.dart';
import 'package:codefactory/common/dio/dio.dart';
import 'package:codefactory/common/model/cursor_pagination_model.dart';
import 'package:codefactory/restaurant/component/restaurant_card.dart';
import 'package:codefactory/restaurant/model/restaurant_model.dart';
import 'package:codefactory/restaurant/repository/restaurant_repository.dart';
import 'package:codefactory/restaurant/view/restaurant_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestaurantScreen extends ConsumerWidget {
  const RestaurantScreen({Key? key}) : super(key: key);

  // Future<List<RestaurantModel>> paginateRestaurant(WidgetRef ref) async {
  //   // final dio = Dio();
  //   //
  //   // dio.interceptors.add(
  //   //   CustomInterceptor(storage: storage),
  //   // );
  //   final dio = ref.watch(dioProvider);
  //
  //   final resp = await RestaurantRepository(
  //     dio,
  //     baseUrl: 'http://$ip/restaurant',
  //   ).paginate();
  //
  //   return resp.data;
  // }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FutureBuilder<CursorPagination<RestaurantModel>>(
            future: ref.watch(restaurantRepositoryProvider).paginate(),
            builder: (_, AsyncSnapshot<CursorPagination<RestaurantModel>> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return ListView.separated(
                itemCount: snapshot.data!.data.length,
                separatorBuilder: (_, index) {
                  return SizedBox(height: 16);
                },
                itemBuilder: (_, index) {
                  final RestaurantModel pItem = snapshot.data!.data[index];

                  // chk : 나도 항상 Map 에 자신이 없다
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailScreen(
                            id: pItem.id,
                          ),
                        ),
                      );
                    },
                    child: RestaurantCard.fromModel(
                      model: pItem,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
