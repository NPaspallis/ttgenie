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
import 'model/data_entry.dart';
import 'model/timetable_view_entry.dart';
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

  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;

  static final Map<String, List<TimetableEntry>> moduleCodeToTimetableEntryMap = {};
  static final Map<String, List<TimetableEntry>> academicIdToTimetableEntryMap = {};
  static final Map<String, List<TimetableEntry>> labIdToTimetableEntryMap = {};
  static final List<TimetableEntry> timetableEntries = [];
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

          // 3. Read 'data' in data structures
          var sheetData = excel.tables['data'];
          if (sheetData != null) {
            _addLog('Processing timetable data ...');
            _loadTimetableEntries(sheetData);
            _addLog('Loaded timetable entries for ${moduleCodeToTimetableEntryMap.length} modules.');
          }

          // 4. read 'timetables' in data structures
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
