import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

import 'package:music/src/bloc/home/home_bloc.dart';
import 'package:music/src/bloc/theme/theme_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/backup_repository.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupRepository _repository = sl<BackupRepository>();

  bool _settings = true;
  bool _favorites = true;
  bool _playlists = true;
  bool _busy = false;

  late Future<List<BackupFile>> _backups = _repository.listBackups();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.getTheme().secondaryColor,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: const Text('Backup & Restore'),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: ListView(
          padding: context.contentPadding,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'What to include',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            CheckboxListTile(
              value: _settings,
              title: const Text('Settings'),
              subtitle: const Text('Theme, filters, playback preferences'),
              onChanged: (value) => setState(() => _settings = value ?? false),
            ),
            CheckboxListTile(
              value: _favorites,
              title: const Text('Favorites'),
              onChanged: (value) => setState(() => _favorites = value ?? false),
            ),
            CheckboxListTile(
              value: _playlists,
              title: const Text('Playlists'),
              onChanged: (value) => setState(() => _playlists = value ?? false),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _busy ? null : _createBackup,
                icon: const Icon(Icons.backup_outlined),
                label: Text(_busy ? 'Working...' : 'Create backup'),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Available backups',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            FutureBuilder<List<BackupFile>>(
              future: _backups,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final List<BackupFile> backups = snapshot.data!;

                if (backups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No backup yet'),
                  );
                }

                return Column(
                  children: [
                    for (final BackupFile backup in backups)
                      ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(
                          backup.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_formatSize(backup.sizeBytes)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => Share.shareXFiles(
                                [XFile(backup.file.path)],
                              ),
                              icon: const Icon(Icons.share_outlined),
                              tooltip: 'Share',
                            ),
                            IconButton(
                              onPressed: () => _confirmDelete(backup),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        onTap: () => _confirmRestore(backup),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  Future<void> _createBackup() async {
    setState(() => _busy = true);

    try {
      final File file = await _repository.createBackup(
        settings: _settings,
        favorites: _favorites,
        playlists: _playlists,
      );

      Fluttertoast.showToast(msg: 'Saved ${file.uri.pathSegments.last}');
    } catch (error) {
      Fluttertoast.showToast(msg: 'Backup failed: $error');
    }

    if (mounted) {
      setState(() {
        _busy = false;
        _backups = _repository.listBackups();
      });
    }
  }

  Future<void> _confirmRestore(BackupFile backup) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'Settings and favorites will be overwritten. Playlists that already '
          'exist are skipped. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);

    try {
      if (!await backup.file.exists()) {
        Fluttertoast.showToast(msg: 'Backup file is gone');

        if (mounted) {
          setState(() {
            _busy = false;
            _backups = _repository.listBackups();
          });
        }

        return;
      }

      final BackupResult result = await _repository.restore(backup.file);

      if (mounted) {
        context.read<ThemeBloc>().add(ChangeTheme(Themes.getThemeName()));
        context.read<HomeBloc>().add(GetSongsEvent());
      }

      Fluttertoast.showToast(
        msg: 'Restored ${result.favorites} favorites, '
            '${result.playlists} playlists',
      );
    } catch (error) {
      Fluttertoast.showToast(msg: 'Restore failed: $error');
    }

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(BackupFile backup) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Delete ${backup.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    if (await backup.file.exists()) {
      await backup.file.delete();
    }

    if (mounted) {
      setState(() {
        _backups = _repository.listBackups();
      });
    }
  }
}
