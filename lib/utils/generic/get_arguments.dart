import 'package:flutter/material.dart' show BuildContext, ModalRoute;

// create an extension on BuildContext to extract arguments of BuildContext
// in order to pass it onto navigator stack
extension GetArgument on BuildContext {
  // function to optionally return value of type T
  T? getArgument<T>() {
    final modalRoute = ModalRoute.of(this);
    // this keyword refers to BuildContext
    if (modalRoute != null) {
      final args = modalRoute.settings.arguments;
      if (args != null && args is T) {
        // if the arguments are the same type as you ask to extract, return args
        return args as T;
      }
    }
    return null;
  }
}
