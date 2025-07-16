import 'package:cached_network_image/cached_network_image.dart';
import 'package:coka/api/api_client.dart';
import 'package:flutter/material.dart';

Widget getAvatarWidget(imgData) {
  return imgData?.contains("https") ?? false
      ? CachedNetworkImage(
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Icon(Icons.error),
          imageUrl: imgData,
        )
      : CachedNetworkImage(
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Icon(Icons.error),
          imageUrl: '${ApiClient.baseUrl.replaceFirst("dev", "api")}$imgData',
        );
}

Color getColorFromInitial(String initial) {
  if (initial.isEmpty) return Colors.white;
  final colors = [
    const Color(0xFF431165),
    const Color(0xFF54D3EC),
    const Color(0xFF675CF5),
    const Color(0xFFF7706E),
    const Color(0x663949AB)
  ];
  List<Color> alphabetColors = [
    const Color(0xFF431165),
    const Color(0xFF54D3EC),
    const Color(0xFF675CF5),
    const Color(0xFFF7706E),
    const Color(0x663949AB)
  ];
  for (final x in colors) {
    alphabetColors.addAll(generateColors(x));
  }

  // Get the first character of the initial and convert it to lowercase
  String firstLetter = initial.substring(0, 1).toLowerCase();

  // Get the index of the firstLetter in the alphabet (a=0, b=1, ..., z=25)
  int index = firstLetter.codeUnitAt(0) - 'a'.codeUnitAt(0);

  // If the index is not in the range of a-z, set it to the last color (for other characters)
  if (index < 0 || index > 25) {
    index = 26;
  }

  // Return the corresponding color from the list
  return alphabetColors[index];
}

Widget createRoundedAvatar(
    {required String name, double? width, double? height, double? borderRadius, double? fontSize}) {
  // Get the initials (1 or 2 characters)
  String initials = getInitials(name);

  // Get the color based on the initials
  Color avatarColor = getColorFromInitial(initials);

  // Return the CircleAvatar widget
  return Container(
    decoration: BoxDecoration(
      color: avatarColor,
      borderRadius: BorderRadius.circular(borderRadius ?? 16),
    ),
    width: width ?? 100,
    height: height ?? 100,
    child: Center(
      child: Text(
        initials,
        style:
            TextStyle(color: Colors.white, fontSize: fontSize ?? 50, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

Widget createCircleAvatar({required String name, double? radius, double? fontSize}) {
  // Get the initials (1 or 2 characters)
  String initials = getInitials(name);

  // Get the color based on the initials
  Color avatarColor = getColorFromInitial(initials);

  // Return the CircleAvatar widget
  return Container(
      height: (radius ?? 19) * 2,
      width: (radius ?? 19) * 2,
      decoration: const BoxDecoration(
          shape: BoxShape.circle,
          // border: Border.all(color: const Color(0xffDACFFF), width: 1),
          // boxShadow: const [
          //   BoxShadow(
          //       color: Color(0x26000000),
          //       offset: Offset(0, 1),
          //       blurRadius: 3,
          //       spreadRadius: 1)
          // ],
          color: Colors.white),
      child: CircleAvatar(
        backgroundColor: avatarColor,
        radius: radius ?? 19,
        child: Text(
          initials,
          style:
              TextStyle(color: Colors.white, fontSize: fontSize ?? 15, fontWeight: FontWeight.bold),
        ),
      ));
}

Widget createSquareAvatar({required String name, double? radius, double? fontSize}) {
  // Get the initials (1 or 2 characters)
  String initials = getInitials(name);

  // Get the color based on the initials
  Color avatarColor = getColorFromInitial(initials);

  // Return the CircleAvatar widget
  return Container(
      height: (radius ?? 19) * 2,
      width: (radius ?? 19) * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: avatarColor),
      child: Text(
        initials,
        style:
            TextStyle(color: Colors.white, fontSize: fontSize ?? 15, fontWeight: FontWeight.bold),
      ));
}

List<Color> generateColors(Color baseColor) {
  // Convert the base color to HSL
  HSLColor hslColor = HSLColor.fromColor(baseColor);

  // Adjust the brightness of the base color
  double brightnessFactor = 0.12;
  Color darkerColor =
      hslColor.withLightness((hslColor.lightness - brightnessFactor).clamp(0.0, 1.0)).toColor();
  Color lighterColor =
      hslColor.withLightness((hslColor.lightness + brightnessFactor).clamp(0.0, 1.0)).toColor();

  // Generate new colors by adjusting the hue
  double hueIncrement = 10.0;
  List<Color> generatedColors = [];

  for (double i = 0; i < 7; i++) {
    double hue = (hslColor.hue + (hueIncrement * i)) % 360.0;
    Color newColor = HSLColor.fromAHSL(1.0, hue, hslColor.saturation, hslColor.lightness).toColor();
    generatedColors.add(newColor);
  }

  // Combine the base color with the generated colors
  return [darkerColor, lighterColor, ...generatedColors];
}

String getInitials(String fullName) {
  if (fullName.isEmpty) return '';

  List<String> nameParts = fullName.trim().split(' ');

  String initials = nameParts.length == 1
      ? nameParts[0][0]
      : nameParts[0][0] + nameParts[nameParts.length - 1][0];

  return initials.toUpperCase();
}
