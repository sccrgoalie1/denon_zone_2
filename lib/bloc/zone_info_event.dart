part of 'zone_info_bloc.dart';

abstract class ZoneInfoEvent extends Equatable {
  const ZoneInfoEvent();
  @override
  List<Object> get props => [];
}


class ZoneInfoRefreshEvent extends ZoneInfoEvent {

  ZoneInfoRefreshEvent();
}
