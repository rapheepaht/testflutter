import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:testflutter/domain/entities/note_entity.dart';
import 'package:testflutter/presentation/pages/create_note_page.dart';
import 'package:testflutter/presentation/pages/home_page.dart';
import 'package:testflutter/presentation/pages/note_detail_page.dart';
import 'package:testflutter/presentation/pages/login_page.dart';
import 'package:testflutter/presentation/pages/profile_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: LoginRoute.page, initial: true),
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: ProfileRoute.page),
        AutoRoute(page: CreateNoteRoute.page),
        AutoRoute(page: NoteDetailRoute.page),
      ];
}
