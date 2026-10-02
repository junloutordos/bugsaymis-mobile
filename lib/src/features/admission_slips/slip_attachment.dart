import 'dart:convert';

class SlipAttachment {
  static const maxBytes = 8 * 1024 * 1024;
  static const _mimeByExt = {
    'pdf': 'application/pdf',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
  };

  final String name;
  final String dataUri;
  const SlipAttachment({required this.name, required this.dataUri});

  /// Cloudflare WAF blocks multipart uploads on this app — files travel as base64 JSON.
  factory SlipAttachment.fromBytes({required String name, required List<int> bytes}) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final mime = _mimeByExt[ext];
    if (mime == null) throw const FormatException('Only PDF, PNG or JPEG files can be attached.');
    if (bytes.length > maxBytes) throw const FormatException('The file is too large (max 8 MB).');
    return SlipAttachment(name: name, dataUri: 'data:$mime;base64,${base64Encode(bytes)}');
  }
}
