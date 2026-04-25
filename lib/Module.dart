class Module {
  final String num;
  final String mode;
  final String moduleCode;
  final String moduleName;
  final double ects;
  final double hours;
  final String notes;
  final double pct1;
  final String tutor1;
  final bool faculty1;
  final double hoursTutor1;
  final double pct2;
  final String tutor2;
  final bool faculty2;
  final double hoursTutor2;

  Module({
    required this.num,
    required this.mode,
    required this.moduleCode,
    required this.moduleName,
    required this.ects,
    required this.hours,
    required this.notes,
    required this.pct1,
    required this.tutor1,
    required this.faculty1,
    required this.hoursTutor1,
    required this.pct2,
    required this.tutor2,
    required this.faculty2,
    required this.hoursTutor2,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Module) return false;
    return other.mode == mode && other.moduleCode == moduleCode;
  }

  @override
  int get hashCode => Object.hash(mode, moduleCode);

  @override
  String toString() {
    return '$moduleCode${mode == 'DL' ? ' (DL)' : ''}';
  }
}
