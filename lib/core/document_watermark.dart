import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List createDiagonalLogoWatermark(
  Uint8List logoBytes, {
  double opacity = 0.13,
}) {
  final decodedLogo = img.decodePng(logoBytes);
  if (decodedLogo == null) {
    throw const FormatException('Could not decode the company logo.');
  }
  final logo = decodedLogo.convert(numChannels: 4);

  for (final pixel in logo) {
    final isWhiteBackground =
        pixel.r >= 245 && pixel.g >= 245 && pixel.b >= 245;
    pixel.a = isWhiteBackground ? 0 : (pixel.a * opacity).round();
  }

  final watermarkWidth = logo.width > logo.height ? 800 : 540;
  final resized = img.copyResize(
    logo,
    width: watermarkWidth,
    interpolation: img.Interpolation.average,
  );
  final rotated = img.copyRotate(
    resized,
    angle: -45,
    interpolation: img.Interpolation.average,
  );
  final canvas = img.Image(width: 1000, height: 1414, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
  img.compositeImage(
    canvas,
    rotated,
    dstX: (canvas.width - rotated.width) ~/ 2,
    dstY: (canvas.height - rotated.height) ~/ 2,
  );

  return Uint8List.fromList(img.encodePng(canvas));
}
