import 'package:flutter/material.dart';
import 'package:mynotes/services/crud/notes_service.dart';

import '../../utils/delete_dialog.dart';

// typedef is a function-type alias which is used as a pointer that references a function
// here we define the function signature
typedef DeleteNoteCallback = void Function(DBNote note);

class NotesListView extends StatelessWidget {
  final List<DBNote> allNotes;
  final DeleteNoteCallback
      onDeleteNote; // invoke the typedef function with variable name onDeleteNote
  const NotesListView({
    Key? key,
    required this.allNotes,
    required this.onDeleteNote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: allNotes.length,
      itemBuilder: (context, index) {
        final note = allNotes[index];
        return ListTile(
          title: Text(
            note.text!,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            onPressed: () async {
              final shouldDelete = await showDeleteDialog(context);

              if (shouldDelete) {
                onDeleteNote(note);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        );
      },
    );
  }
}
