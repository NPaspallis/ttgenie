class StructureRow {
  final String programme;
  final String mode;
  final String moduleCode;
  final double facultyHours;
  final double associatesHours;

  StructureRow({
    required this.programme,
    required this.mode,
    required this.moduleCode,
    required this.facultyHours,
    required this.associatesHours,
  });

  @override
  String toString() {
    return 'StructureRow{programme: $programme, mode: $mode, moduleCode: $moduleCode, facultyHours: $facultyHours, associatesHours: $associatesHours}';
  }
}
