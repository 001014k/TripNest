class SharedLinkPlatform {
  static bool domain(String host, String root) =>
      host == root || host.endsWith('.$root');
  static String detect(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '기타';
    final host = uri.host.toLowerCase();
    if (domain(host, 'instagram.com')) return 'Instagram';
    if (domain(host, 'youtube.com') || host == 'youtu.be') return 'YouTube';
    if (domain(host, 'naver.com') || host == 'naver.me') return 'Naver';
    if (domain(host, 'daum.net') || domain(host, 'tistory.com')) return 'Daum';
    if (domain(host, 'kakao.com') || host == 'kko.to') return 'Kakao';
    if (domain(host, 'google.com') ||
        domain(host, 'google.co.kr') ||
        host == 'maps.app.goo.gl' ||
        host == 'goo.gl') {
      return uri.path.contains('/maps') ||
              host.startsWith('maps.') ||
              host == 'goo.gl'
          ? 'Google Maps'
          : 'Google';
    }
    if (domain(host, 'blogspot.com')) return 'Blogger';
    if (domain(host, 'tiktok.com')) return 'TikTok';
    if (domain(host, 'facebook.com')) return 'Facebook';
    if (domain(host, 'twitter.com') || domain(host, 'x.com')) return 'Twitter';
    return '기타';
  }

  /// Public review articles, not search results or map listings.
  static bool supportsPlaces(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !['https', 'http'].contains(uri.scheme)) return false;
    final host = uri.host.toLowerCase();
    return host == 'naver.me' ||
        host == 'blog.naver.com' ||
        host == 'm.blog.naver.com' ||
        host == 'cafe.naver.com' ||
        host == 'm.cafe.naver.com' ||
        host == 'story.pay.naver.com' ||
        host == 'cafe.daum.net' ||
        host == 'm.cafe.daum.net' ||
        domain(host, 'tistory.com') ||
        domain(host, 'blogspot.com');
  }

  static bool isExcludedPortal(String url) =>
      const {'Google', 'Google Maps', 'Naver', 'Daum', 'Kakao'}
          .contains(detect(url)) &&
      !supportsPlaces(url);
}
