class BarAxis {
  final String x;
  final double y;

  const BarAxis({required this.x, required this.y});
}

class BarData {
  final double lowIncome;
  final double orphanage;
  final double oldFolkHome;
  final double cancerNGO;
  final double wildlifeProtection;
  final double environmentProtection;

  BarData({
    required this.lowIncome,
    required this.orphanage,
    required this.oldFolkHome,
    required this.cancerNGO,
    required this.wildlifeProtection,
    required this.environmentProtection,
  });

  List<BarAxis> barData = [];

  void initializeBarData() {
    barData = [
      BarAxis(x: "Low Income", y: lowIncome),
      BarAxis(x: "Orphanage", y: orphanage),
      BarAxis(x: "Old Folk", y: oldFolkHome),
      BarAxis(x: "Cancer NGO", y: cancerNGO),
      BarAxis(x: "MMF", y: wildlifeProtection),
      BarAxis(x: "CETDEM", y: environmentProtection),
    ];
  }
}