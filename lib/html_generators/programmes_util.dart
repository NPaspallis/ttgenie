import 'package:ttgenie/html_generators/timetable_util.dart';
import 'package:ttgenie/model/timetable_view_entry.dart';

import '../html_util.dart';
import '../model/data_entry.dart';

class ProgrammesUtil {

  static String getProgrammeTimetableAsDiv(TimetableViewEntry timetableViewEntry, List<TimetableEntry> selectedTimetableEntries) {

    final String programmeName = '${timetableViewEntry.programme}: ${timetableViewEntry.name}';
    final String html = TimetableUtil.getTimetableFromTimetableEntriesAsHtml(programmeName, selectedTimetableEntries);

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