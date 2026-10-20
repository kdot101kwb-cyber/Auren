/// Shared media-type inference for URLs attached to AUREN Pulse posts.
String postMediaTypeFromUrl(String url) {
  if (url.trim().isEmpty) return 'none';

  final path = Uri.tryParse(url.trim())?.path.toLowerCase() ?? url.toLowerCase();
  if (RegExp(r'\.(mp4|mov|webm|m4v|avi|mkv)$').hasMatch(path)) {
    return 'video';
  }
  return 'image';
}
