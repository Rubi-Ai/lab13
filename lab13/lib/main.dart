import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Ключ форми
  late Database database;
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'notes.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY, text TEXT, timestamp TEXT)',
        );
      },
      version: 1,
    );
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final List<Map<String, dynamic>> data = await database.query(
      'notes',
      orderBy: 'timestamp DESC',
    );
    setState(() {
      notes = data;
    });
  }

  Future<void> _addNote() async {
    if (!_formKey.currentState!.validate()) return; // Перевірка форми

    final text = _controller.text.trim();
    final now = DateTime.now();
    final formattedTimestamp = DateFormat('dd.MM.yyyy, HH:mm:ss').format(now);

    await database.insert(
      'notes',
      {'text': text, 'timestamp': formattedTimestamp},
    );
    _controller.clear();
    _loadNotes();
  }

  Future<void> _deleteNote(int id) async {
    await database.delete('notes', where: 'id = ?', whereArgs: [id]);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter Demo Home Page'),
      centerTitle: true,
      backgroundColor: const Color.fromARGB(255, 175, 137, 238),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter a note',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Value is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addNote,
                    child: Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Dismissible(
                  key: Key(note['id'].toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteNote(note['id']);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['text'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                note['timestamp'],
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
