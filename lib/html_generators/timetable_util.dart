import '../html_util.dart';
import '../model/data_entry.dart';
import 'package:intl/intl.dart';

class TimetableUtil {
  static const int lunchStartHour = 11;
  static const int lunchEndHour = 15;

  static String getTimetableFromTimetableEntriesAsHtml(
      final String title, List<TimetableEntry> selectedTimetableEntries) {

    if (selectedTimetableEntries.isEmpty) {
      return "<div><h3>$title</h3><p style='font-style: italic;'>No Entries</p></div>";
    }

    String html = '<h3>$title</h3>';

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
    final Map<String, Map<String,int>> dayToModuleCodeToColumn = {};
    for (String day in HtmlUtil.weekdays) {
      dayToMaxConcurrentSessions[day] = 1;
      dayToModuleCodeToColumn[day] = {};
      for (DateTime ldt = minStartTime;
          ldt.isBefore(maxEndTime);
          ldt = ldt.add(Duration(minutes: stepPeriod))) {
        int numOfConcurrentSessions = timeToDayToModuleCodes[ldt]?[day]?.length ?? 0;
        if (numOfConcurrentSessions > dayToMaxConcurrentSessions[day]!) {
          dayToMaxConcurrentSessions[day] = numOfConcurrentSessions;
          final List<TimetableEntry> concurrentTimetableEntries = timeToDayToModuleCodes[ldt]![day]!;
          for(int i=0; i<concurrentTimetableEntries.length; i++) {
            dayToModuleCodeToColumn[day]![concurrentTimetableEntries[i].moduleCode] = i;
          }
        }
      }
    }

    // create the header row
    html += "<tr><th><i>Time</i></th>";
    for (String day in HtmlUtil.weekdays) {
      html += "<th colspan='${dayToMaxConcurrentSessions[day]!}' style='min-width:150px;'>$day</th>";
    }
    html += "</tr>";

    // initiate vertical skip map
    final Map<DateTime, Map<String, int>> timeToDayToVerticalSkips = {};
    for (DateTime ldt = minStartTime;
        ldt.isBefore(maxEndTime);
        ldt = ldt.add(Duration(minutes: stepPeriod))) {
      final Map<String, int> dayToVerticalSkips = {};
      for (String day in HtmlUtil.weekdays) {
        dayToVerticalSkips[day] = 1;
      }
      timeToDayToVerticalSkips[ldt] = dayToVerticalSkips;
    }

    final DateFormat timeFormat = DateFormat('HH:mm');

    for (DateTime currentStartTime = minStartTime;
        currentStartTime.isBefore(maxEndTime);
        currentStartTime = currentStartTime.add(Duration(minutes: stepPeriod))) {
      
      final bool lunchTime = currentStartTime.hour > lunchStartHour && currentStartTime.hour < lunchEndHour;
      final Map<String, List<TimetableEntry>>? dayToModuleCodes = timeToDayToModuleCodes[currentStartTime];
      String rowHtml = "<tr>";

      final String timeRange = "${timeFormat.format(currentStartTime)} - ${timeFormat.format(currentStartTime.add(Duration(minutes: stepPeriod)))}";
      rowHtml += lunchTime ? "<td bgcolor='#ffffc0'><i>$timeRange</i></td>" : "<td><i>$timeRange</i></td>";

      for (String day in HtmlUtil.weekdays) {
        final List<TimetableEntry> entries = dayToModuleCodes?[day] ?? [];
        final int maxConcurrentSessions = dayToMaxConcurrentSessions[day] ?? 1;

        for (var entry in entries) {
          if (entry.startTime == currentStartTime) {
            int totalNumOfVerticalTimeslots = entry.endTime.difference(entry.startTime).inMinutes ~/ stepPeriod;
            // compute vertical skips
            for (DateTime ldt = entry.startTime;
                ldt.isBefore(entry.endTime);
                ldt = ldt.add(Duration(minutes: stepPeriod))) {
              int currentSkips = timeToDayToVerticalSkips[ldt]?[day] ?? 1;
              timeToDayToVerticalSkips[ldt]?[day] = currentSkips + 1;
            }
            final String sessionType = entry.sessionTypeName.toLowerCase();
            rowHtml += "<td class='$sessionType' bgcolor='#f0f0f0' rowspan='$totalNumOfVerticalTimeslots'>${HtmlUtil.getModuleAsHtml(entry)}</td>";
          }
        }

        // draw empty cells
        final int skips = timeToDayToVerticalSkips[currentStartTime]?[day] ?? 1;
        for (int i = 0; i < maxConcurrentSessions - skips + 1; i++) {
          rowHtml += lunchTime ? '<td bgcolor="#ffffc0"></td>' : '<td></td>';
        }
      }
      rowHtml += "</tr>";
      html += rowHtml;
    }

    return '<table>$html</table>';
  }
}
