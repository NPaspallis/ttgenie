import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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

  void _addLog(String message) {
    // debugPrint(message);
    setState(() {
      _logs.add(message);
    });
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

          // 3. Print the contents in the log
          for (var table in excel.tables.keys) {
            _addLog('--- Sheet: $table ---');
            var sheet = excel.tables[table]!;
            
            for (var row in sheet.rows) {
              // Extract values from each cell in the row
              var rowValues = row.map((cell) => cell?.value?.toString() ?? '').toList();
              _addLog('Row: $rowValues');
            }
          }
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Timetable Genie'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.upload), text: 'Process'),
              Tab(icon: Icon(Icons.terminal), text: 'Logs'),
              Tab(icon: Icon(Icons.report_problem), text: 'Issues'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Timetables'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Action Button
            Center(
              child: _isProcessing
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing Excel file...'),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _pickAndProcessFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Pick and Process XLSX'),
                    ),
            ),
            // Tab 2: Logs
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
            // Tab 3: Issues Placeholder
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
            // Tab 4: Timetables Placeholder
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
