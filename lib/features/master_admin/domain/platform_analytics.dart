class PlatformAnalytics {
  const PlatformAnalytics({
    required this.totalGyms,
    required this.activeCoaches,
    required this.totalTrainees,
  });

  final int totalGyms;
  final int activeCoaches;
  final int totalTrainees;

  static const empty = PlatformAnalytics(
    totalGyms: 0,
    activeCoaches: 0,
    totalTrainees: 0,
  );
}
