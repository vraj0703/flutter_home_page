import 'package:flutter_bloc/flutter_bloc.dart';

/// Drawer open/closed state. Lightweight on purpose — kept separate from
/// SceneBloc (which owns scene transitions) to avoid muddying that state
/// graph. Provided alongside SceneBloc in FlameScene's MultiBlocProvider.
class MenuDrawerState {
  final bool isOpen;
  const MenuDrawerState({required this.isOpen});

  MenuDrawerState copyWith({bool? isOpen}) =>
      MenuDrawerState(isOpen: isOpen ?? this.isOpen);
}

class MenuDrawerCubit extends Cubit<MenuDrawerState> {
  MenuDrawerCubit() : super(const MenuDrawerState(isOpen: false));

  void open()    => emit(const MenuDrawerState(isOpen: true));
  void dismiss() => emit(const MenuDrawerState(isOpen: false));
  void toggle()  => emit(MenuDrawerState(isOpen: !state.isOpen));
}
