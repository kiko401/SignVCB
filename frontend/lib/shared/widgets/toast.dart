import 'package:flutter/material.dart';

class ToastHost extends StatelessWidget {
  const ToastHost({super.key, required this.child});

  final Widget child;

  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(String message) {
    final messenger = messengerKey.currentState;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(key: messengerKey, child: child);
  }
}
