class Academic {
  final String email;
  final String name;
  final String role;
  final String qualifications;
  final String education;
  final String expertise;

  Academic({
    required this.email,
    required this.name,
    required this.role,
    required this.qualifications,
    required this.education,
    required this.expertise,
  });

  int get educationRank {
    return switch (qualifications) {
      'Professor' => 1,
      'Associate Professor' => 2,
      'Assistant Professor' => 3,
      'Lecturer' => 4,
      _ => 5,
    };
  }

  bool get isFaculty => role.toLowerCase() == 'faculty';

  @override
  String toString() {
    return 'Academic{'
        'email=\'$email\', '
        'name=\'$name\', '
        'role=\'$role\', '
        'qualifications=\'$qualifications\', '
        'education=\'$education\', '
        'expertise=\'$expertise\', '
        'faculty=$isFaculty'
        '}';
  }

  static int compare(Academic a1, Academic a2) {
    if (a1.isFaculty && !a2.isFaculty) {
      return -1;
    } else if (!a1.isFaculty && a2.isFaculty) {
      return 1;
    } else if (a1.isFaculty && a2.isFaculty) {
      if (a1.educationRank == a2.educationRank) {
        return a1.name.toLowerCase().compareTo(a2.name.toLowerCase());
      } else {
        return a1.educationRank - a2.educationRank;
      }
    } else {
      // none is faculty
      return a1.name.toLowerCase().compareTo(a2.name.toLowerCase());
    }
  }
}
