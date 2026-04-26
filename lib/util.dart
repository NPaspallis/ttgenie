import 'module.dart';

class Util {

  static double getHours(final Module module, final String email) {
    if (module.tutor1 == email) {
      return module.hoursTutor1;
    } else if (module.tutor2 == email) {
      return module.hoursTutor2;
    } else {
      return 0.0;
    }
  }

  static Module? getModule(final Set<Module> allModules, final String moduleCode, final String mode) {
    for (Module module in allModules) {
      if (module.moduleCode == moduleCode && module.mode == mode) {
        return module;
      }
    }
    return null;
  }

}