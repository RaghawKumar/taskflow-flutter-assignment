import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controllers/app_bloc.dart';

class AppScope extends BlocProvider<AppBloc> {
  const AppScope({super.key, required AppBloc bloc, required super.child})
    : super.value(value: bloc);
  static AppBloc of(BuildContext context, {bool listen = true}) =>
      listen ? context.watch<AppBloc>() : context.read<AppBloc>();
}
