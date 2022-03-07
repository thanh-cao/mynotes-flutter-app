import 'package:flutter/material.dart';
import 'package:mynotes/utils/generic_dialog.dart';

// refactored showErrorDialog derived from a generic dialog
Future<void> showErrorDialog(
  BuildContext context,
  String text,
) {
  return showGenericDialog<void>(
    context: context,
    title: 'An error occured',
    content: text,
    optionsBuilder: () => {
      'OK': null,
    }, // optionsBuilder following the typedef DialogOptionBuilder function signature
  );
}

// old showErrorDialog
// Future<void> showErrorDialog(
//   BuildContext context,
//   String text,
// ) {
//   return showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: const Text('An error occured'),
//         content: Text(text),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: const Text('OK'),
//           )
//         ],
//       );
//     },
//   );
// }
