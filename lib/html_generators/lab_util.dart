import 'dart:collection';

import 'package:ttgenie/html_generators/timetable_util.dart';

import '../model/data_entry.dart';

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
    html += "<p>Modules: $moduleCodes</p>\n";

    html += "<p><b>Timetables</b> (Full Year: ${fullYearTimetableEntries.isNotEmpty ? "Yes" : "No"}, Sem 1: ${sem1 ? "Yes" : "No"}, Sem 2: ${sem2 ? "Yes" : "No"}, Sem 3: ${sem3 ? "Yes" : "No"})</p>";

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

    return template
        .replaceAll('%lab-id%', labId)
        .replaceAll('%lab-timetables%', html);
  }

  static String template = r'''
        <div class="card lab" id="room_%lab-id%">
          <div class="lab-icon">🖥️</div>
          <span class="card-tag">Room</span>
          <h3>%lab-id%</h3>
          %lab-timetables%
          <div class="card-meta">
            <span class="badge">Computer lab</span>
            <span class="badge">Lecture room</span>
          </div>
        </div>
  ''';
}