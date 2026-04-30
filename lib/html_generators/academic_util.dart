import 'dart:collection';
import '../html_util.dart';
import '../model/academic.dart';
import '../model/data_entry.dart';
import 'timetable_util.dart';

class AcademicUtil {

  static String createAcademicTimetablesAsHtml(
      final Academic academic,
      List<TimetableEntry>? timetableEntries,
      final double targetHours) {

    return htmlPage.replaceAll("%html%", createAcademicTimetablesAsDiv(academic, timetableEntries, targetHours));
  }

  static String createAcademicTimetablesAsDiv(
      final Academic academic,
      List<TimetableEntry>? timetableEntries,
      final double targetHours) {
    
    final Map<String, double> deliveryTypeToTotalHours = {};

    String html = "<div>";

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

    html += "<p>Modules: $moduleCodes</p>\n";
    
    final List<String> sortedDeliveryTypes = deliveryTypeToTotalHours.keys.toList()..sort();
    
    html += "<p>Workload: </p><ul>\n";
    double totalHoursForAcademicYear = 0.0;
    
    for (final deliveryType in sortedDeliveryTypes) {
      final double totalHours = deliveryTypeToTotalHours[deliveryType] ?? 0.0;
      if (deliveryType.toLowerCase() == "full year") {
        html += "<li><i>$deliveryType</i>: $totalHours per week (${(totalHours * 30).toStringAsFixed(0)} in total)</li>\n";
        totalHoursForAcademicYear += totalHours * 30;
      } else if (deliveryType.toLowerCase() == "semester 1" || deliveryType.toLowerCase() == "semester 2") {
        html += "<li><i>$deliveryType</i>: $totalHours per week (${(totalHours * 15).toStringAsFixed(0)} in total)</li>\n";
        totalHoursForAcademicYear += totalHours * 15;
      } else if (deliveryType.toLowerCase() == "semester 3") {
        html += "<li><i>$deliveryType</i>: $totalHours per week (${(totalHours * 10).toStringAsFixed(0)} in total)</li>\n";
        totalHoursForAcademicYear += totalHours * 10;
      } else {
        print("Invalid deliveryType: $deliveryType");
      }
    }
    
    html += "<li><b>Total hours per week: ${(totalHoursForAcademicYear / 30.0).toStringAsFixed(2)} (${totalHoursForAcademicYear.toStringAsFixed(0)} hours over the academic year)</b></li>\n";
    html += "<br>\n";
    
    if (academic.isFaculty) {
      double academicTarget = targetHours; 
      
      if ((totalHoursForAcademicYear / 30.0).toStringAsFixed(2) == academicTarget.toStringAsFixed(2)) {
        html += "<li style='color: green'>Target hours: ${academicTarget.toStringAsFixed(2)} OK!</li>\n";
      } else {
        final double difference = (totalHoursForAcademicYear / 30.0) - academicTarget;
        html += "<li style='color: red'>Target hours: ${academicTarget.toStringAsFixed(2)} (difference: ${difference > 0 ? "+" : ""}${difference.toStringAsFixed(2)})</li>\n";
      }
    }
    html += "</ul>\n";

    html += "<p><b>Timetables</b> (Full Year: ${fullYearTimetableEntries.isNotEmpty ? "Yes" : "No"}, Sem 1: ${sem1 ? "Yes" : "No"}, Sem 2: ${sem2 ? "Yes" : "No"}, Sem 3: ${sem3 ? "Yes" : "No"})</p>";

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
      htmlModuleCodes += '  <span class="badge">$moduleCode</span>\n';
    }
    htmlModuleCodes += '</div>\n\n';

    return academicDivTemplate
        .replaceAll('%academic-id%', HtmlUtil.replaceSpaces(academic.name))
        .replaceAll('%academic-initials%', getInitials(academic.name))
        .replaceAll('%academic-type%', 'tbc')//todo
        .replaceAll('%academic-name%', academic.name)
        .replaceAll('%timetables-divs%', html)
        .replaceAll('%module-divs%', htmlModuleCodes);
  }

  static String getInitials(String name) {
    if(name.length < 2) return '??';
    final int indexOfFirstSpace = name.indexOf(' ');
    final String firstName = name.substring(0, indexOfFirstSpace);
    final String lastName = name.substring(indexOfFirstSpace+1);
    return firstName[0] + lastName[0];
  }

  // must replace:
  // - %academic-id%
  // - %academic-initials%
  // - %academic-type% Faculty | Special Teaching Staff
  // - %academic-name%
  // - %timetables-divs%
  static const String academicDivTemplate = r'''
        <div class="card academic" id="#academic-%academic-id%">
          <div class="card-avatar">%academic-initials%</div>
          <span class="card-tag">%academic-type%</span>
          <h3>%academic-name%</h3>
          %timetables-divs%
          %module-divs%
        </div>
  ''';

  static const String academicTemplate = r"""
<div class='page'>
    <a name="academic_%academic_name_with_no_spaces%"></a>
    <h3>%academic_name% [<a href="mailto:%academic_email%@uclan.ac.uk">@%academic_email%</a>]</h3>
    <p><a href="#top">Back to top</a></p>
    %targets%
    %academic_timetables%
</div>""";

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

  static const String htmlPage = r"""
<html lang="en">

<head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      padding: 5px;
    }
    td {
      min-width: 100px;
    }
    tr {
      page_break_inside: avoid;
    }
    
    /* Tooltip container */
    .tooltip {
      position: relative;
      display: inline-block;
      border-bottom: 1px dotted black; /* If you want dots under the hoverable text */
    }
    
    /* Tooltip text */
    .tooltip .tooltiptext {
      visibility: hidden;
      width: 300px;
      background-color: black;
      color: #fff;
      text-align: left;
      padding: 10px;
      border-radius: 6px;
    
      /* Position the tooltip text - see examples below! */
      position: absolute;
      z-index: 1;
    }
    
    /* Show the tooltip text when you mouse over the tooltip container */
    .tooltip:hover .tooltiptext {
      visibility: visible;
    }
    
    @media print {
        .page, .page-break { break-after: page; }
    }
    </style>

</head>

<body>

<div style='display:none;'>
    <svg id='external-link' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512'><path d='M320 0c-17.7 0-32 14.3-32 32s14.3 32 32 32l82.7 0L201.4 265.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L448 109.3l0 82.7c0 17.7 14.3 32 32 32s32-14.3 32-32l0-160c0-17.7-14.3-32-32-32L320 0zM80 32C35.8 32 0 67.8 0 112L0 432c0 44.2 35.8 80 80 80l320 0c44.2 0 80-35.8 80-80l0-112c0-17.7-14.3-32-32-32s-32 14.3-32 32l0 112c0 8.8-7.2 16-16 16L80 448c-8.8 0-16-7.2-16-16l0-320c0-8.8 7.2-16 16-16l112 0c17.7 0 32-14.3 32-32s-14.3-32-32-32L80 32z'/></svg>
    <svg id='calendar-days' xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path d="M128 0c17.7 0 32 14.3 32 32l0 32 128 0 0-32c0-17.7 14.3-32 32-32s32 14.3 32 32l0 32 48 0c26.5 0 48 21.5 48 48l0 48L0 160l0-48C0 85.5 21.5 64 48 64l48 0 0-32c0-17.7 14.3-32 32-32zM0 192l448 0 0 272c0 26.5-21.5 48-48 48L48 512c-26.5 0-48-21.5-48-48L0 192zm64 80l0 32c0 8.8 7.2 16 16 16l32 0c8.8 0 16-7.2 16-16l0-32c0-8.8-7.2-16-16-16l-32 0c-8.8 0-16 7.2-16 16zm128 0l0 32c0 8.8 7.2 16 16 16l32 0c8.8 0 16-7.2 16-16l0-32c0-8.8-7.2-16-16-16l-32 0c-8.8 0-16 7.2-16 16zm144-16c-8.8 0-16 7.2-16 16l0 32c0 8.8 7.2 16 16 16l32 0c8.8 0 16-7.2 16-16l0-32c0-8.8-7.2-16-16-16l-32 0zM64 400l0 32c0 8.8 7.2 16 16 16l32 0c8.8 0 16-7.2 16-16l0-32c0-8.8-7.2-16-16-16l-32 0c-8.8 0-16 7.2-16 16zm144-16c-8.8 0-16 7.2-16 16l0 32c0 8.8 7.2 16 16 16l32 0c8.8 0 16-7.2 16-16l0-32c0-8.8-7.2-16-16-16l-32 0zm112 16l0 32c0 8.8 7.2 16 16 16l32 0c8.8 0 16-7.2 16-16l0-32c0-8.8-7.2-16-16-16l-32 0c-8.8 0-16 7.2-16 16z"/></svg>
    <svg id='computer'      xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512"><path d="M384 96l0 224L64 320 64 96l320 0zM64 32C28.7 32 0 60.7 0 96L0 320c0 35.3 28.7 64 64 64l117.3 0-10.7 32L96 416c-17.7 0-32 14.3-32 32s14.3 32 32 32l256 0c17.7 0 32-14.3 32-32s-14.3-32-32-32l-74.7 0-10.7-32L384 384c35.3 0 64-28.7 64-64l0-224c0-35.3-28.7-64-64-64L64 32zm464 0c-26.5 0-48 21.5-48 48l0 352c0 26.5 21.5 48 48 48l64 0c26.5 0 48-21.5 48-48l0-352c0-26.5-21.5-48-48-48l-64 0zm16 64l32 0c8.8 0 16 7.2 16 16s-7.2 16-16 16l-32 0c-8.8 0-16-7.2-16-16s7.2-16 16-16zm-16 80c0-8.8 7.2-16 16-16l32 0c8.8 0 16 7.2 16 16s-7.2 16-16 16l-32 0c-8.8 0-16-7.2-16-16zm32 160a32 32 0 1 1 0 64 32 32 0 1 1 0-64z"/></svg>
    <svg id='globe'         xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path d="M352 256c0 22.2-1.2 43.6-3.3 64l-185.3 0c-2.2-20.4-3.3-41.8-3.3-64s1.2-43.6 3.3-64l185.3 0c2.2 20.4 3.3 41.8 3.3 64zm28.8-64l123.1 0c5.3 20.5 8.1 41.9 8.1 64s-2.8 43.5-8.1 64l-123.1 0c2.1-20.6 3.2-42 3.2-64s-1.1-43.4-3.2-64zm112.6-32l-116.7 0c-10-63.9-29.8-117.4-55.3-151.6c78.3 20.7 142 77.5 171.9 151.6zm-149.1 0l-176.6 0c6.1-36.4 15.5-68.6 27-94.7c10.5-23.6 22.2-40.7 33.5-51.5C239.4 3.2 248.7 0 256 0s16.6 3.2 27.8 13.8c11.3 10.8 23 27.9 33.5 51.5c11.6 26 20.9 58.2 27 94.7zm-209 0L18.6 160C48.6 85.9 112.2 29.1 190.6 8.4C165.1 42.6 145.3 96.1 135.3 160zM8.1 192l123.1 0c-2.1 20.6-3.2 42-3.2 64s1.1 43.4 3.2 64L8.1 320C2.8 299.5 0 278.1 0 256s2.8-43.5 8.1-64zM194.7 446.6c-11.6-26-20.9-58.2-27-94.6l176.6 0c-6.1 36.4-15.5 68.6-27 94.6c-10.5 23.6-22.2 40.7-33.5 51.5C272.6 508.8 263.3 512 256 512s-16.6-3.2-27.8-13.8c-11.3-10.8-23-27.9-33.5-51.5zM135.3 352c10 63.9 29.8 117.4 55.3 151.6C112.2 482.9 48.6 426.1 18.6 352l116.7 0zm358.1 0c-30 74.1-93.6 130.9-171.9 151.6c25.5-34.2 45.2-87.7 55.3-151.6l116.7 0z"/></svg>
</div>

<div class='page'>
    <h1>Academics</h1>
    <a name="top"></a>
    
    <h2>Faculty</h2>
    <a name="faculty"/>
    
    %faculty_list%
    
    <h2>Associates (Special Teaching Staff)</h2>
    <a name="associates"/>
    
    %associates_list%
    
    <hr>
</div>

%html%

</body>
</html>""";
}
