part of 'zone_info_bloc.dart';

abstract class ZoneInfoState extends Equatable {
  const ZoneInfoState();
  @override
  List<Object> get props => [];
}

class ZoneInfoInitial extends ZoneInfoState {

}


class ZoneInfoStateLoading extends ZoneInfoState {
  @override
  String toString() => 'ZoneInfoBlocStateLoading';
}

class ZoneInfoBlocStateSuccess extends ZoneInfoState {
  final ZoneInfo info;

  ZoneInfoBlocStateSuccess(this.info);

  @override
  String toString() => 'ZoneInfoBlocStateSuccess { info: ${info.zone1Info!.on} }';
}

class ZoneInfoBlocStateError extends ZoneInfoState {
  final dynamic error;

  ZoneInfoBlocStateError(this.error);

  @override
  String toString() => 'ZoneInfoBlocStateError';
}
