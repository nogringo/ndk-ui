import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_ui/functions/pubkey_color.dart';

class NPicture extends StatefulWidget {
  final Ndk ndk;
  final String pubKey;
  final Duration animationDuration;

  const NPicture({
    super.key,
    required this.ndk,
    required this.pubKey,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<NPicture> createState() => _NPictureState();
}

class _NPictureState extends State<NPicture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.ndk.metadata.loadMetadata(widget.pubKey),
      builder: (context, snapshot) {
        return _buildPictureContent(snapshot);
      },
    );
  }

  Widget _buildPictureContent(AsyncSnapshot<Metadata?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildDefaultPicture(snapshot.data?.getName());
    }

    final picture = snapshot.data?.picture;
    if (picture == null) {
      return _buildDefaultPicture(snapshot.data?.getName());
    }

    return _buildImagePicture(picture);
  }

  Widget _buildDefaultPicture(String? name) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '';
    final color = pubkeyColor(widget.pubKey);

    return FadeTransition(
      key: const ValueKey('default'),
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          color: color,
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicture(String pictureUrl) {
    return FadeTransition(
      key: ValueKey(pictureUrl),
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Image.network(
          pictureUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return ColoredBox(color: pubkeyColor(widget.pubKey));
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultPicture(null);
          },
        ),
      ),
    );
  }
}
