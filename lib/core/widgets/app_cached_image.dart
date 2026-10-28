import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Widget? placeholder;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) {
        if (placeholder != null) return placeholder!;
        return _buildShimmerPlaceholder(context);
      },
      errorWidget: (context, url, error) {
        if (errorWidget != null) return errorWidget!;
        return _buildErrorWidget(context);
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildShimmerPlaceholder(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: baseColor, borderRadius: borderRadius),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor(context).withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: (width != null && width! < 50) ? 20 : 32,
          color: colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
