import 'package:bloc/bloc.dart';
import 'package:fores/cbloc/cbloc.dart';
import 'package:meta/meta.dart';

part 'shortcuts_event.dart';

part 'shortcuts_state.dart';

class ShortcutsBloc extends CBloc<ShortcutsEvent, ShortcutsState> {
  ShortcutsBloc() : super(ShortcutsInitial(), subscribedTopics: ["shortcuts"]) {
    on<ShortcutsEvent>((event, emit) {});
  }
}
