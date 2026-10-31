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

  /// Places on the ALU Rwanda campus a report can be pinned to.
  static const campusLocations = [
    'Main Building',
    'Library',
    'Cafeteria',
    'Student Residence',
    'Innovation Hub',
    'Lecture Rooms',
    'Sports Ground',
    'Administration Block',
    'Parking & Gate',
    'Washrooms',
    'Outdoor Areas',
  ];
}

abstract final class Collections {
  static const users = 'users';
  static const reports = 'reports';
  static const updates = 'updates';
  static const notifications = 'notifications';
}
