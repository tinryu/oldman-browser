// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class RadioGroup<T> extends StatelessWidget {
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget child;

  const RadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _RadioGroupScope<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: child,
    );
  }
}

class _RadioGroupScope<T> extends InheritedWidget {
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  const _RadioGroupScope({
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  static _RadioGroupScope<T>? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_RadioGroupScope<T>>();
  }

  @override
  bool updateShouldNotify(_RadioGroupScope<T> oldWidget) {
    return groupValue != oldWidget.groupValue ||
        onChanged != oldWidget.onChanged;
  }
}

class RadioListTileWrapper<T> extends StatelessWidget {
  final T value;
  final Widget? title;

  const RadioListTileWrapper({super.key, required this.value, this.title});

  @override
  Widget build(BuildContext context) {
    final scope = _RadioGroupScope.of<T>(context);
    return RadioListTile<T>(
      title: title,
      value: value,
      groupValue: scope?.groupValue,
      onChanged: scope?.onChanged,
    );
  }
}
