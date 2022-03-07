import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_service.dart';
import 'package:mynotes/utils/generic/get_arguments.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({Key? key}) : super(key: key);

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  DBNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _noteContent;

  Future<DBNote> createOrGetExistingNote(BuildContext context) async {
    // when the function is called, it will check if there exists a note argument,
    // meaning that the user taps on a note on the notes list to enter this view.
    // If so, returns the this view populated note content field with
    // the existing note argument
    final widgetNote = context.getArgument<DBNote>();
    if (widgetNote != null) {
      // assign the extract note object and assign to this view's _note variable
      _note = widgetNote;
      _noteContent.text = widgetNote.text!; // populate the note text field
      return widgetNote;
    }

    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }

    final email = AuthService.firebase().currentUser!.email!;
    final owner = await _notesService.getUser(email: email);
    final newNote = await _notesService.createNote(owner: owner);
    // reassign the newNote to this view's private _note variable so that
    // it is either saved or deleted upon user pressing the back button and dispose this view
    _note = newNote;
    return newNote;
  }

  void _noteContentControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _noteContent.text;
    await _notesService.updateNote(
      note: note,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _noteContent.removeListener(_noteContentControllerListener);
    _noteContent.addListener(_noteContentControllerListener);
  }

  void _deleteNoteIfEmpty() {
    final note = _note;

    // if the text field for note content is empty and there already exists note, delete it off of db
    if (_noteContent.text.isEmpty && note != null) {
      _notesService.deleteNote(noteId: note.id);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _noteContent.text;
    if (text.isNotEmpty && note != null) {
      await _notesService.updateNote(
        note: note,
        text: text,
      );
    }
  }

  @override
  void initState() {
    _notesService = NotesService();
    _noteContent = TextEditingController();
    super.initState();
  }

  // When user clicks back or when this create new note widget is disposed,
  // check if the note is empty or not. If empty, delete the note from db.
  // Otherwise, save it
  @override
  void dispose() {
    _deleteNoteIfEmpty();
    _saveNoteIfTextNotEmpty();
    _noteContent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create new note'),
      ),
      body: FutureBuilder(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return TextField(
                controller: _noteContent,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                    hintText: 'Start writing your note...'),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
