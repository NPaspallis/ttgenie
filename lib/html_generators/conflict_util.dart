import '../model/data_entry.dart';
import '../model/message.dart';
import '../model/timetable_view_entry.dart';

class ConflictUtil {

  // compare timetableEntries in pair to identify conflicts (overlapping in time)
  // when 'checkGroups' is set it considers different groups as non-conflicts (default is false)
  static List<Message> findConflicts(final List<TimetableEntry> timetableEntries, {final bool checkGroups = false}) {
    final List<Message> allMessages = [];
    // compare all in pairs
    for(int i=0; i<timetableEntries.length-1; i++) {
      for(int j=i+1; j<timetableEntries.length; j++) {
        // compare entries i and j
        final TimetableEntry te1 = timetableEntries[i];
        final TimetableEntry te2 = timetableEntries[j];
        if(te1.dayName != te2.dayName) continue; // different day, all good
        if(haveNoOverlapInSemesters(te1, te2)) continue; // no overlapping semesters, all good
        if(haveNoOverlapInTime(te1, te2)) continue; // no conflict in time, all good
        if(checkGroups) { // conflict in time, let's check for groups
          if(te1.groupName.isNotEmpty && te2.groupName.isNotEmpty && te1.groupName != te2.groupName) continue; // different groups so no conflict
        }
        allMessages.add(
            Message(MessageType.error, '${te1.moduleCode} / ${te2.moduleCode}',
                'Conflicting sessions:<div style="display: flex;"><div style="width: 200px;">${te1.toTooltipHTML()}</div>'
                    '<div style="width: 200px;">${te2.toTooltipHTML()}</div></div>', url: Message.noUrl));
      }
    }

    return allMessages;
  }

  static bool haveNoOverlapInTime(final TimetableEntry te1, final TimetableEntry te2) {
    final int startsMinutesFromMidnight1 = te1.startTime.hour * 60 + te1.startTime.minute;
    final int startsMinutesFromMidnight2 = te2.startTime.hour * 60 + te2.startTime.minute;
    final int endsMinutesFromMidnight1 = te1.endTime.hour * 60 + te1.endTime.minute;
    final int endsMinutesFromMidnight2 = te2.endTime.hour * 60 + te2.endTime.minute;

    return endsMinutesFromMidnight1 <= startsMinutesFromMidnight2 || endsMinutesFromMidnight2 <= startsMinutesFromMidnight1;
  }

  static bool haveNoOverlapInSemesters(final TimetableEntry te1, final TimetableEntry te2) {
    String delivery1 = te1.deliveryTypeName; // can be 'Semester 1', 'Semester 2', 'Semester 3', 'Full Year', or 'Semester 1 and Semester 2 and Semester 3'
    String delivery2 = te2.deliveryTypeName;
    if(delivery1 == 'Semester 1') return delivery2 == 'Semester 2' || delivery2 == 'Semester 3';
    if(delivery1 == 'Semester 2') return delivery2 == 'Semester 1' || delivery2 == 'Semester 3';
    if(delivery1 == 'Semester 3') return delivery2 == 'Full Year';
    if(delivery1 == 'Full Year') return delivery2 == 'Semester 3';
    return false; // always a conflict in case of 'Semester 1 and Semester 2 and Semester 3'
  }

  static List<Message> findMissingModules(TimetableViewEntry timetableViewEntry, List<TimetableEntry> timetableEntries) {
    final List<Message> allMessages = [];
    // find all covered modules
    final Set<String> coveredModuleCodes = {};
    for(TimetableEntry timetableEntry in timetableEntries) {
      coveredModuleCodes.add(timetableEntry.moduleCode);
    }

    final List<String> timetabledModuleCodes = timetableViewEntry.values;
    for(final String timetabledModuleCode in timetabledModuleCodes) {
      if(!coveredModuleCodes.contains(timetabledModuleCode)) {
        allMessages.add(Message(MessageType.warning, 'Missing $timetabledModuleCode',
          'No entries found for timetabled module: $timetabledModuleCode', url: Message.noUrl));
      }
    }

    return allMessages;
  }
}