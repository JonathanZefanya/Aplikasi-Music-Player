import 'package:flutter/material.dart';

import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/router/app_router.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/presentation/pages/home/views/albums_view.dart';
import 'package:music/src/presentation/pages/home/views/artists_view.dart';
import 'package:music/src/presentation/pages/home/views/genres_view.dart';
import 'package:music/src/presentation/pages/home/views/songs_view.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabs = ['Songs', 'Albums', 'Artists', 'Genres'];

  late final TabController _tabController = TabController(
    length: _tabs.length,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: Text(
          'Library',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.searchRoute);
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              // 12 + 12 lines the first tab label up with the 24px title inset.
              padding: const EdgeInsets.only(left: AppSpacing.md),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              tabs: [
                for (final String tab in _tabs) Tab(text: tab),
              ],
            ),
          ),
        ),
      ),
      body: ContentWidth(
        child: TabBarView(
          controller: _tabController,
          children: const [
            SongsView(),
            AlbumsView(),
            ArtistsView(),
            GenresView(),
          ],
        ),
      ),
    );
  }
}
