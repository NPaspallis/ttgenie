import 'dart:math';

import 'package:ttgenie/html_generators/academic_workload_util.dart';

import 'model/data_entry.dart';
import 'model/timetable_view_entry.dart';

class HtmlUtil {
  static const int stepInMinsFullHour = 60;
  static const int stepInMinsHalfHour = 30;

  static const List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    // 'Saturday',
    // 'Sunday'
  ];

  static String replaceSpaces(String text) {
    return text.replaceAll(' ', '_');
  }

  static String getModuleAsHtml(TimetableEntry entry) {
    String name = entry.groupName.isEmpty ? entry.moduleCode : '${entry.moduleCode} (${entry.groupName})';
    String room = entry.roomCode.isEmpty ? '' : ' @ ${entry.roomCode}';
    String tutors = entry.lecturerId + (entry.lecturer2Id.isEmpty ? '' : ' + ${entry.lecturer2Id}');
    // Basic implementation - can be expanded as needed
    return '<div class="tooltip">$name<br>$room<br><i>$tutors</i><span class="tooltiptext">${entry.toTooltipHTML()}</span></div>';
  }

  static String createNavbar(final List<TimetableViewEntry> timetableViewEntries, final Map<String,String> academicIdsToNames, final Map<String,String> academicIdsToRanks, final List<String> labs, bool withWorkload) {

    final Map<String, Set<String>> groupToProgrammes = {};
    final Map<String, List<TimetableViewEntry>> programmeToTimetableViewEntries = {};
    for(TimetableViewEntry timetableViewEntry in timetableViewEntries) {
      if(timetableViewEntry.type == 'Modules') {
        groupToProgrammes.putIfAbsent(timetableViewEntry.group, () => {}).add(timetableViewEntry.programme);
        programmeToTimetableViewEntries.putIfAbsent(timetableViewEntry.programme, () => []).add(timetableViewEntry);
      }
    }

    String htmlProgrammes = '';
    for(final String group in groupToProgrammes.keys) {
      htmlProgrammes += '<div class="mega-col">\n';
      htmlProgrammes += '<div class="mega-col-title">$group</div>\n\n';

      final List<String> programmes = groupToProgrammes[group]!.toList();
      programmes.sort();

      for(String programme in programmes) {
        htmlProgrammes += '<p><span>$programme</span></p>\n';
        List<TimetableViewEntry> selectedTimetableViewEntries = programmeToTimetableViewEntries[programme]!;
        selectedTimetableViewEntries.sort();
        for(TimetableViewEntry timetableViewEntry in selectedTimetableViewEntries) {
          final String url = replaceSpaces('$programme-${timetableViewEntry.name}');
          htmlProgrammes += '<a href="#$url"><span></span>${timetableViewEntry.name}</a>\n';
          htmlProgrammes += '\n';
        }
      }

      htmlProgrammes += '</div>\n\n';
    }

    List<String> groupNames = ['Prof. & Assoc. Prof. & Assist. Prof.', 'Lecturer & Lecturer (TO)', 'STS (A-J)', 'STS (K-Z)'];

    final List<String> academicIds = academicIdsToRanks.keys.toList();
    academicIds.sort((id1, id2) => AcademicWorkloadUtil.compare(academicIdsToNames[id1]!, academicIdsToRanks[id1]!, academicIdsToNames[id2]!, academicIdsToRanks[id2]!));
    String htmlAcademics = '';
    for(int i=0; i < groupNames.length; i++) {
      htmlAcademics += '<div class="mega-col">\n';
      htmlAcademics += '<div class="mega-col-title">${groupNames[i]}</div>\n\n';

      for(String academicId in academicIds) {
        final String academicRank = academicIdsToRanks[academicId]!;
        if(i==0 && !(academicRank == 'Prof.' || academicRank == 'Assoc. Prof.' || academicRank == 'Assist. Prof.')) {
          continue;
        } else if(i==1 && !(academicRank == 'Lecturer' || academicRank == 'Lecturer (TO)')) {
          continue;
        } else if(i==2 && (academicRank != 'STS' || academicId[0].toLowerCase().compareTo('j') >= 0)) {
          continue;
        } else if(i==3 && (academicRank != 'STS' || academicId[0].toLowerCase().compareTo('j') < 0)) {
          continue;
        }
        final String academicName = academicIdsToNames[academicId]!;
        final String url = replaceSpaces('academic-$academicName');
        htmlAcademics += '<a href="#$url"><span></span>$academicName</a>\n';
        htmlAcademics += '\n';
      }

      htmlAcademics += '</div>\n\n';
    }

    labs.sort();
    String htmlLabs = '';
    for(String lab in labs) {
      htmlLabs += '<a href="#room_$lab"><span></span>$lab</a>\n\n';
    }

    String htmlWorkload = '';
    if(withWorkload) {

      const int numOfAcademicsGroups = 4;
      final int numOfAcademics = academicIdsToNames.length;
      int numOfAcademicsPerGroup = (numOfAcademics / numOfAcademicsGroups).ceil();
      // int numOfAcademicsPerGroup = (academicNames.length / numOfAcademicsGroups).ceil();
      String htmlWorkloadAcademics = '';
      for(int i=0; i < numOfAcademicsGroups; i++) {
        htmlWorkloadAcademics += '<div class="mega-col">\n';
        htmlWorkloadAcademics += '<div class="mega-col-title">${groupNames[i]}</div>\n\n';

        final int firstIndex = i*numOfAcademicsPerGroup;
        // final int lastIndex = i<numOfAcademicsGroups-1 ? (i+1)*numOfAcademicsPerGroup : academicNames.length;
        final int lastIndex = i<numOfAcademicsGroups-1 ? (i+1)*numOfAcademicsPerGroup : numOfAcademics;
        final List<String> academicNames = academicIdsToNames.values.toList();
        for(int j=firstIndex; j<lastIndex; j++) {
          String academicName = academicNames[j];
          final String url = replaceSpaces('workload-academic-$academicName');
          htmlWorkloadAcademics += '<a href="#$url"><span></span>$academicName</a>\n';
          htmlWorkloadAcademics += '\n';
        }

        htmlWorkloadAcademics += '</div>\n\n';
      }

      htmlWorkload = workloadHeader.replaceAll('%workload-academics-links%', htmlWorkloadAcademics);
    }

    return navbarTemplate
        .replaceAll('%programmes-links%', htmlProgrammes)
        .replaceAll('%academics-links%', htmlAcademics)
        .replaceAll('%labs-links%', htmlLabs)
        .replaceAll('<!-- %with-workload% -->', htmlWorkload);
  }

  static String navbarTemplate = '''
  <!-- NAVBAR -->
  <nav>
    <div class="nav-brand">ttgenie</div>
    <ul class="nav-menus">

      <li class="has-mega">
        <a href="#programmes">Programmes</a>
        <div class="mega-menu">
          <div class="mega-inner">

          %programmes-links%

          </div>
        </div>
      </li>

      <li class="has-mega">
        <a href="#academics">Academics</a>
        <div class="mega-menu">
          <div class="mega-inner">

          %academics-links%

          </div>
        </div>
      </li>

      <li>
        <a href="#labs">Labs</a>
        <div class="dropdown">
          %labs-links%
        </div>
      </li>

      <!-- %with-workload% -->
    </ul>
  </nav>
''';

  static String workloadHeader = '''
      <li class="has-mega">
      <a href="#workload">Workload</a>
      <div class="mega-menu">
        <div class="mega-inner">

        %workload-academics-links%

        </div>
      </div>
    </li>
''';
}