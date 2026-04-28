import 'package:ttgenie/timetable_view.dart';

import '../html_util.dart';
import '../model/data_entry.dart';
import 'package:intl/intl.dart';

import '../model/timetable_view_entry.dart';

class TimetableUtil {
  static const int lunchStartHour = 11;
  static const int lunchEndHour = 15;

  static String getTimetableFromTimetableEntriesAsHtml(
      final String title, List<TimetableEntry> selectedTimetableEntries) {
    
    String html = "<h3>$title</h3>";

    if (selectedTimetableEntries.isEmpty) {
      html += "<p style='font-style: italic;'>No Entries</p>";
      return html;
    }

    // check if any of the entries starts or ends at a :30 point
    bool halfHourSteps = false;
    for (var entry in selectedTimetableEntries) {
      if (entry.startTime.minute == 30 || entry.endTime.minute == 30) {
        halfHourSteps = true;
        break;
      }
    }
    final int stepPeriod = halfHourSteps ? HtmlUtil.stepInMinsHalfHour : HtmlUtil.stepInMinsFullHour;

    // compute the min and max timeslot
    // DateTime minStartTime = selectedTimetableEntries[0].startTime;
    DateTime minStartTime = DateTime(2026, 1, 1, selectedTimetableEntries[0].startTime.hour, selectedTimetableEntries[0].startTime.minute);
    // DateTime maxEndTime = selectedTimetableEntries[0].endTime;
    DateTime maxEndTime = DateTime(2026, 1, 1, selectedTimetableEntries[0].endTime.hour, selectedTimetableEntries[0].endTime.minute);
    for (final entry in selectedTimetableEntries) {
      if (entry.startTime.isBefore(minStartTime)) minStartTime = entry.startTime;
      if (entry.endTime.isAfter(maxEndTime)) maxEndTime = entry.endTime;
    }

    // initiate the data structures
    final Map<DateTime, Map<String, List<TimetableEntry>>> timeToDayToModuleCodes = {};
    for (DateTime ldt = minStartTime;
        ldt.isBefore(maxEndTime);
        ldt = ldt.add(Duration(minutes: stepPeriod))) {
      final Map<String, List<TimetableEntry>> dayToTimetableEntries = {};
      for (String day in HtmlUtil.weekdays) {
        dayToTimetableEntries[day] = [];
      }
      timeToDayToModuleCodes[ldt] = dayToTimetableEntries;
    }

    // loop through all entries and update data structures
    for (final entry in selectedTimetableEntries) {
      final String day = entry.dayName;
      for (DateTime ldt = entry.startTime;
          ldt.isBefore(entry.endTime);
          ldt = ldt.add(Duration(minutes: stepPeriod))) {
        timeToDayToModuleCodes[ldt]?[day]?.add(entry);
      }
    }

    // initiate max concurrent sessions map
    final Map<String, int> dayToMaxConcurrentSessions = {};
    for (String day in HtmlUtil.weekdays) {
      dayToMaxConcurrentSessions[day] = 1;
      for (DateTime ldt = minStartTime;
          ldt.isBefore(maxEndTime);
          ldt = ldt.add(Duration(minutes: stepPeriod))) {
        int numOfConcurrentSessions = timeToDayToModuleCodes[ldt]?[day]?.length ?? 0;
        if (numOfConcurrentSessions > dayToMaxConcurrentSessions[day]!) {
          dayToMaxConcurrentSessions[day] = numOfConcurrentSessions;
        }
      }
    }

    // create the header row
    html += "<tr><th><i>Time</i></th>";
    for (String day in HtmlUtil.weekdays) {
      int colspan = (dayToMaxConcurrentSessions[day] ?? 1).clamp(1, 100);
      html += "<th colspan='$colspan' style='min-width:150px;'>$day</th>";
    }
    html += "</tr>";

    // initiate skip map
    final Map<DateTime, Map<String, int>> timeToDayToSkips = {};
    for (DateTime ldt = minStartTime;
        ldt.isBefore(maxEndTime);
        ldt = ldt.add(Duration(minutes: stepPeriod))) {
      final Map<String, int> dayToSkips = {};
      for (String day in HtmlUtil.weekdays) {
        dayToSkips[day] = 1;
      }
      timeToDayToSkips[ldt] = dayToSkips;
    }

    final DateFormat timeFormat = DateFormat('HH:mm');

    for (DateTime currentStartTime = minStartTime;
        currentStartTime.isBefore(maxEndTime);
        currentStartTime = currentStartTime.add(Duration(minutes: stepPeriod))) {
      
      final bool lunchTime = currentStartTime.hour > lunchStartHour && currentStartTime.hour < lunchEndHour;
      final Map<String, List<TimetableEntry>>? dayToModuleCodes = timeToDayToModuleCodes[currentStartTime];
      String rowHtml = "<tr>";

      String timeRange = "${timeFormat.format(currentStartTime)} - ${timeFormat.format(currentStartTime.add(Duration(minutes: stepPeriod)))}";
      rowHtml += lunchTime ? "<td bgcolor='#ffffc0'><i>$timeRange</i></td>" : "<td><i>$timeRange</i></td>";

      for (String day in HtmlUtil.weekdays) {
        final List<TimetableEntry> entries = dayToModuleCodes?[day] ?? [];
        final int maxConcurrentSessions = dayToMaxConcurrentSessions[day] ?? 1;
        
        for (var entry in entries) {
          if (entry.startTime == currentStartTime) {
            int totalNumOfTimeslots = entry.endTime.difference(entry.startTime).inMinutes ~/ stepPeriod;
            
            for (DateTime ldt = entry.startTime;
                ldt.isBefore(entry.endTime);
                ldt = ldt.add(Duration(minutes: stepPeriod))) {
              int currentSkips = timeToDayToSkips[ldt]?[day] ?? 1;
              timeToDayToSkips[ldt]?[day] = currentSkips + 1;
            }
            rowHtml += "<td bgcolor='#f0f0f0' rowspan='$totalNumOfTimeslots'>${HtmlUtil.getModuleAsHtml(entry)}</td>";
          }
        }

        // draw empty cells
        final int skips = timeToDayToSkips[currentStartTime]?[day] ?? 1;
        for (int i = 0; i < maxConcurrentSessions - skips + 1; i++) {
          rowHtml += lunchTime ? "<td bgcolor='#ffffc0'></td>" : "<td></td>";
        }
      }
      rowHtml += "</tr>";
      html += rowHtml;
    }

    return "<table>$html</table>";
  }

  static String getTimetableFromModulesTimetableViewEntryAsHtml(
      final String title, TimetableViewEntry selectedTimetableViewEntry) {
    final List<String> selectedModuleCodes = selectedTimetableViewEntry.values;
    List<TimetableEntry> selectedTimetableEntries = [];
    //todo

    return getTimetableFromTimetableEntriesAsHtml(title, selectedTimetableEntries);
  }
}
