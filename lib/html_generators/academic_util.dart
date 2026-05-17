import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../html_util.dart';
import '../model/data_entry.dart';
import '../model/message.dart';
import 'conflict_util.dart';
import 'timetable_util.dart';

class AcademicUtil {

  static String createAcademicTimetablesAsDiv(
      final String academicName,
      final String academicRank,
      List<TimetableEntry>? timetableEntries,
      final double targetHours) {
    
    final Map<String, double> deliveryTypeToTotalHours = {};

    Set<String> moduleCodes = SplayTreeSet<String>();
    final List<TimetableEntry> fullYearTimetableEntries = [];
    final List<TimetableEntry> sem1TimetableEntries = [];
    final List<TimetableEntry> sem2TimetableEntries = [];
    final List<TimetableEntry> sem3TimetableEntries = [];
    bool sem1 = false, sem2 = false, sem3 = false;

    for (final timetableEntry in timetableEntries ?? []) {
      moduleCodes.add(timetableEntry.moduleCode);
      
      // Calculate duration in minutes
      int minutes = timetableEntry.endTime.difference(timetableEntry.startTime).inMinutes;

      double currentHours = deliveryTypeToTotalHours[timetableEntry.deliveryTypeName] ?? 0.0;
      
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
      
      currentHours += minutes / 60.0;
      deliveryTypeToTotalHours[timetableEntry.deliveryTypeName] = currentHours;
    }

    final List<String> sortedDeliveryTypes = deliveryTypeToTotalHours.keys.toList()..sort();
    
    double totalHoursForAcademicYear = 0.0;
    double workloadSem1 = 0, workloadSem2 = 0, workloadSem3 = 0;

    for (final deliveryType in sortedDeliveryTypes) {
      final double totalHours = deliveryTypeToTotalHours[deliveryType] ?? 0.0;
      if (deliveryType.toLowerCase() == "full year") {
        workloadSem1 += totalHours;
        workloadSem2 += totalHours;
        totalHoursForAcademicYear += totalHours * 30;
      } else if (deliveryType.toLowerCase() == "semester 1") {
        workloadSem1 += totalHours;
        totalHoursForAcademicYear += totalHours * 15;
      } else if(deliveryType.toLowerCase() == "semester 2") {
        workloadSem2 += totalHours;
        totalHoursForAcademicYear += totalHours * 15;
      } else if (deliveryType.toLowerCase() == "semester 3") {
        workloadSem3 += totalHours;
        totalHoursForAcademicYear += totalHours * 10;
      } else {
        debugPrint('Invalid deliveryType: $deliveryType');
      }
    }
    String htmlWorkload = '<div class="workload"><b>Workload</b>: $totalHoursForAcademicYear hours in total (~<b>${(totalHoursForAcademicYear/30).toStringAsFixed(1)}</b> per week) ';
    if(workloadSem1 > 0) htmlWorkload += '[Sem1: ${workloadSem1.toStringAsFixed(1)} hrs/week] ';
    if(workloadSem2 > 0) htmlWorkload += '[Sem2: ${workloadSem2.toStringAsFixed(1)} hrs/week] ';
    if(workloadSem3 > 0) htmlWorkload += '[Sem3: ${workloadSem3.toStringAsFixed(1)} hrs/week] ';
    htmlWorkload += '</div>';

    String htmlModes = '';
    htmlModes += fullYearTimetableEntries.isNotEmpty ? '<span class="badge">Full Year <span class="check-icon">✓</span></span>\n' : '';
    htmlModes += sem1 ? '<span class="badge">Sem 1</b> <span class="check-icon">✓</span></span>\n' : '';
    htmlModes += sem2 ? '<span class="badge">Sem 2</b> <span class="check-icon">✓</span></span>\n' : '';

    String html = "<div>";

    if (moduleCodes.isNotEmpty) {
      if (!sem1 && !sem2) {
        html += TimetableUtil.getTimetableFromTimetableEntriesAsHtml("Full Year", timetableEntries ?? []);
      } else {
        html += TimetableUtil.getTimetableFromTimetableEntriesAsHtml("Semester 1", sem1TimetableEntries);
        html += TimetableUtil.getTimetableFromTimetableEntriesAsHtml("Semester 2", sem2TimetableEntries);
      }
      if (sem3) {
        html += TimetableUtil.getTimetableFromTimetableEntriesAsHtml("Semester 3", sem3TimetableEntries);
      }
    }

    // String targets = "";
    // if (targetHours > 0) {
    //   targets += "<p>Target hours: ${targetHours.toStringAsFixed(1)}</p>";
    // }

    html += "</div>";

    String htmlModuleCodes = '<div class="card-meta">\n';
    for(final String moduleCode in moduleCodes) {
      htmlModuleCodes += '  <span class="module">$moduleCode</span>\n';
    }
    htmlModuleCodes += '</div>\n\n';

    final List<Message> conflictMessages = ConflictUtil.findConflicts(timetableEntries ?? [], checkGroups: false);
    String htmlConflicts = '';
    for(final Message conflictMessage in conflictMessages) {
      htmlConflicts += '${conflictMessage.toBadgeHtml()}\n';
    }

    return academicDivTemplate
        .replaceAll('%academic-id%', HtmlUtil.replaceSpaces(academicName))
        .replaceAll('%academic-initials%', getInitials(academicName))
        .replaceAll('%academic-name%', academicName)
        .replaceAll('%academic-rank%', academicRank)
        .replaceAll('%module-divs%', htmlModuleCodes)
        .replaceAll('%academic-modes%', htmlModes)
        .replaceAll('%workload%', htmlWorkload)
        .replaceAll('%html-conflicts%', htmlConflicts)
        .replaceAll('%timetables-divs%', html);
  }

  static String getInitials(String name) {
    if(name.length < 2) return '??';
    final int indexOfFirstSpace = name.indexOf(' ');
    final String firstName = name.substring(0, indexOfFirstSpace);
    final String lastName = name.substring(indexOfFirstSpace+1);
    return firstName[0] + lastName[0];
  }

  // must replace:
  // - %academic-id% (no spaces)
  // - %academic-initials%
  // - %academic-name%
  // - %module-divs%
  // - %academic-modes%
  // - %workload%
  // - %html-conflicts%
  // - %timetables-divs%
  static const String academicDivTemplate = r'''
        <div class="card academic page" id="academic-%academic-id%">
          <div class="card-meta">
            <div class="rank-badge">%academic-rank%</div>
          </div>
          <h2><div class="card-avatar">%academic-initials%</div>%academic-name%</h2>
          %module-divs%
          <div class="card-meta">
            %academic-modes%
          </div>
          %workload%
          <div class="card-meta">
            %html-conflicts%
          </div>
          %timetables-divs%
        </div>
  ''';

  static const String academicTemplate = r'''
<div class='page'>
    <a name="academic_%academic_name_with_no_spaces%"></a>
    <h3>%academic_name% [<a href="mailto:%academic_email%@uclan.ac.uk">@%academic_email%</a>]</h3>
    <p><a href="#top">Back to top</a></p>
    %targets%
    %academic_timetables%
</div>''';

  static const String academicsListTemplate = r"""
<h2>%academics_list_name%</h2>
<table>
    <tr>
        <th style='min-width:200'>Name</th>
        <th>Qualification</th>
        <th>Email</th>
        <th>Allocated hours</th>
        <th>Target hours</th>
    </tr>
    %academics_rows%
</table>""";

  static const String academicsListTemplateNoTargetHours = r"""
<h2>%academics_list_name%</h2>
<table>
    <tr>
        <th style='min-width:200'>Name</th>
        <th>Qualification</th>
        <th>Email</th>
        <th>Allocated hours</th>
    </tr>
    %academics_rows%
</table>""";
}
