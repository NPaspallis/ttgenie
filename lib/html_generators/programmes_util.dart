import 'dart:collection';

import 'package:ttgenie/html_generators/timetable_util.dart';
import 'package:ttgenie/model/timetable_view_entry.dart';

import '../html_util.dart';
import '../model/data_entry.dart';

class ProgrammesUtil {

  static String getProgrammeTimetableAsDiv(TimetableViewEntry timetableViewEntry, List<TimetableEntry> timetableEntries) {

    final String programmeName = '${timetableViewEntry.programme}: ${timetableViewEntry.name}';

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

    return programmeDivTemplate
        .replaceAll('%programme_id%', HtmlUtil.replaceSpaces('${timetableViewEntry.programme}-${timetableViewEntry.name}'))
        .replaceAll('%programme_group%', timetableViewEntry.group)
        .replaceAll('%programme_type%', timetableViewEntry.distanceLearning ? 'distance learning' : 'conventional delivery')
        .replaceAll('%timetables-div%', html);
  }

  // requires the following data:
  // - %programme_id% (no spaces)
  // - %programme_group%
  // - %programme_name%
  // - %programme_type% (conventional delivery | distance learning)
  // - %timetables-div%
  static const String programmeDivTemplate = r'''
        <div class="card academic" id="%programme_id%">
          <span class="card-tag">%programme_group%</span>
          %timetables-div%
          <div class="card-meta">
            <span class="badge">%programme_type%</span>
          </div>
        </div>
  ''';
}