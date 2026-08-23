import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';

/// CachedNetworkImage takes a plain header map, not a Dio interceptor, so
/// this duplicates the one line of ApiClient's auth logic that images need
/// (same duplication AnnouncementPosterImage carries for posters).
final studentAuthHeadersProvider = FutureProvider<Map<String, String>>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: AppConstants.tokenKey);
  return token != null ? {'Authorization': 'Bearer $token'} : {};
});

/// Renders the authenticated student's own profile photo via the
/// Sanctum-reachable self-scoped proxy (GET /api/mobile/student/photo) —
/// never a direct S3 URL. There is no per-student parameter in that URL,
/// so this always shows the signed-in student's own photo. [child] is
/// shown instead whenever there is no photo on file or it fails to load
/// (e.g. an initials fallback).
class StudentPhotoImage extends ConsumerWidget {
  final Widget child;
  final BoxFit fit;
  final Alignment alignment;

  const StudentPhotoImage({
    super.key,
    required this.child,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headersAsync = ref.watch(studentAuthHeadersProvider);

    return headersAsync.when(
      loading: () => child,
      error: (_, _) => child,
      data: (headers) => CachedNetworkImage(
        imageUrl: '${AppConstants.baseUrl}/student/photo',
        httpHeaders: headers,
        fit: fit,
        alignment: alignment,
        placeholder: (_, _) => child,
        errorWidget: (_, _, _) => child,
      ),
    );
  }
}
