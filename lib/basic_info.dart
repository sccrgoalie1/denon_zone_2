class BasicInfo {
  late bool on;
  double? volume;
  bool? muted;
  String? source;
  late List<SourceStatus> sources;
  BasicInfo();
}

class ZoneInfo {
  BasicInfo? zone1Info;
  BasicInfo? zone2Info;
}

class SourceStatus {
  String? name;
  late String rename;
}