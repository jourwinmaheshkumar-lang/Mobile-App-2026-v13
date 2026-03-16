/// Modern 3D Emoji-Style Icon Pack for Flutter
/// 
/// This class provides easy access to all 3D emoji-style icons
/// designed for the mobile application. Each icon features:
/// - Smooth glossy 3D design
/// - Rounded edges
/// - Vibrant colors with soft gradients
/// - Soft studio lighting
/// - Subtle shadows
/// - Transparent background
/// 
/// Usage:
/// ```dart
/// Image.asset(AppIcons.dice, width: 48, height: 48)
/// ```
class AppIcons {
  AppIcons._();
  
  // Base path for all icons
  static const String _basePath = 'assets/icons/';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // GAMES & ENTERTAINMENT
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// 🎲 Red and white 3D dice icon
  static const String dice = '${_basePath}icon_dice.png';
  
  /// 🎮 Blue gaming controller/joystick icon
  static const String joystick = '${_basePath}icon_joystick.png';
  
  /// 🧩 Blue and yellow puzzle pieces icon
  static const String puzzle = '${_basePath}icon_puzzle.png';
  
  /// 🎳 Purple bowling ball with pins icon
  static const String bowling = '${_basePath}icon_bowling.png';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SPORTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// ⚽ Classic black and white soccer ball icon
  static const String soccerBall = '${_basePath}icon_soccer_ball.png';
  
  /// 🏀 Orange basketball with black lines icon
  static const String basketball = '${_basePath}icon_basketball.png';
  
  /// 🎾 Yellow-green tennis ball icon
  static const String tennis = '${_basePath}icon_tennis.png';
  
  /// ⚾ Brown wooden baseball bat icon
  static const String baseballBat = '${_basePath}icon_baseball_bat.png';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CELEBRATIONS & PARTY
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// 🎈 Glossy red party balloon icon
  static const String balloon = '${_basePath}icon_balloon.png';
  
  /// 🎆 Colorful fireworks explosion icon
  static const String fireworks = '${_basePath}icon_fireworks.png';
  
  /// 🎉 Party popper with confetti icon
  static const String confetti = '${_basePath}icon_confetti.png';
  
  /// 🎁 Red gift box with golden bow icon
  static const String gift = '${_basePath}icon_gift.png';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TOYS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// 🧸 Cute brown teddy bear icon
  static const String teddyBear = '${_basePath}icon_teddy_bear.png';
  
  /// 🪁 Colorful flying kite icon
  static const String kite = '${_basePath}icon_kite.png';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SYMBOLS & ACHIEVEMENTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// ❤️ Red glossy heart icon
  static const String heart = '${_basePath}icon_heart.png';
  
  /// ⭐ Golden star icon
  static const String star = '${_basePath}icon_star.png';
  
  /// 🏆 Golden trophy with smiley face icon
  static const String trophy = '${_basePath}icon_trophy.png';
  
  /// 🥇 Gold medal with red ribbon icon
  static const String medal = '${_basePath}icon_medal.png';
  
  /// 👑 Golden royal crown with gems icon
  static const String crown = '${_basePath}icon_crown.png';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MYSTICAL & SPECIAL
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// 🔮 Purple crystal ball on golden stand icon
  static const String crystalBall = '${_basePath}icon_crystal_ball.png';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Returns a list of all available icon paths
  static List<String> get allIcons => [
    dice,
    joystick,
    puzzle,
    bowling,
    soccerBall,
    basketball,
    tennis,
    baseballBat,
    balloon,
    fireworks,
    confetti,
    gift,
    teddyBear,
    kite,
    heart,
    star,
    trophy,
    medal,
    crown,
    crystalBall,
  ];
  
  /// Returns icons grouped by category
  static Map<String, List<String>> get iconsByCategory => {
    'Games & Entertainment': [dice, joystick, puzzle, bowling],
    'Sports': [soccerBall, basketball, tennis, baseballBat],
    'Celebrations & Party': [balloon, fireworks, confetti, gift],
    'Toys': [teddyBear, kite],
    'Symbols & Achievements': [heart, star, trophy, medal, crown],
    'Mystical & Special': [crystalBall],
  };
  
  /// Returns the icon name from the path (without extension)
  static String getIconName(String iconPath) {
    final fileName = iconPath.split('/').last;
    return fileName.replaceAll('icon_', '').replaceAll('.png', '').replaceAll('_', ' ');
  }
}
