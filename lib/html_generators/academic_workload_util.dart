import 'package:flutter/cupertino.dart';

import '../html_util.dart';
import '../model/data_entry.dart';

class AcademicWorkloadUtil {

  static String createAcademicWorkloadAsHtml(final Map<String, String> academicIdlToName, final Map<String, String> academicIdlToRank, final Map<String, List<TimetableEntry>> academicIdToTimetableEntryMap) {

    String workloadTable = '<table><tr><th>Name</th><th>Semester 1</th><th>Semester 2</th><th>Semester 3</th><th>Overall hours</th><th>Weekly hours</th></tr>';

    List<String> academicIds = academicIdToTimetableEntryMap.keys.toList();
    academicIds.sort((id1,id2) => compare(academicIdlToName[id1]!, academicIdlToRank[id1]!, academicIdlToName[id2]!, academicIdlToRank[id2]!));
    for(String academicId in academicIds) {
      // compute workload
      final List<TimetableEntry> selectedTimetableEntries = academicIdToTimetableEntryMap[academicId] ?? [];
      double sem1_hours = 0, sem2_hours = 0, sem3_hours = 0;
      for(TimetableEntry timetableEntry in selectedTimetableEntries) {
        final int minutes = timetableEntry.endTime.difference(timetableEntry.startTime).inMinutes;
        final double hours = minutes/60;
        if(timetableEntry.deliveryTypeName == 'Full Year') {
          sem1_hours += hours;
          sem2_hours += hours;
        } else if(timetableEntry.deliveryTypeName == 'Semester 1') {
          sem1_hours += hours;
        } else if(timetableEntry.deliveryTypeName == 'Semester 2') {
          sem2_hours += hours;
        } else if(timetableEntry.deliveryTypeName == 'Semester 3') {
          sem3_hours += hours;
        }
      }
      double totalHoursForYear = sem1_hours * 15 + sem2_hours * 15 + sem3_hours * 10;

      String academicRank = academicIdlToRank[academicId]!;
      String academicName = academicIdlToName[academicId]!;
      String academicUrl = 'academic-${HtmlUtil.replaceSpaces(academicName)}';
      final String url = HtmlUtil.replaceSpaces('workload-academic-$academicName');
      workloadTable += '''
        <tr id="$url">
          <td><b>$academicRank <a href="#$academicUrl">$academicName</a></b></td>
          <td>${sem1_hours > 0 ? sem1_hours.toStringAsFixed(1) : ''}</td>
          <td>${sem2_hours > 0 ? sem2_hours.toStringAsFixed(1) : ''}</td>
          <td>${sem3_hours > 0 ? sem3_hours.toStringAsFixed(1) : ''}</td>
          <td>$totalHoursForYear hrs</td>
          <td>${(totalHoursForYear/30).toStringAsFixed(1)} hrs</td>
        </tr>''';
    }

    workloadTable += '</table>';

    return htmlWorkloadTemplate.replaceAll('%workload-table%', workloadTable);
  }

  static int compare(String name1, String rank1, String name2, String rank2) {
    if(rank1 == rank2) {
      return name1.compareTo(name2);
    } else {
      if(rank1 == 'Prof.') {
        return -1;
      } else if(rank2 == 'Prof.') {
        return 1;
      } else if(rank1 == 'Assoc. Prof.') {
        return -1;
      } else if(rank2 == 'Assoc. Prof.') {
        return 1;
      } else if(rank1 == 'Assist. Prof.') {
        return -1;
      } else if(rank2 == 'Assist. Prof.') {
        return 1;
      } else if(rank1 == 'Lecturer') {
        return -1;
      } else if(rank2 == 'Lecturer') {
        return 1;
      } else if(rank1 == 'Lecturer (TO)') {
        return -1;
      } else if(rank2 == 'Lecturer (TO)') {
        return 1;
      } else if(rank1 == 'STS') {
        return -1;
      } else if(rank2 == 'STS') {
        return 1;
      } else {
        debugPrint('Unknown ranks: $rank1 vs $rank2');
        return 0;
      }
    }
  }
}

const htmlWorkloadTemplate = '''
    <!-- ══ WORKLOAD ══ -->
    <section id="workload" class="section" style="scroll-margin-top: var(--nav-h)">
      <div class="section-header">
        <h2 class="section-title">Workload</h2>
      </div>
      <div class="cards">

        %workload-table%

      </div>
    </section>
''';