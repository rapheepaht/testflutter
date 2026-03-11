// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    CreateNoteRoute.name: (routeData) {
      final args = routeData.argsAs<CreateNoteRouteArgs>(
          orElse: () => const CreateNoteRouteArgs());
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: CreateNotePage(
          key: args.key,
          note: args.note,
        ),
      );
    },
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: HomePage(
          key: args.key,
          email: args.email,
        ),
      );
    },
    ProfileRoute.name: (routeData) {
      final args = routeData.argsAs<ProfileRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ProfilePage(
          key: args.key,
          email: args.email,
        ),
      );
    },
    LoginRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LoginPage(),
      );
    },
    NoteDetailRoute.name: (routeData) {
      final args = routeData.argsAs<NoteDetailRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: NoteDetailPage(
          key: args.key,
          note: args.note,
        ),
      );
    },
  };
}

/// generated route for
/// [CreateNotePage]
class CreateNoteRoute extends PageRouteInfo<CreateNoteRouteArgs> {
  CreateNoteRoute({
    Key? key,
    NoteEntity? note,
    List<PageRouteInfo>? children,
  }) : super(
          CreateNoteRoute.name,
          args: CreateNoteRouteArgs(
            key: key,
            note: note,
          ),
          initialChildren: children,
        );

  static const String name = 'CreateNoteRoute';

  static const PageInfo<CreateNoteRouteArgs> page =
      PageInfo<CreateNoteRouteArgs>(name);
}

class CreateNoteRouteArgs {
  const CreateNoteRouteArgs({
    this.key,
    this.note,
  });

  final Key? key;

  final NoteEntity? note;

  @override
  String toString() {
    return 'CreateNoteRouteArgs{key: $key, note: $note}';
  }
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    Key? key,
    String email = 'user@example.com',
    List<PageRouteInfo>? children,
  }) : super(
          HomeRoute.name,
          args: HomeRouteArgs(
            key: key,
            email: email,
          ),
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const PageInfo<HomeRouteArgs> page = PageInfo<HomeRouteArgs>(name);
}

class HomeRouteArgs {
  const HomeRouteArgs({
    this.key,
    this.email = 'user@example.com',
  });

  final Key? key;

  final String email;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, email: $email}';
  }
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<ProfileRouteArgs> {
  ProfileRoute({
    Key? key,
    required String email,
    List<PageRouteInfo>? children,
  }) : super(
          ProfileRoute.name,
          args: ProfileRouteArgs(
            key: key,
            email: email,
          ),
          initialChildren: children,
        );

  static const String name = 'ProfileRoute';

  static const PageInfo<ProfileRouteArgs> page =
      PageInfo<ProfileRouteArgs>(name);
}

class ProfileRouteArgs {
  const ProfileRouteArgs({
    this.key,
    required this.email,
  });

  final Key? key;

  final String email;

  @override
  String toString() {
    return 'ProfileRouteArgs{key: $key, email: $email}';
  }
}

/// generated route for
/// [NoteDetailPage]
class NoteDetailRoute extends PageRouteInfo<NoteDetailRouteArgs> {
  NoteDetailRoute({
    Key? key,
    required NoteEntity note,
    List<PageRouteInfo>? children,
  }) : super(
          NoteDetailRoute.name,
          args: NoteDetailRouteArgs(
            key: key,
            note: note,
          ),
          initialChildren: children,
        );

  static const String name = 'NoteDetailRoute';

  static const PageInfo<NoteDetailRouteArgs> page =
      PageInfo<NoteDetailRouteArgs>(name);
}

class NoteDetailRouteArgs {
  const NoteDetailRouteArgs({
    this.key,
    required this.note,
  });

  final Key? key;

  final NoteEntity note;

  @override
  String toString() {
    return 'NoteDetailRouteArgs{key: $key, note: $note}';
  }
}
