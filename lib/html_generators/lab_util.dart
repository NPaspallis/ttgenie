import '../model/data_entry.dart';

class LabUtil {
  static String createLabTimetablesAsHtml(final String labId, List<TimetableEntry>? timetableEntries) {

    return 'todo'; // todo
  }

  String template = r'''
          <div class="card lab" id="lab-1">
          <div class="lab-icon">🖥️</div>
          <span class="card-tag">Research Lab</span>
          <h3>Lab 1 — Computing Lab</h3>
          <p>A state-of-the-art computing laboratory equipped with high-performance workstations, GPU clusters, and a dedicated development environment for software engineering and AI research projects.</p>
          <div class="card-meta">
            <span class="badge">40 Workstations</span>
            <span class="badge">GPU Cluster</span>
          </div>
        </div>
  ''';
}