import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_ui/functions/pubkey_color.dart';

class NBanner extends StatefulWidget {
  final Ndk ndk;
  final String pubKey;
  final Duration animationDuration;

  const NBanner({
    super.key,
    required this.ndk,
    required this.pubKey,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<NBanner> createState() => _NBannerState();
}

class _NBannerState extends State<NBanner> with SingleTickerProviderStateMixin {
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
      begin: 0.95,
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
        return AnimatedSwitcher(
          duration: widget.animationDuration,
          child: _buildBannerContent(snapshot),
        );
      },
    );
  }

  Widget _buildBannerContent(AsyncSnapshot<Metadata?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildDefaultBanner();
    }

    final banner = snapshot.data?.banner;
    if (banner == null) {
      return _buildDefaultBanner();
    }

    return _buildImageBanner(banner);
  }

  Widget _buildDefaultBanner() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: pubkeyColor(widget.pubKey),
      brightness: Theme.of(context).brightness,
    );

    return FadeTransition(
      key: const ValueKey('default'),
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 10,
          width: 10,
          color: colorScheme.primaryContainer,
        ),
      ),
    );
  }

  Widget _buildImageBanner(String bannerUrl) {
    return FadeTransition(
      key: ValueKey(bannerUrl),
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Image.network(
          bannerUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return ColoredBox(
              color: pubkeyColor(widget.pubKey).withValues(alpha: 0.3),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultBanner();
          },
        ),
      ),
    );
  }
}
