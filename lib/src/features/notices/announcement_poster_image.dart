import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import 'notices_provider.dart';

/// Renders an announcement poster stored in private S3, via the
/// Sanctum-reachable proxy (GET /api/mobile/media/{path}) — never a direct
/// S3 URL. Falls back to a neutral campaign-icon tile if the poster fails
/// to load or auth headers can't be resolved.
class AnnouncementPosterImage extends ConsumerWidget {
  final String posterPath;
  final BoxFit fit;

  const AnnouncementPosterImage({super.key, required this.posterPath, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headersAsync = ref.watch(posterAuthHeadersProvider);

    return headersAsync.when(
      loading: () => _placeholder(),
      error: (_, _) => _placeholder(),
      data: (headers) => CachedNetworkImage(
        imageUrl: '${AppConstants.baseUrl}/media/$posterPath',
        httpHeaders: headers,
        fit: fit,
        placeholder: (_, _) => _placeholder(),
        errorWidget: (_, _, _) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.accentBg,
        child: const Center(
          child: Icon(Icons.campaign_rounded, color: AppColors.accent, size: 32),
        ),
      );
}
