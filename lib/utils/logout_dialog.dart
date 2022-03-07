import 'package:flutter/cupertino.dart';
import 'package:mynotes/utils/generic_dialog.dart';

Future<bool> showLogOutDialog(
  BuildContext context,
) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Log out',
    content: 'Are you sure you want to log out?',
    optionsBuilder: () => {
      'Cancel': false,
      'Log out': true,
    },
  ).then((value) => value ?? false);
  // then() block is a safeguard in case a user wants to dismiss the dialog
  // by tapping outside of the dialog box instead of either of the button
  // which contains value. In that case, default value will be false(cancel)
}
