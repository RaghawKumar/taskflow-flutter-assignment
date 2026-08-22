import 'package:flutter/widgets.dart';
import '../controllers/app_controller.dart';

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppController of(BuildContext context, {bool listen = true}) {
    if (!listen)
      return context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
    return context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  }
}
