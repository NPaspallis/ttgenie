import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'Academic.dart';
import 'Module.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ExcelProcessor(),
    );
  }
}

class ExcelProcessor extends StatefulWidget {
  const ExcelProcessor({super.key});

  @override
  State<ExcelProcessor> createState() => _ExcelProcessorState();
}

class _ExcelProcessorState extends State<ExcelProcessor> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;

  static final Set<Module> allModules = {};
  // static final Map<String, List<StructureRow>> programmeToStructureRowsMap = {};
  // static final Map<Module, List<String>> moduleToProgrammesMap = {};
  static final Map<String, Academic> emailToAcademic = {};

  void _addLog(String message) {
    // debugPrint(message);
    setState(() {
      _logs.add(message);
    });
  }


  @override
  void initState() {
    super.initState();
    _addLog('Console Log');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessFile() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Allow the user to pick a file of XLSX type
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true, // Required to access the file content as bytes
      );

      if (result != null) {
        _addLog('File selected: ${result.files.single.name}');
        _addLog('Processing...');

        // 2. Upload it (read the bytes) and process it
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          // Perform decoding in a slight delay if it's very fast to show the spinner
          // or just proceed if it's naturally heavy.
          var excel = Excel.decodeBytes(bytes);

          _addLog('Sheets number: ${excel.tables.keys.length}');
          _addLog('Sheets titles: ${excel.tables.keys.join(', ')}');

          // 3. Print the contents in the log
          for (var table in excel.tables.keys) {
            _addLog('--- Sheet: $table ---');

            // var sheet = excel.tables[table]!;
            // for (var row in sheet.rows) {
            //   // Extract values from each cell in the row
            //   var rowValues = row.map((cell) => cell?.value?.toString() ?? '').toList();
            //   _addLog('Row: $rowValues');
            // }
          }

          var sheetModules = excel.tables['modules']!;
          _addLog('Processing modules ...');
          _loadModules(sheetModules);

          var sheetAcademics = excel.tables['academics']!;
          _addLog('Processing academics ...');
          _loadAcademics(sheetAcademics);

          _addLog('Modules:');
          _addLog(allModules.toString());
          _addLog('Academics:');
          _addLog(emailToAcademic.toString());
        } else {
          _addLog('Error: Could not read file bytes.');
        }
      } else {
        _addLog('User canceled file selection.');
      }
    } catch (e) {
      _addLog('Error picking or processing file: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _loadModules(Sheet sheetModules) {
    allModules.clear();
    for (int i = 1; i < sheetModules.rows.length; i++) {
      var row = sheetModules.rows[i];
      // if (row.isEmpty || row[0]?.value == null || row[0]?.value.toString() == '#') {
      //   continue;
      // }

      String getStr(int i) => (i < row.length && row[i]?.value != null) ? row[i]!.value.toString().trim() : '';
      double getNum(int i) {
        if (i >= row.length || row[i]?.value == null) return 0.0;
        final val = row[i]!.value;
        return double.tryParse(val.toString()) ?? 0.0;
      }

      final String num = getStr(0);
      // final String programme = getStr(1);
      final String mode = getStr(2);
      final String moduleCode = getStr(3);
      final String moduleName = getStr(4);
      final double ects = getNum(5);
      final double hours = getNum(6);
      final String notes = getStr(7);
      final double pct1 = getNum(8);
      final String tutor1 = getStr(9);
      final bool faculty1 = getNum(10) == 1;
      final double hoursTutor1 = getNum(11);
      final double pct2 = getNum(12);
      final String tutor2 = getStr(13);
      final bool faculty2 = getNum(14) == 1;
      final double hoursTutor2 = getNum(15);

      final module = Module(
        num: num,
        mode: mode,
        moduleCode: moduleCode,
        moduleName: moduleName,
        ects: ects,
        hours: hours,
        notes: notes,
        pct1: pct1,
        tutor1: tutor1,
        faculty1: faculty1,
        hoursTutor1: hoursTutor1,
        pct2: pct2,
        tutor2: tutor2,
        faculty2: faculty2,
        hoursTutor2: hoursTutor2,
      );
      allModules.add(module);
    }
    _addLog('Loaded ${allModules.length} modules.');
  }

  void _loadAcademics(Sheet sheetAcademics) {
    emailToAcademic.clear();
    for (int i=1; i < sheetAcademics.rows.length; i++) {
      var row = sheetAcademics.rows[i];
      // if (row.isEmpty || row[0]?.value == null || row[0]?.value.toString() == '#') {
      //   continue;
      // }

      String getStr(int i) => (i < row.length && row[i]?.value != null) ? row[i]!.value.toString().trim() : '';

      final String email = getStr(0);
      final String name = getStr(1);
      final String role = getStr(2);
      final String qualifications = getStr(3);
      final String education = getStr(4);
      final String expertise = getStr(5);

      final academic = Academic(
        email: email,
        name: name,
        role: role,
        qualifications: qualifications,
        education: education,
        expertise: expertise,
      );
      emailToAcademic[email] = academic;
    }
    _addLog('Loaded ${emailToAcademic.length} academics.');
  }

  static double _getHours(final Module module, final String email) {
    if (module.tutor1 == email) {
      return module.hoursTutor1;
    } else if (module.tutor2 == email) {
      return module.hoursTutor2;
    } else {
      return 0.0;
    }
  }

  static Module? _getModule(final String moduleCode, final String mode) {
    for (Module module in allModules) {
      if (module.moduleCode == moduleCode && module.mode == mode) {
        return module;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Timetable Genie'),
          actions: [
            TextButton.icon(
              onPressed: _isProcessing ? null : () {
                _addLog('Selecting file ...');
                _pickAndProcessFile();
              },
              icon: const Icon(Icons.upload),
              label: const Text(
                'Pick and Upload XLSX file'
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.terminal), text: 'Logs'),
              Tab(icon: Icon(Icons.report_problem), text: 'Issues'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Timetables'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Logs
            Container(
              color: Colors.black,
              child: Theme(
                data: ThemeData.dark().copyWith(
                  scrollbarTheme: const ScrollbarThemeData(
                    thumbColor: WidgetStatePropertyAll(Colors.white60),
                    radius: Radius.circular(10),
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 8.0,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Tab 2: Issues Placeholder
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_problem, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Issues', style: TextStyle(fontSize: 24)),
                  Text('Any issues found in the XLSX will appear here.'),
                ],
              ),
            ),
            // Tab 3: Timetables Placeholder
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('Timetables', style: TextStyle(fontSize: 24)),
                  Text('The processed timetables will be displayed here.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
