import 'dart:collection';

import 'package:ttgenie/html_generators/conflict_util.dart';
import 'package:ttgenie/html_generators/timetable_util.dart';
import 'package:ttgenie/model/message.dart';
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
      moduleCodes.add(timetableEntry.moduleCode);
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

    String htmlModules = '';
    for(String moduleCode in moduleCodes) {
      htmlModules += '<span class="module">$moduleCode</span>\n';
    }

    String htmlModes = '';
    htmlModes += fullYearTimetableEntries.isNotEmpty ? '<span class="badge">Full Year <span class="check-icon">✓</span></span>\n' : '';
    htmlModes += sem1 ? '<span class="badge">Sem 1</b> <span class="check-icon">✓</span></span>\n' : '';
    htmlModes += sem2 ? '<span class="badge">Sem 2</b> <span class="check-icon">✓</span></span>\n' : '';

    String html = '<div>';

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

    final List<Message> conflictMessages = ConflictUtil.findConflicts(timetableEntries, checkGroups: true);
    String htmlConflicts = '';
    for(final Message conflictMessage in conflictMessages) {
      htmlConflicts += '${conflictMessage.toBadgeHtml()}\n';
    }

    return programmeDivTemplate
        .replaceAll('%programme-id%', HtmlUtil.replaceSpaces('${timetableViewEntry.programme}-${timetableViewEntry.name}'))
        .replaceAll('%programme-name%', programmeName)
        .replaceAll('%programme-group%', timetableViewEntry.group)
        .replaceAll('%programme-type%', timetableViewEntry.distanceLearning ? 'distance learning' : 'conventional delivery')
        .replaceAll('%html-modules%', htmlModules)
        .replaceAll('%html-modes%', htmlModes)
        .replaceAll('%html-conflicts%', htmlConflicts)
        .replaceAll('%timetables-div%', html);
  }

  // requires the following data:
  // - %programme_id% (no spaces)
  // - %programme_group%
  // - %programme_name%
  // - %programme_type% (conventional delivery | distance learning)
  // - %timetables-div%
  static const String programmeDivTemplate = r'''
        <div class="card academic" id="%programme-id%">
          <h2>%programme-name%</h2>
          <div class="card-meta">
            <span class="card-tag">%programme-group%</span>
            <span class="card-tag">%programme-type%</span>
          </div>
          <div class="card-meta">
            %html-modules%
          </div>
          <div class="card-meta">
            %html-modes%
          </div>
          <div class="card-meta">
            %html-conflicts%
          </div>
          <br/>
          %timetables-div%
        </div>
  ''';
}