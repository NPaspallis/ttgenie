import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class TimetableEntry {
  static final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  static const int spanWidth = 80;

  final String recurrenceTypeName;
  final String periodName;
  final String dayName;
  final String moduleCode;
  final String moduleName;
  final DateTime startTime;
  final DateTime endTime;
  final String sessionTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final String deliveryTypeName;
  final String roomCode;
  final String lecturerEmail;
  final int expNoStudents;
  final String roomType;
  final String groupName;
  final String notes;

  TimetableEntry({
    required this.recurrenceTypeName,
    required this.periodName,
    required this.dayName,
    required this.moduleCode,
    required this.moduleName,
    required this.startTime,
    required this.endTime,
    required this.sessionTypeName,
    required this.startDate,
    required this.endDate,
    required this.deliveryTypeName,
    required this.roomCode,
    required this.lecturerEmail,
    required this.expNoStudents,
    required this.roomType,
    required this.groupName,
    required this.notes,
  });

  String get lecturerEmailId {
    final int indexOfAt = lecturerEmail.indexOf('@');
    return indexOfAt == -1 ? "unknown" : lecturerEmail.substring(0, indexOfAt);
  }

  // String get startTimeAsString => '${startTime.hour < 10 ? '0' : ''}${startTime.hour}:${startTime.minute < 10 ? '0' : ''}${startTime.minute}';
  // String get endTimeAsString => '${endTime.hour < 10 ? '0' : ''}${endTime.hour}:${endTime.minute < 10 ? '0' : ''}${endTime.minute}';
  // String get startDateAsString => '${startDate.year}-${startDate.month < 10 ? '0' : ''}${startDate.month}-${startDate.day < 10 ? '0' : ''}${startDate.day}';
  // String get endDateAsString => '${endDate.year}-${endDate.month < 10 ? '0' : ''}${endDate.month}-${endDate.day < 10 ? '0' : ''}${endDate.day}';
  String get startTimeAsString => DateFormat('HH:mm').format(startTime);
  String get endTimeAsString => DateFormat('HH:mm').format(endTime);
  String get startDateAsString => DateFormat('yyyy-MM-dd').format(startDate);
  String get endDateAsString => DateFormat('yyyy-MM-dd').format(endDate);


  String toTooltipHTML() { // todo refactor to a Util file
    // final String startTimeStr = DateFormat('HH:mm').format(startTime);
    // final String endTimeStr = DateFormat('HH:mm').format(endTime);
    final String startTimeStr = startTimeAsString;
    final String endTimeStr = endTimeAsString;

    return "<p>"
        "<h3>$moduleCode - $moduleName</h3>"
        "<span style='float:left; width:${spanWidth}px;'>Room:</span> ${roomCode.isEmpty ? "?" : roomCode}<br/>"
        "<span style='float:left; width:${spanWidth}px;'>Lecturer ID:</span> $lecturerEmail<br/>"
        "<span style='float:left; width:${spanWidth}px;'>Session:</span> $startTimeStr - $endTimeStr<br/>"
        "<span style='float:left; width:${spanWidth}px;'>Delivery:</span> $deliveryTypeName<br/>"
        "${notes.trim().isEmpty ? "" : "<span style='float:left; width:${spanWidth}px;'>Notes:</span> $notes<br/>"}"
        "</p>";
  }

  @override
  String toString() {
    return "$moduleCode[$startTimeAsString - $endTimeAsString]";
  }

  String toFullString() {
    return "TimetableEntryRow{"
        "recurrenceTypeName='$recurrenceTypeName', "
        "periodName='$periodName', "
        "dayName='$dayName', "
        "moduleCode='$moduleCode', "
        "moduleName='$moduleName', "
        "startTime=$startTimeAsString, "
        "endTime=$endTimeAsString, "
        "sessionTypeName='$sessionTypeName', "
        "startDate=$startDateAsString, "
        "endDate=$endDateAsString, "
        "deliveryTypeName='$deliveryTypeName', "
        "roomCode='$roomCode', "
        "lecturerEmail='$lecturerEmail', "
        "expNoStudents=$expNoStudents, "
        "roomType=$roomType, "
        "groupName='$groupName', "
        "notes='$notes'"
        "}";
  }
}
