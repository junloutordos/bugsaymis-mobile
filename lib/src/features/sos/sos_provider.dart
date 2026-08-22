import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

final sosConfigProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response =
      await ref.read(apiClientProvider).get('/student/portal/sos/config');
  return response.data as Map<String, dynamic>;
});
