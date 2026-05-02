import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ttgenie/html_generators/lab_util.dart';
import 'package:ttgenie/html_generators/programmes_util.dart';
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
  static final Map<String, List<TimetableEntry>> labIdToTimetableEntryMap = {};
  static final List<TimetableEntry> timetableEntries = [];
  static final Set<Module> allModules = {};
  static final Map<String, Module> allModuleCodeToModules = {};
  static final Map<String, List<StructureRow>> programmeToStructureRowsMap = {};
  static final Map<Module, List<String>> moduleToProgrammesMap = {};
  static final Map<String, Academic> emailToAcademic = {};
  static final List<TimetableViewEntry> timetableViewEntries = [];
  static final List<String> allProgrammes = [];
  static final Map<String, List<TimetableViewEntry>> programmeToTimetableViewEntries = {};
  static final Map<String, String> academicIdlToName = {};

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
    _initPackageInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  late PackageInfo _packageInfo = PackageInfo(version: '0.0.0', appName: '', packageName: '', buildNumber: '');

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
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

          // var sheetAcademics = excel.tables['academics']!;
          // _addLog('Processing academics ...');
          // _loadAcademics(sheetAcademics);
          // _addLog('Loaded ${emailToAcademic.length} academics');

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

          // 6.a for programmes
          String htmlProgrammes = "";
          for(TimetableViewEntry timetableViewEntry in timetableViewEntries) {
            if(timetableViewEntry.type == 'Modules') {
              List<TimetableEntry> selectedTimetableEntries = [];
              for(String moduleCode in timetableViewEntry.values) {
                selectedTimetableEntries.addAll(moduleCodeToTimetableEntryMap[moduleCode] ?? []);
              }

              htmlProgrammes += '${ProgrammesUtil.getProgrammeTimetableAsDiv(timetableViewEntry, selectedTimetableEntries)}\n\n';
            }
          }

          // 6.b for academics
          final List<String> academicIds = academicIdlToName.keys.toList();
          final List<String> academicNames = academicIdlToName.values.toList();
          String htmlAcademics = '';
          academicIds.sort((id1,id2) => academicIdlToName[id1]!.compareTo(academicIdlToName[id2]!));
          academicNames.sort();
          for(String academicId in academicIds) {
            final List<TimetableEntry> selectedTimetableEntries = academicIdToTimetableEntryMap[academicId.toLowerCase()]!;
            final String academicName = academicIdlToName[academicId.toLowerCase()]!;
            htmlAcademics += '${AcademicUtil.createAcademicTimetablesAsDiv(academicName, selectedTimetableEntries, 0)}\n\n';
          }

          // 6.c for rooms and labs
          final List<String> labIds = labIdToTimetableEntryMap.keys.toList();
          labIds.sort();
          String htmlLabs = '';
          for(String labId in labIds) {
            final List<TimetableEntry> selectedTimetableEntries = labIdToTimetableEntryMap[labId]!;
            htmlLabs += '${LabUtil.createLabTimetablesAsHtml(labId, selectedTimetableEntries)}\n\n';
          }

          String htmlNavbar = HtmlUtil.createNavbar(timetableViewEntries, academicNames, labIds.toList());
          String html = HtmlTemplates.htmlPageModern
              .replaceAll('%navbar%', htmlNavbar)
              .replaceAll('%programmes-divs%', htmlProgrammes)
              .replaceAll('%academics-divs%', htmlAcademics)
              .replaceAll('%labs-divs%', htmlLabs);
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
    academicIdlToName.clear();

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
      final String lecturerName = getStr(12); // ignore for now
      final int expNoStudents = getNum(13).toInt();
      final String roomType = getStr(14);
      final String groupName = getStr(15);
      final String lecturerId = getStr(16);
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
        lecturerName: lecturerName,
        expNoStudents: expNoStudents,
        roomType: roomType,
        groupName: groupName,
        lecturerId: lecturerId,
        notes: notes,
      );

      moduleCodeToTimetableEntryMap.putIfAbsent(moduleCode, () => []).add(timetableEntry);
      academicIdToTimetableEntryMap.putIfAbsent(lecturerId.toLowerCase(), () => []).add(timetableEntry);
      academicIdlToName[lecturerId.toLowerCase()] = lecturerName;
      timetableEntries.add(timetableEntry);
      if(roomCode.isNotEmpty) {
        labIdToTimetableEntryMap.putIfAbsent(roomCode, () => []).add(timetableEntry);
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
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Timetable Genie'),
              Text('version ${_packageInfo.version}', style: TextStyle(fontSize: 14.0))
            ],
          ),
          leading: Padding(
            padding: const EdgeInsets.all(5.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage('icons/Icon-192.png'),
            ),
          ),
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
        ),
        body: Center(
          child: _htmlTimetable.isEmpty ?
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isProcessing ?
                CircularProgressIndicator() :
                Icon(Icons.calendar_today, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(_isProcessing ? 'Loading ...' : 'Timetables', style: TextStyle(fontSize: 24)),
              Text(_isProcessing ? 'Processing could take up to 30 seconds' : 'The HTML timetables will be displayed here.'),
            ],
          ) :
          TimetableView(html: _htmlTimetable),
        )
      ),
    );
  }
}
