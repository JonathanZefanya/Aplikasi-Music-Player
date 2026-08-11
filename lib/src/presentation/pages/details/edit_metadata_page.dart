import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:music/src/bloc/home/home_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/metadata_repository.dart';

class EditMetadataPage extends StatefulWidget {
  final SongModel song;

  const EditMetadataPage({super.key, required this.song});

  @override
  State<EditMetadataPage> createState() => _EditMetadataPageState();
}

class _EditMetadataPageState extends State<EditMetadataPage> {
  final MetadataRepository _repository = sl<MetadataRepository>();

  final TextEditingController _title = TextEditingController();
  final TextEditingController _artist = TextEditingController();
  final TextEditingController _album = TextEditingController();
  final TextEditingController _albumArtist = TextEditingController();
  final TextEditingController _genre = TextEditingController();
  final TextEditingController _year = TextEditingController();
  final TextEditingController _trackNumber = TextEditingController();
  final TextEditingController _lyrics = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _fetching = false;
  bool _fetchingArtwork = false;

  Uint8List? _artwork;
  bool _artworkChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _albumArtist.dispose();
    _genre.dispose();
    _year.dispose();
    _trackNumber.dispose();
    _lyrics.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final Tag? tag = await _repository.read(widget.song.data);

    if (!mounted) {
      return;
    }

    setState(() {
      _title.text = tag?.title ?? widget.song.title;
      _artist.text = tag?.trackArtist ?? widget.song.artist ?? '';
      _album.text = tag?.album ?? widget.song.album ?? '';
      _albumArtist.text = tag?.albumArtist ?? '';
      _genre.text = tag?.genre ?? widget.song.genre ?? '';
      _year.text = tag?.year?.toString() ?? '';
      _trackNumber.text = tag?.trackNumber?.toString() ?? '';
      _lyrics.text = tag?.lyrics ?? '';
      _artwork = tag?.pictures.isNotEmpty == true
          ? tag!.pictures.first.bytes
          : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.getTheme().secondaryColor,
      appBar: AppBar(
        backgroundColor: Themes.getTheme().primaryColor,
        elevation: 0,
        title: const Text('Edit Metadata'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
          ),
        ],
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildArtwork(),
                  const SizedBox(height: 16),
                  _field(_title, 'Title'),
                  _field(_artist, 'Artist'),
                  _field(_album, 'Album'),
                  _field(_albumArtist, 'Album artist'),
                  _field(_genre, 'Genre'),
                  _field(_year, 'Year', numeric: true),
                  _field(_trackNumber, 'Track number', numeric: true),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lyrics',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _fetching ? null : _fetchLyrics,
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: Text(_fetching ? 'Fetching...' : 'Fetch online'),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _lyrics,
                    maxLines: 12,
                    minLines: 6,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'No lyrics',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _buildArtwork() {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.withOpacity(0.15),
          ),
          clipBehavior: Clip.antiAlias,
          child: _artwork == null
              ? const Icon(Icons.album_outlined, size: 64)
              : Image.memory(_artwork!, fit: BoxFit.cover),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _pickArtwork,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Pick'),
            ),
            TextButton.icon(
              onPressed: _fetchingArtwork ? null : _downloadArtwork,
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(_fetchingArtwork ? 'Downloading...' : 'Download'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickArtwork() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) {
      return;
    }

    final Uint8List bytes = await File(picked.path).readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _artwork = bytes;
      _artworkChanged = true;
    });
  }

  Future<void> _downloadArtwork() async {
    setState(() => _fetchingArtwork = true);

    final Uint8List? bytes = await _repository.downloadArtwork(
      title: _title.text.trim(),
      artist: _artist.text.trim(),
      album: _album.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _fetchingArtwork = false;

      if (bytes != null) {
        _artwork = bytes;
        _artworkChanged = true;
      }
    });

    Fluttertoast.showToast(
      msg: bytes == null ? 'Artwork not found' : 'Artwork downloaded',
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _fetchLyrics() async {
    setState(() => _fetching = true);

    final String? lyrics = await _repository.fetchOnlineLyrics(
      title: _title.text.trim(),
      artist: _artist.text.trim(),
      album: _album.text.trim(),
      durationSeconds: widget.song.duration == null
          ? null
          : (widget.song.duration! / 1000).round(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _fetching = false);

    if (lyrics == null) {
      Fluttertoast.showToast(msg: 'Lyrics not found');
      return;
    }

    _lyrics.text = lyrics;
    Fluttertoast.showToast(msg: 'Lyrics loaded');
  }

  Future<void> _save() async {
    if (!await Permission.manageExternalStorage.isGranted) {
      final PermissionStatus status =
          await Permission.manageExternalStorage.request();

      if (!status.isGranted) {
        Fluttertoast.showToast(msg: 'Storage permission denied');
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() => _saving = true);

    try {
      await _repository.write(
        widget.song.data,
        title: _title.text.trim(),
        trackArtist: _artist.text.trim(),
        album: _album.text.trim(),
        albumArtist: _albumArtist.text.trim(),
        genre: _genre.text.trim(),
        year: int.tryParse(_year.text.trim()),
        trackNumber: int.tryParse(_trackNumber.text.trim()),
        lyrics: _lyrics.text,
      );

      if (_artworkChanged && _artwork != null) {
        await _repository.writeArtwork(widget.song.data, _artwork!);
      }

      Fluttertoast.showToast(
        msg: 'Saved. Refresh the library to see the change',
      );

      if (mounted) {
        context.read<HomeBloc>().add(GetSongsEvent());
        Navigator.of(context).pop();
      }
    } catch (error) {
      Fluttertoast.showToast(msg: 'Failed to save: $error');
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }
}
