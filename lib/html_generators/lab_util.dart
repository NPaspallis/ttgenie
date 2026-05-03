import 'dart:collection';

import 'package:ttgenie/html_generators/timetable_util.dart';

import '../model/data_entry.dart';
import '../model/message.dart';
import 'conflict_util.dart';

class LabUtil {
  static String createLabTimetablesAsHtml(final String labId, List<TimetableEntry> timetableEntries) {

    Set<String> moduleCodes = SplayTreeSet<String>();
    final List<TimetableEntry> fullYearTimetableEntries = [];
    final List<TimetableEntry> sem1TimetableEntries = [];
    final List<TimetableEntry> sem2TimetableEntries = [];
    final List<TimetableEntry> sem3TimetableEntries = [];
    bool sem1 = false, sem2 = false, sem3 = false;

    for (final timetableEntry in timetableEntries) {
      if (timetableEntry.deliveryTypeName == "Full Year") {
        fullYearTimetableEntries.add(timetableEntry);
        sem1TimetableEntries.add(timetableEntry);
        sem2TimetableEntries.add(timetableEntry);
      } else if (timetableEntry.deliveryTypeName == "Semester 1") {
        sem1 = true;
        sem1TimetableEntries.add(timetableEntry);
      } else if (timetableEntry.deliveryTypeName == "Semester 2") {
        sem2 = true;
        sem2TimetableEntries.add(timetableEntry);
      } else if (timetableEntry.deliveryTypeName == "Semester 3") {
        sem3 = true;
        sem3TimetableEntries.add(timetableEntry);
      }
    }

    String html = "<div>";

    // html += "<p>Modules: $moduleCodes</p>\n";
    //
    // html += "<p><b>Timetables</b> (Full Year: ${fullYearTimetableEntries.isNotEmpty ? "Yes" : "No"}, Sem 1: ${sem1 ? "Yes" : "No"}, Sem 2: ${sem2 ? "Yes" : "No"}, Sem 3: ${sem3 ? "Yes" : "No"})</p>";

    String htmlModules = '';
    for(String moduleCode in moduleCodes) {
      htmlModules += '<span class="module">$moduleCode</span>\n';
    }

    String htmlModes = '';
    htmlModes += fullYearTimetableEntries.isNotEmpty ? '<span class="badge">Full Year <span class="check-icon">✓</span></span>\n' : '';
    htmlModes += sem1 ? '<span class="badge">Sem 1</b> <span class="check-icon">✓</span></span>\n' : '';
    htmlModes += sem2 ? '<span class="badge">Sem 2</b> <span class="check-icon">✓</span></span>\n' : '';

    if (!sem1 && !sem2) {
      html += TimetableUtil.getTimetableFromTimetableEntriesAsHtml("Full Year", timetableEntries);
    } else {
      html += TimetableUtil.getTimetableFromTimetableEntriesAsHtml("Semester 1", sem1TimetableEntries);
      html += TimetableUtil.getTimetableFromTimetableEntriesAsHtml("Semester 2", sem2TimetableEntries);
    }
    if (sem3) {
      html += TimetableUtil.getTimetableFromTimetableEntriesAsHtml("Semester 3", sem3TimetableEntries);
    }

    html += "</div>";

    final List<Message> conflictMessages = ConflictUtil.findConflicts(timetableEntries ?? [], checkGroups: false);
    String htmlConflicts = '';
    for(final Message conflictMessage in conflictMessages) {
      htmlConflicts += '${conflictMessage.toBadgeHtml()}\n';
    }

    return template
        .replaceAll('%lab-id%', labId)
        .replaceAll('%html-modules%', htmlModules)
        .replaceAll('%html-modes%', htmlModes)
        .replaceAll('%html-conflicts%', htmlConflicts)
        .replaceAll('%lab-timetables%', html);
  }

  static String template = r'''
        <div class="card lab" id="room_%lab-id%">
          <h2><div class="lab-icon">🖥️</div>%lab-id%</h2>
          <div class="card-meta">
            %html-modules%
          </div>
          <div class="card-meta">
            %html-modes%
          </div>
          <div class="card-meta">
            %html-conflicts%
          </div>
          %lab-timetables%
        </div>
  ''';
}