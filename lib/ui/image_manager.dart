import 'package:flutter/material.dart';

class ImageManager {
  static final ImageManager _singleton = ImageManager._create();
  ImageManager._create();
  factory ImageManager() {
    return _singleton;
  }

  static const String _imagesDir = 'images';
  static Image _unknownImage = Image.asset('$_imagesDir/unknown.png');
  static const Map<String, bool> _jpgImages =
      {}; // maps image name to whether theme-specific or not
  static const Map<String, bool> _pngImages = {
    // maps image name to whether theme-specific or not
    'app_background': true,
    'panel_background': true,
    'drawer_background': true,
    'dragon': true,
    'celestial_icon': false,
    'hypogean_icon': false,
    'app_circle': false,
    'github_icon': true,
    'gifts/diamonds': false,
    'gifts/elite_soulstones': false,
    'gifts/rare_soulstones': false,
    'gifts/common_scrolls': false,
    'gifts/faction_scrolls': false,
    'gifts/gold': false,
    'gifts/hero_essence': false,
    'gifts/chest_of_wishes': false,
    'gifts/hero_coins': false,
    'gifts/gladiator_coins': false,
    'gifts/guild_coins': false,
    'gifts/labyrinth_tokens': false,
    'gifts/stargazing_cards': false,
    'gifts/hours/essence_2': false,
    'gifts/hours/essence_6': false,
    'gifts/hours/essence_8': false,
    'gifts/hours/essence_24': false,
    'gifts/hours/experience_2': false,
    'gifts/hours/experience_6': false,
    'gifts/hours/experience_8': false,
    'gifts/hours/experience_24': false,
    'gifts/hours/gold_2': false,
    'gifts/hours/gold_6': false,
    'gifts/hours/gold_8': false,
    'gifts/hours/gold_24': false,
  };

  String _theme = 'hypogean';
  Map<String, Image> _images = {};

  bool contains(String name) {
    return _jpgImages.containsKey(name) || _pngImages.containsKey(name);
  }

  Image get(String name) {
    if (_images.containsKey(name)) {
      return _images[name]!;
    }
    if (_jpgImages.containsKey(name)) {
      return _createImageFromMap(name, _jpgImages[name]!, 'jpg');
    }
    if (_pngImages.containsKey(name)) {
      return _createImageFromMap(name, _pngImages[name]!, 'png');
    }
    return _unknownImage;
  }

  void applyTheme(String theme) {
    _theme = theme;
    _images.clear();
  }

  Image _createImageFromMap(String name, bool isThemed, String extension) {
    Image image = Image.asset(
        '$_imagesDir/${isThemed ? '$_theme/' : ''}$name.$extension');
    _images[name] = image;
    return image;
  }
}
