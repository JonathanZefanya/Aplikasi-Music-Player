import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music/src/bloc/theme/theme_bloc.dart';
import 'package:music/src/core/theme/themes.dart';

class ThemesPage extends StatefulWidget {
  const ThemesPage({super.key});

  @override
  State<ThemesPage> createState() => _ThemesPageState();
}

class _ThemesPageState extends State<ThemesPage> {
  final ImagePicker _imagePicker = ImagePicker();

  List<String> get _themeNames => Themes.themeNames;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Themes.getTheme().secondaryColor,
          appBar: AppBar(
            backgroundColor: Themes.getTheme().primaryColor,
            elevation: 0,
            title: const Text('Themes'),
          ),
          body: Ink(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
            decoration: Themes.getBackgroundDecoration(),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _themeNames.length,
              itemBuilder: (context, index) {
                final String themeName = _themeNames[index];
                return _buildThemeButton(themeName);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeButton(String themeName) {
    final ThemeColor previewTheme = Themes.getThemeFromKey(themeName);
    final bool isSelected = Themes.getThemeName() == themeName;
    final bool isCustomImage = themeName == Themes.customImageThemeName;
    final bool hasImage = isCustomImage &&
        previewTheme.backgroundImagePath != null &&
        previewTheme.backgroundImagePath!.isNotEmpty &&
        File(previewTheme.backgroundImagePath!).existsSync();

    return Stack(
      children: [
        Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: hasImage ? null : previewTheme.linearGradient,
            image: hasImage
                ? DecorationImage(
                    image: FileImage(File(previewTheme.backgroundImagePath!)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      previewTheme.overlayColor.withOpacity(0.5),
                      BlendMode.darken,
                    ),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: previewTheme.primaryColor.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: -5,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _onThemeTap(themeName),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCustomImage)
                    Icon(
                      hasImage
                          ? Icons.image
                          : Icons.add_photo_alternate_outlined,
                      color: previewTheme.adaptiveTextColor,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    themeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: previewTheme.adaptiveTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isSelected)
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: previewTheme.adaptiveTextColor == Colors.white
                    ? Colors.deepPurple
                    : Colors.black,
              ),
              child: Icon(
                Icons.check,
                color: previewTheme.adaptiveTextColor == Colors.white
                    ? Colors.white
                    : Colors.amber,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onThemeTap(String themeName) async {
    if (themeName == Themes.customColorThemeName) {
      await _selectCustomColorTheme();
      return;
    }

    if (themeName == Themes.customImageThemeName) {
      await _selectCustomImageTheme();
      return;
    }

    if (!mounted) {
      return;
    }

    context.read<ThemeBloc>().add(ChangeTheme(themeName));
  }

  Future<void> _selectCustomColorTheme() async {
    final Color? selectedColor = await _showColorPickerDialog(
      title: 'Pilih Warna Tema',
      initialColor: Themes.getTheme().primaryColor,
    );

    if (selectedColor == null) {
      return;
    }

    await Themes.setCustomColorTheme(selectedColor);
    if (!mounted) {
      return;
    }

    context.read<ThemeBloc>().add(ChangeTheme(Themes.customColorThemeName));
  }

  Future<void> _selectCustomImageTheme() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (pickedFile == null) {
      return;
    }

    final ThemeColor currentTheme =
        Themes.getThemeFromKey(Themes.customImageThemeName);
    final Color? overlayColor = await _showColorPickerDialog(
      title: 'Pilih Warna Overlay',
      initialColor: currentTheme.primaryColor,
    );

    await Themes.setCustomImageTheme(
      imagePath: pickedFile.path,
      overlayColor: overlayColor ?? const Color(0xff111111),
    );

    if (!mounted) {
      return;
    }

    context.read<ThemeBloc>().add(ChangeTheme(Themes.customImageThemeName));
  }

  Future<Color?> _showColorPickerDialog({
    required String title,
    required Color initialColor,
  }) async {
    int red = initialColor.red;
    int green = initialColor.green;
    int blue = initialColor.blue;

    return showDialog<Color>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final Color pickedColor = Color.fromARGB(255, red, green, blue);
            final Color textColor = Themes.getAdaptiveTextColor(pickedColor);

            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        color: pickedColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${pickedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildColorSlider(
                      label: 'R',
                      value: red.toDouble(),
                      activeColor: Colors.red,
                      onChanged: (value) {
                        setDialogState(() => red = value.toInt());
                      },
                    ),
                    _buildColorSlider(
                      label: 'G',
                      value: green.toDouble(),
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setDialogState(() => green = value.toInt());
                      },
                    ),
                    _buildColorSlider(
                      label: 'B',
                      value: blue.toDouble(),
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setDialogState(() => blue = value.toInt());
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(pickedColor),
                  child: const Text('Pakai'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorSlider({
    required String label,
    required double value,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(label),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(value.toInt().toString()),
        ),
      ],
    );
  }
}
