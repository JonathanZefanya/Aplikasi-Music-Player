import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:music/src/app.dart';
import 'package:music/src/bloc/favorites/favorites_bloc.dart';
import 'package:music/src/bloc/home/home_bloc.dart';
import 'package:music/src/bloc/player/player_bloc.dart';
import 'package:music/src/bloc/playlists/playlists_cubit.dart';
import 'package:music/src/bloc/recents/recents_bloc.dart';
import 'package:music/src/bloc/scan/scan_cubit.dart';
import 'package:music/src/bloc/search/search_bloc.dart';
import 'package:music/src/bloc/song/song_bloc.dart';
import 'package:music/src/bloc/theme/theme_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/data/repositories/player_repository.dart';
import 'package:music/src/data/services/hive_box.dart';

Future<void> main() async {
  // initialize flutter engine
  WidgetsFlutterBinding.ensureInitialized();

  // initialize dependency injection
  init();

  // ask for permission to access media if not granted
  if (!await Permission.mediaLibrary.isGranted) {
    await Permission.mediaLibrary.request();
  }

  // initialize hive
  await Hive.initFlutter();
  await Hive.openBox(HiveBox.boxName);

  // initialize audio service
  await sl<MusicPlayer>().init();

  // run app
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<HomeBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<ThemeBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<SongBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<FavoritesBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<PlayerBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<RecentsBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<SearchBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<ScanCubit>(),
        ),
        BlocProvider(
          create: (context) => sl<PlaylistsCubit>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
