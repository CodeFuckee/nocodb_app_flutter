import 'package:flutter/material.dart';

class FullScreenImagePage extends StatefulWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  int _quarterTurns = 0;

  void _rotateImage() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right),
            onPressed: _rotateImage,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: RotatedBox(
            quarterTurns: _quarterTurns,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  '无法加载图片',
                  style: TextStyle(color: Colors.white),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator(
                  color: Colors.white,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
