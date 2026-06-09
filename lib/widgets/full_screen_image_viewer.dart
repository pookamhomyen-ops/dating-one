import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FullScreenImageViewer extends StatelessWidget {
  final List<String> urls;
  final int initialIndex;
  final bool isPrivate;

  const FullScreenImageViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
    this.isPrivate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      body: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: PageView.builder(
              itemCount: urls.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return Center(
                  child: Stack(
                    children: [
                      Image.network(
                        urls[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      if (isPrivate)
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: Container(color: AppColors.textPrimary.withOpacity(0.3)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: AppColors.background, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
