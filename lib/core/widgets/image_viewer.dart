import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const ImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  static void show(BuildContext context, String imageUrl, {String? heroTag}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(imageUrl: imageUrl, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: heroTag != null
              ? Hero(
                  tag: heroTag!,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
