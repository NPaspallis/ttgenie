import 'dart:math';

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
    'Saturday',
    'Sunday'
  ];

  static String replaceSpaces(String text) {
    return text.replaceAll(' ', '_');
  }

  static String getModuleAsHtml(TimetableEntry entry) {
    // Basic implementation - can be expanded as needed
    return '<div class="tooltip">${entry.moduleCode}<span class="tooltiptext">${entry.toTooltipHTML()}</span></div>';
  }

  static String createNavbar(final List<TimetableViewEntry> timetableViewEntries, final Map<String, String> academicsEmailToName, final List<String> labs) {

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

    final List<String> academicNames = academicsEmailToName.values.toList();
    academicNames.sort();
    const int numOfAcademicsGroups = 4;
    int numOfAcademicsPerGroup = (academicNames.length / numOfAcademicsGroups).ceil();
    List<String> groupNames = [];
    for(int i=0; i<numOfAcademicsGroups; i++) {
      String firstLetter = i==0 ? 'A' : academicNames[i*numOfAcademicsPerGroup][0];
      int lastIndex = min((i+1)*numOfAcademicsPerGroup-1, academicNames.length-1);
      String lastLetter = i<numOfAcademicsGroups-1 ? academicNames[lastIndex][0] : 'Z';
      groupNames.add('$firstLetter to $lastLetter');
    }

    String htmlAcademics = '';
    for(int i=0; i < numOfAcademicsGroups; i++) {
      htmlAcademics += '<div class="mega-col">\n';
      htmlAcademics += '<div class="mega-col-title">${groupNames[i]}</div>\n\n';

      final int firstIndex = i*numOfAcademicsPerGroup;
      final int lastIndex = i<numOfAcademicsGroups-1 ? (i+1)*numOfAcademicsPerGroup : academicNames.length;
      for(int j=firstIndex; j<lastIndex; j++) {
        final String url = replaceSpaces('#academic-${academicNames[j]}');
        htmlAcademics += '<a href="#$url"><span></span>${academicNames[j]}</a>\n';
        htmlAcademics += '\n';
      }

      htmlAcademics += '</div>\n\n';
    }

    labs.sort();
    String htmlLabs = '';
    for(String lab in labs) {
      htmlLabs += '<a href="#$lab"><span></span>$lab</a>\n\n';
    }

    return navbarTemplate
        .replaceAll('%programmes-links%', htmlProgrammes)
        .replaceAll('%academics-links%', htmlAcademics)
        .replaceAll('%labs-links%', htmlLabs);
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

    </ul>
  </nav>
''';
}