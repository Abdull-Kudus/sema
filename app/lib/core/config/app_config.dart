/// App-wide constants. Anything a campus admin might want to change lives here
/// rather than inside widgets.
abstract final class AppConfig {
  static const appName = 'Sema';
  static const fullName = 'Sema · Campus Incident Reporting';
  static const tagline = 'Speak up. Fix campus.';
  static const institution = 'African Leadership University';

  static const studentDomain = 'alustudent.com';
  static const staffDomain = 'alueducation.com';
  static const allowedDomains = [studentDomain, staffDomain];

  static const maxPhotos = 3;
  static const photoMaxWidth = 1600;
  static const photoQuality = 78;

  static const titleMin = 5;
  static const titleMax = 80;
  static const descriptionMin = 15;
  static const descriptionMax = 1000;
  static const passwordMin = 8;

  static const feedLimit = 200;
  static const verifyPollInterval = Duration(seconds: 4);
  static const resendCooldown = Duration(seconds: 60);

  /// Areas of the ALU Rwanda campus, each with the spots a report can be
  /// narrowed to. Every area has its own washrooms.
  static const campusAreas = [
    CampusArea('Main Building', ['Reception', 'Learning Lab (Congo & Gabon)']),
    CampusArea('Staff Area', ['Staff Work Hive', 'Administration']),
    CampusArea('Leadership Centre', ['Eswatini']),
    CampusArea('Resource Centre', ['Gambia', 'Liberia & Benin', 'Guinea']),
    CampusArea('Learning Commons', ['KK']),
    CampusArea('Enterprise Commons', [
      'Learning Lab (Kenya, Burundi, Kilimanjaro)',
      'Algeria, Angola, Namibia',
      'Fab Lab',
    ]),
    CampusArea('Social Commons', [
      'Learning Lab (Algeria, Egypt, Morocco, Ethiopia)',
      'Food Court & Vendors',
      'South Sudan, Djibouti',
    ]),
    CampusArea('Collab Street', ['NN']),
    CampusArea('Campus Grounds', ['Main Gate', 'Parking', 'Outdoor Spaces'], washrooms: false),
  ];

  static CampusArea? areaNamed(String name) {
    for (final area in campusAreas) {
      if (area.name == name) return area;
    }
    return null;
  }
}

class CampusArea {
  const CampusArea(this.name, this._spots, {this.washrooms = true});

  final String name;
  final List<String> _spots;
  final bool washrooms;

  List<String> get spots => [..._spots, if (washrooms) 'Washrooms'];
}

abstract final class Collections {
  static const users = 'users';
  static const reports = 'reports';
  static const updates = 'updates';
  static const notifications = 'notifications';
}
