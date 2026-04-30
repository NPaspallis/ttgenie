import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ttgenie/html_templates.dart';
import 'package:ttgenie/html_util.dart';
import 'package:universal_html/html.dart' as html;

import 'html_generators/academic_util.dart';
import 'html_generators/timetable_util.dart';
import 'model/data_entry.dart';
import 'model/academic.dart';
import 'model/module.dart';
import 'model/structure_row.dart';
import 'model/timetable_view_entry.dart';
import 'util.dart';
import 'timetable_view.dart';

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
  // static const Map<String,String> labs = {//todo delete
  //   "CY014": "Computer Lab CY014 (Capacity 32)",
  //   "CY114": "Computer Lab CY114 (Capacity 32)",
  //   "CY111": "Computer Lab CY111 (Capacity 20)",
  //   "CY112": "Computer Lab CY112 (Capacity 18)",
  //   "CYCSL": "CISCO Lab CYCSL (Capacity 20)",
  //   "CY020": "Electronics Lab",
  //   "CY021": "Engineering Lab"
  // };


  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;

  static final Map<String, List<TimetableEntry>> moduleCodeToTimetableEntryMap = {};
  static final Map<String, List<TimetableEntry>> academicIdToTimetableEntryMap = {};
  static final List<TimetableEntry> timetableEntries = [];
  static final Set<Module> allModules = {};
  static final Map<String, Module> allModuleCodeToModules = {};
  static final Map<String, List<StructureRow>> programmeToStructureRowsMap = {};
  static final Map<Module, List<String>> moduleToProgrammesMap = {};
  static final Map<String, Academic> emailToAcademic = {};
  static final List<TimetableViewEntry> timetableViewEntries = [];
  static final List<String> allProgrammes = [];
  static final Map<String, List<TimetableViewEntry>> programmeToTimetableViewEntries = {};
  static final Map<String, String> academicsEmailToName = {};
  static final Set<String> labs = {};

  String _htmlTimetable = '';

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

        // 2. Upload it (read the bytes) and process it
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          // Perform decoding in a slight delay if it's very fast to show the spinner
          // or just proceed if it's naturally heavy.
          var excel = Excel.decodeBytes(bytes);

          _addLog('Sheets number: ${excel.tables.keys.length}');
          _addLog('Sheets titles: ${excel.tables.keys.join(', ')}');

          // 3. Read data in data structures
          var sheetData = excel.tables['data'];
          if (sheetData != null) {
            _addLog('Processing timetable data ...');
            _loadTimetableEntries(sheetData);
            _addLog('Loaded timetable entries for ${moduleCodeToTimetableEntryMap.length} modules.');
          }

          var sheetModules = excel.tables['modules']!;
          _addLog('Processing modules ...');
          _loadModules(sheetModules);
          _addLog('Loaded ${allModules.length} modules');

          var sheetAcademics = excel.tables['academics']!;
          _addLog('Processing academics ...');
          _loadAcademics(sheetAcademics);
          _addLog('Loaded ${emailToAcademic.length} academics');

          var sheetTimetables = excel.tables['timetables']!;
          _addLog('Processing timetable data ...');
          _loadTimetableViewEntries(sheetTimetables);
          _addLog('Loaded ${timetableViewEntries.length} timetable entries.');


          // 5. populate allProgrammes from timetableViewEntries
          for (var entry in timetableViewEntries) {
            if (entry.type == "Modules" && !allProgrammes.contains(entry.programme)) {
              allProgrammes.add(entry.programme);
            }
          }
          _addLog('Loaded ${allProgrammes.length} programmes.');

          // 6. generate timetables
          String htmlProgrammes = "";
          for(TimetableViewEntry timetableViewEntry in timetableViewEntries) {
            if(timetableViewEntry.type == 'Modules') {
              List<TimetableEntry> selectedTimetableEntries = [];
              for(String moduleCode in timetableViewEntry.values) {
                selectedTimetableEntries.addAll(moduleCodeToTimetableEntryMap[moduleCode] ?? []);
              }

              htmlProgrammes += '${TimetableUtil.getTimetableFromTimetableEntriesAsHtml(timetableViewEntry.name, selectedTimetableEntries)}\n\n';
            }
          }

          String htmlAcademics = '';
          for(String academicId in academicIdToTimetableEntryMap.keys) {
            // _addLog('academicId: $academicId');
            Academic academic = emailToAcademic[academicId]!;
            // _addLog('academic: $academic');
            List<TimetableEntry> selectedTimetableEntries = academicIdToTimetableEntryMap[academicId]!;
            htmlAcademics += '${AcademicUtil.createAcademicTimetablesAsDiv(academic, selectedTimetableEntries, 0)}\n\n';
          }

          // todo add academics
          // String html = AcademicUtil.htmlPage.replaceAll('%html%', htmlAcademics);
          // String html = AcademicUtil.htmlPage.replaceAll('%html%', htmlProgrammes);
          String htmlNavbar = HtmlUtil.createNavbar(timetableViewEntries, academicsEmailToName, labs.toList());
          String html = HtmlTemplates.htmlPageModern
              .replaceAll('%navbar%', htmlNavbar)
              .replaceAll('%academics-divs%', htmlAcademics);
          setState(() => _htmlTimetable = html);

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

  void _loadTimetableEntries(Sheet sheetTimetables) {
    moduleCodeToTimetableEntryMap.clear();
    academicIdToTimetableEntryMap.clear();

    for (int i = 1; i < sheetTimetables.rows.length; i++) {
      var row = sheetTimetables.rows[i];
      if (row.isEmpty || row[2]?.value == null) continue;

      String getStr(int i) => (i < row.length && row[i]?.value != null) ? row[i]!.value.toString().trim() : '';
      double getNum(int i) {
        if (i >= row.length || row[i]?.value == null) return 0.0;
        final val = row[i]!.value;
        return double.tryParse(val.toString()) ?? 0.0;
      }

      final String recurrenceType = getStr(0);
      final String academicPeriodCode = getStr(1);
      final String dayName = getStr(2);
      final String moduleCode = getStr(3);
      final String moduleName = getStr(4);
      final TimeCellValue startTime = row[5]!.value as TimeCellValue;
      final TimeCellValue endTime = row[6]!.value as TimeCellValue;
      final String sessionTypeName = getStr(7);
      final DateCellValue startDate = row[8]!.value as DateCellValue;
      final DateCellValue endDate = row[9]!.value as DateCellValue;
      final String deliveryTypeName = getStr(10);
      final String roomCode = getStr(11);
      final String instructorName = getStr(12); // ignore for now
      final int expNoStudents = getNum(13).toInt();
      final String roomType = getStr(14);
      final String groupName = getStr(15);
      final String instructorId = getStr(16);
      final String notes = getStr(17);

      if (moduleCode.isEmpty) continue;

      final timetableEntry = TimetableEntry(
        recurrenceTypeName: recurrenceType,
        periodName: academicPeriodCode,
        dayName: dayName,
        moduleCode: moduleCode,
        moduleName: moduleName,
        startTime: DateTime(2026, 1, 1, startTime.hour, startTime.minute),
        endTime: DateTime(2026, 1, 1, endTime.hour, endTime.minute),
        sessionTypeName: sessionTypeName,
        startDate: DateTime(startDate.year, startDate.month, startDate.day),
        endDate: DateTime(endDate.year, endDate.month, endDate.day),
        deliveryTypeName: deliveryTypeName,
        roomCode: roomCode,
        lecturerEmail: instructorId,
        expNoStudents: expNoStudents,
        roomType: roomType,
        groupName: groupName,
        notes: notes,
      );

      moduleCodeToTimetableEntryMap.putIfAbsent(moduleCode, () => []).add(timetableEntry);
      academicIdToTimetableEntryMap.putIfAbsent(instructorId.toLowerCase(), () => []).add(timetableEntry);
      timetableEntries.add(timetableEntry);
      academicsEmailToName[instructorId.toLowerCase()] = instructorName;
      if(roomCode.isNotEmpty && roomType == '2') {
        labs.add(roomCode);
      }
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
      allModuleCodeToModules[moduleCode] = module;
    }
  }

  void _loadAcademics(Sheet sheetAcademics) {
    emailToAcademic.clear();
    for (int i=1; i < sheetAcademics.rows.length; i++) {
      var row = sheetAcademics.rows[i];

      String getStr(int i) => (i < row.length && row[i]?.value != null) ? row[i]!.value.toString().trim() : '';

      final String email = getStr(0);
      final String name = getStr(1);
      final String role = getStr(2);
      final String qualifications = getStr(3);
      final bool skip = getStr(4).toLowerCase() == "skip";
      final String notes = getStr(5);

      final academic = Academic(
        email: email,
        name: name,
        role: role,
        qualifications: qualifications,
        skip: skip,
        notes: notes,
      );
      emailToAcademic[email] = academic;
    }
  }

  void _loadTimetableViewEntries(Sheet timetableViewEntriesSheet) {
    timetableViewEntries.clear();
    for (int i = 1; i < timetableViewEntriesSheet.rows.length; i++) {
      var row = timetableViewEntriesSheet.rows[i];
      if (row.isEmpty) continue;

      String getStr(int index) => (index < row.length && row[index]?.value != null) ? row[index]!.value.toString().trim() : '';

      String type = getStr(0);
      String group = getStr(1);
      String programme = getStr(2);
      bool distanceLearning = "true" == getStr(3).toLowerCase();
      String name = getStr(4);

      List<String> values = [];
      for (int j = 5; j < row.length; j++) {
        String val = getStr(j);
        if (val.isEmpty) break;
        values.add(val);
      }
      TimetableViewEntry timetableViewEntry = TimetableViewEntry(
        type: type,
        group: group,
        programme: programme,
        distanceLearning: distanceLearning,
        name: name,
        values: values,
      );
      timetableViewEntries.add(timetableViewEntry);
      programmeToTimetableViewEntries.putIfAbsent(programme, () => []).add(timetableViewEntry);
    }

  }

  // keep this unused for now
  void _loadStructures(Sheet sheetStructures) {
    programmeToStructureRowsMap.clear();
    moduleToProgrammesMap.clear();

    for (int i = 2; i < sheetStructures.rows.length; i++) {
      var row = sheetStructures.rows[i];
      if (row.isEmpty || row[1]?.value == null) continue;

      String getStr(int i) => (i < row.length && row[i]?.value != null) ? row[i]!.value.toString().trim() : '';
      double getNum(int i) {
        if (i >= row.length || row[i]?.value == null) return 0.0;
        final val = row[i]!.value;
        return double.tryParse(val.toString()) ?? 0.0;
      }

      final String programme = getStr(1);
      final String mode = getStr(2);
      final String moduleCode = getStr(3);
      final double facultyHours = getNum(4);
      final double associatesHours = getNum(5);

      final structureRow = StructureRow(
        programme: programme,
        mode: mode,
        moduleCode: moduleCode,
        facultyHours: facultyHours,
        associatesHours: associatesHours,
      );

      // populate programmeToStructureRowsMap
      programmeToStructureRowsMap.putIfAbsent(programme, () => []).add(structureRow);

      // populate modulesToProgrammesMap
      final module = Util.getModule(allModules, moduleCode, mode);
      if (module != null) {
        moduleToProgrammesMap.putIfAbsent(module, () => []).add(programme);
      }
    }
    _addLog('Loaded structures for ${programmeToStructureRowsMap.length} programmes.');
  }

  Future<void> _downloadHtml() async {
    if (_htmlTimetable.isEmpty) {
      _addLog('No HTML to download.');
      return;
    }

    try {
      final Uint8List bytes = Uint8List.fromList(utf8.encode(_htmlTimetable));
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "timetable.html")
          ..click();
        html.Url.revokeObjectUrl(url);
        _addLog('HTML download triggered in browser.');
      } else {
        // FilePicker.saveFile handles the writing on Desktop if 'bytes' is provided.
        // It returns null on mobile platforms.
        String? result = await FilePicker.saveFile(
          fileName: 'timetable.html',
          type: FileType.custom,
          allowedExtensions: ['html'],
          bytes: bytes,
        );
        if (result != null) {
          _addLog('HTML saved: $result');
        } else {
          _addLog('Save canceled or not supported on this platform.');
        }
      }
    } catch (e) {
      _addLog('Error saving HTML: $e');
    }
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
              label: const Text('Upload XLSX file'),
            ),
            TextButton.icon(
              onPressed: _htmlTimetable.isEmpty ? null : () {
                _addLog('Downloading file ...');
                _downloadHtml();
              },
              icon: const Icon(Icons.download),
              label: const Text('Download HTML file'),
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
            Center(
              child: _htmlTimetable.isEmpty ?
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 64, color: Colors.blue),
                    SizedBox(height: 16),
                    Text('Timetables', style: TextStyle(fontSize: 24)),
                    Text('The processed timetables will be displayed here.'),
                  ],
                ) :
                TimetableView(html: _htmlTimetable),
            ),
          ],
        )
      ),
    );
  }
}
