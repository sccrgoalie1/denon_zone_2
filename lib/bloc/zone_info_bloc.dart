import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:denon_zone_2/basic_info.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import 'package:denon_zone_2/denon_service.dart';

part 'zone_info_event.dart';
part 'zone_info_state.dart';

class ZoneInfoBloc extends Bloc<ZoneInfoEvent, ZoneInfoState> {
  DenonService service;

  ZoneInfoBloc({@required this.service}) : super(ZoneInfoInitial());

  @override
  Stream<ZoneInfoState> mapEventToState(ZoneInfoEvent event,) async* {
    if (event is ZoneInfoRefreshEvent) {
      yield ZoneInfoStateLoading();
      try {
        final info = await service.getInfo();
        yield ZoneInfoBlocStateSuccess(info);
      } catch (error) {
        yield ZoneInfoBlocStateError(error);
      }
    }
  }
}

