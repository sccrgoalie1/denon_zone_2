class BasicInfo {
  bool on;
  double volume;
  bool muted;
  String source;
  List<SourceStatus> sources;
  BasicInfo();
}

class ZoneInfo {
  BasicInfo zone1Info;
  BasicInfo zone2Info;
}

class SourceStatus {
  String name;
  String rename;
}