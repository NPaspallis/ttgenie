import 'timetable_entry.dart';

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
}
