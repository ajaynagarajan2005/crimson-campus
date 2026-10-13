import 'package:flutter/material.dart';

import '../routes.dart';
import '../utils/format.dart';
import 'campus_info.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class ClassSession {
  const ClassSession({
    required this.code,
    required this.title,
    required this.weekday,
    required this.start,
    required this.end,
    required this.room,
    required this.lecturer,
    this.isLab = false,
  });

  final String code, title, room, lecturer;
  final int weekday;
  final TimeOfDay start, end;
  final bool isLab;

  int get startMinutes => start.hour * 60 + start.minute;
}

class CourseResult {
  const CourseResult(this.code, this.title, this.credits, this.grade, this.points);

  final String code, title, grade;
  final int credits;
  final double points;
}

class CourseAttendance {
  const CourseAttendance(this.code, this.title, this.attended, this.total);

  final String code, title;
  final int attended, total;

  double get ratio => attended / total;
}

class FeeItem {
  const FeeItem(this.title, this.amount, this.due, {this.paid = false});

  final String title, due;
  final int amount;
  final bool paid;
}

class LibraryBook {
  const LibraryBook(this.id, this.title, this.author, this.due, {this.dueSoon = false});

  final String id, title, author, due;
  final bool dueSoon;
}

/// A campus shuttle line. Stops refer to [campusPlaces] ids (real
/// OpenStreetMap locations); the timetable itself is sample data.
class ShuttleRoute {
  const ShuttleRoute({
    required this.id,
    required this.name,
    required this.stopIds,
    required this.firstDeparture,
    required this.lastDeparture,
    required this.everyMinutes,
    required this.status,
    required this.tone,
    this.minutesBetweenStops = 3,
  });

  final String id, name, status;
  final List<String> stopIds;
  final TimeOfDay firstDeparture, lastDeparture;
  final int everyMinutes;
  final int minutesBetweenStops;
  final BadgeTone tone;

  List<CampusPlace> get stops =>
      [for (final id in stopIds) campusPlaces.firstWhere((p) => p.id == id)];

  String get path => '${stops.first.name} – ${stops.last.name}';

  String get frequency =>
      'Every $everyMinutes min · ${formatTime(firstDeparture)} – ${formatTime(lastDeparture)}';

  int get _first => firstDeparture.hour * 60 + firstDeparture.minute;
  int get _last => lastDeparture.hour * 60 + lastDeparture.minute;

  /// Upcoming departures from the first stop, today.
  List<TimeOfDay> departuresAfter(DateTime now, {int count = 6}) {
    final nowMinutes = now.hour * 60 + now.minute;
    final result = <TimeOfDay>[];
    for (var t = _first; t <= _last && result.length < count; t += everyMinutes) {
      if (t >= nowMinutes) result.add(TimeOfDay(hour: t ~/ 60, minute: t % 60));
    }
    return result;
  }

  String nextDepartureLabel([DateTime? now]) {
    final next = departuresAfter(now ?? DateTime.now(), count: 1);
    return next.isEmpty ? 'Tomorrow ${formatTime(firstDeparture)}' : formatTime(next.first);
  }

  String get nextDeparture => nextDepartureLabel();
}

class Club {
  const Club({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.members,
    required this.meets,
    required this.description,
  });

  final String id, name, category, meets, description;
  final IconData icon;
  final int members;
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.deadline,
    required this.badge,
    required this.tone,
    required this.icon,
  });

  final String id, title, message, date, deadline, badge;
  final BadgeTone tone;
  final IconData icon;
}

class CampusEvent {
  const CampusEvent({
    required this.id,
    required this.title,
    required this.day,
    required this.month,
    required this.weekday,
    required this.time,
    required this.venue,
    required this.category,
    required this.description,
    required this.icon,
    required this.capacity,
    required this.registered,
  });

  final String id, title, day, month, weekday, time, venue, category, description;
  final IconData icon;
  final int capacity, registered;
}

class CampusService {
  const CampusService(this.label, this.icon, this.route, {this.badge, this.tone = BadgeTone.light});

  final String label, route;
  final IconData icon;
  final String? badge;
  final BadgeTone tone;
}

// ---------------------------------------------------------------------------
// Sample data (fictional)
// ---------------------------------------------------------------------------

const String appName = 'Crimson Campus';
const String universityName = 'INTI International University';

const List<CampusService> campusServices = [
  CampusService('Timetable', Icons.calendar_month_rounded, AppRoutes.timetable),
  CampusService('Results', Icons.emoji_events_rounded, AppRoutes.results, badge: 'New', tone: BadgeTone.success),
  CampusService('Attendance', Icons.fact_check_rounded, AppRoutes.attendance),
  CampusService('Fees', Icons.account_balance_wallet_rounded, AppRoutes.fees, badge: 'Due', tone: BadgeTone.warning),
  CampusService('Library', Icons.local_library_rounded, AppRoutes.library),
  CampusService('Shuttle', Icons.directions_bus_rounded, AppRoutes.shuttle, badge: 'Live', tone: BadgeTone.success),
  CampusService('Clubs', Icons.groups_rounded, AppRoutes.clubs),
  CampusService('Helpdesk', Icons.support_agent_rounded, AppRoutes.helpdesk),
];

const List<ClassSession> timetable = [
  // Monday
  ClassSession(code: 'CS301', title: 'Data Structures', weekday: 1, start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 10, minute: 0), room: 'Block C-204', lecturer: 'Dr. Ravi Kumar'),
  ClassSession(code: 'CS305', title: 'Operating Systems', weekday: 1, start: TimeOfDay(hour: 11, minute: 0), end: TimeOfDay(hour: 12, minute: 0), room: 'Block C-110', lecturer: 'Prof. Meera Pillai'),
  ClassSession(code: 'MA301', title: 'Probability & Statistics', weekday: 1, start: TimeOfDay(hour: 14, minute: 0), end: TimeOfDay(hour: 15, minute: 0), room: 'Block A-302', lecturer: 'Dr. Sanjay Rao'),
  // Tuesday
  ClassSession(code: 'CS307', title: 'Computer Networks', weekday: 2, start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 10, minute: 0), room: 'Block C-204', lecturer: 'Dr. Anita Joseph'),
  ClassSession(code: 'CS391', title: 'Operating Systems Lab', weekday: 2, start: TimeOfDay(hour: 13, minute: 0), end: TimeOfDay(hour: 15, minute: 0), room: 'Computing Lab 3', lecturer: 'Prof. Meera Pillai', isLab: true),
  // Wednesday
  ClassSession(code: 'CS301', title: 'Data Structures', weekday: 3, start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 10, minute: 0), room: 'Block C-204', lecturer: 'Dr. Ravi Kumar'),
  ClassSession(code: 'CS309', title: 'Database Management Systems', weekday: 3, start: TimeOfDay(hour: 10, minute: 30), end: TimeOfDay(hour: 11, minute: 30), room: 'Block B-105', lecturer: 'Dr. Farah Siddiqui'),
  ClassSession(code: 'HS301', title: 'Professional Ethics', weekday: 3, start: TimeOfDay(hour: 15, minute: 0), end: TimeOfDay(hour: 16, minute: 0), room: 'Seminar Hall 1', lecturer: 'Ms. Leena Thomas'),
  // Thursday
  ClassSession(code: 'CS307', title: 'Computer Networks', weekday: 4, start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 10, minute: 0), room: 'Block C-204', lecturer: 'Dr. Anita Joseph'),
  ClassSession(code: 'CS393', title: 'Database Lab', weekday: 4, start: TimeOfDay(hour: 13, minute: 0), end: TimeOfDay(hour: 15, minute: 0), room: 'Computing Lab 2', lecturer: 'Dr. Farah Siddiqui', isLab: true),
  // Friday
  ClassSession(code: 'CS305', title: 'Operating Systems', weekday: 5, start: TimeOfDay(hour: 10, minute: 0), end: TimeOfDay(hour: 11, minute: 0), room: 'Block C-110', lecturer: 'Prof. Meera Pillai'),
  ClassSession(code: 'MA301', title: 'Probability & Statistics', weekday: 5, start: TimeOfDay(hour: 12, minute: 0), end: TimeOfDay(hour: 13, minute: 0), room: 'Block A-302', lecturer: 'Dr. Sanjay Rao'),
  ClassSession(code: 'CS309', title: 'Database Management Systems', weekday: 5, start: TimeOfDay(hour: 14, minute: 0), end: TimeOfDay(hour: 15, minute: 0), room: 'Block B-105', lecturer: 'Dr. Farah Siddiqui'),
];

List<ClassSession> classesFor(int weekday) =>
    timetable.where((s) => s.weekday == weekday).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

/// The next class from [now], with a friendly "Today / Tomorrow / Monday" label.
({ClassSession session, String when})? nextClass([DateTime? now]) {
  final time = now ?? DateTime.now();
  final minutes = time.hour * 60 + time.minute;
  for (var offset = 0; offset < 7; offset++) {
    final day = ((time.weekday - 1 + offset) % 7) + 1;
    for (final session in classesFor(day)) {
      if (offset > 0 || session.startMinutes > minutes) {
        const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final when = offset == 0 ? 'Today' : (offset == 1 ? 'Tomorrow' : names[day]);
        return (session: session, when: when);
      }
    }
  }
  return null;
}

/// GPA per completed semester (average = CGPA 3.72).
const List<double> gpaHistory = [3.58, 3.70, 3.74, 3.86];

/// Semester 4 results (GPA 3.86).
const List<CourseResult> latestResults = [
  CourseResult('CS202', 'Design & Analysis of Algorithms', 4, 'A', 4.0),
  CourseResult('CS204', 'Computer Organisation', 4, 'A-', 3.7),
  CourseResult('CS206', 'Software Engineering', 3, 'A', 4.0),
  CourseResult('MA202', 'Discrete Mathematics', 4, 'A-', 3.7),
  CourseResult('HS202', 'Technical Communication', 2, 'A', 4.0),
];

const List<CourseAttendance> attendanceRecords = [
  CourseAttendance('CS301', 'Data Structures', 28, 30),
  CourseAttendance('CS305', 'Operating Systems', 26, 29),
  CourseAttendance('CS307', 'Computer Networks', 25, 28),
  CourseAttendance('CS309', 'Database Management Systems', 27, 29),
  CourseAttendance('MA301', 'Probability & Statistics', 20, 28),
  CourseAttendance('HS301', 'Professional Ethics', 13, 14),
];

double get overallAttendance {
  final attended = attendanceRecords.fold<int>(0, (sum, r) => sum + r.attended);
  final total = attendanceRecords.fold<int>(0, (sum, r) => sum + r.total);
  return attended / total;
}

const List<FeeItem> feeItems = [
  FeeItem('Tuition fee · Semester 5', 85000, 'Paid on 28 Jul 2026', paid: true),
  FeeItem('Hostel & mess · Oct–Dec', 42000, 'Due 20 Oct 2026'),
  FeeItem('End-semester exam fee', 2500, 'Due 25 Oct 2026'),
  FeeItem('Library late fine', 150, 'Paid on 02 Sep 2026', paid: true),
];

const List<LibraryBook> borrowedBooks = [
  LibraryBook('osc', 'Operating System Concepts', 'Silberschatz, Galvin & Gagne', 'Due 12 Oct 2026', dueSoon: true),
  LibraryBook('cn', 'Computer Networking: A Top-Down Approach', 'Kurose & Ross', 'Due 22 Oct 2026'),
  LibraryBook('cc', 'Clean Code', 'Robert C. Martin', 'Due 30 Oct 2026'),
];

const List<ShuttleRoute> shuttleRoutes = [
  ShuttleRoute(
    id: 'a',
    name: 'Line A',
    stopIds: ['north-gate', 'main', 'block-d', 'block-a'],
    firstDeparture: TimeOfDay(hour: 7, minute: 30),
    lastDeparture: TimeOfDay(hour: 19, minute: 30),
    everyMinutes: 15,
    status: 'On time',
    tone: BadgeTone.success,
  ),
  ShuttleRoute(
    id: 'b',
    name: 'Line B',
    stopIds: ['lincoln', 'hall', 'main'],
    firstDeparture: TimeOfDay(hour: 7, minute: 0),
    lastDeparture: TimeOfDay(hour: 21, minute: 0),
    everyMinutes: 20,
    status: 'Delayed 5 min',
    tone: BadgeTone.warning,
    minutesBetweenStops: 4,
  ),
  ShuttleRoute(
    id: 'c',
    name: 'Line C',
    stopIds: ['main', 'south-gate', 'bus', 'melati'],
    firstDeparture: TimeOfDay(hour: 6, minute: 30),
    lastDeparture: TimeOfDay(hour: 22, minute: 0),
    everyMinutes: 30,
    status: 'On time',
    tone: BadgeTone.success,
  ),
  ShuttleRoute(
    id: 'n',
    name: 'Night Line',
    stopIds: ['main', 'hall', 'lincoln'],
    firstDeparture: TimeOfDay(hour: 21, minute: 0),
    lastDeparture: TimeOfDay(hour: 23, minute: 30),
    everyMinutes: 30,
    status: 'Scheduled',
    tone: BadgeTone.light,
    minutesBetweenStops: 4,
  ),
];

const List<Club> clubs = [
  Club(id: 'robotics', name: 'Robotics Society', category: 'Technology', icon: Icons.precision_manufacturing_rounded, members: 124, meets: 'Tuesdays · 5:30 PM', description: 'Build autonomous bots and compete in national robotics leagues.'),
  Club(id: 'byteforge', name: 'ByteForge Coding Club', category: 'Technology', icon: Icons.code_rounded, members: 210, meets: 'Thursdays · 6:00 PM', description: 'Weekly contests, hack nights and peer code reviews.'),
  Club(id: 'debate', name: 'Debate Union', category: 'Literary', icon: Icons.record_voice_over_rounded, members: 68, meets: 'Wednesdays · 5:00 PM', description: 'Parliamentary debates, MUNs and public speaking practice.'),
  Club(id: 'lens', name: 'Lens & Light Photography', category: 'Arts', icon: Icons.photo_camera_rounded, members: 92, meets: 'Saturdays · 4:00 PM', description: 'Photo walks, editing workshops and an annual exhibition.'),
  Club(id: 'music', name: 'Music Collective', category: 'Arts', icon: Icons.music_note_rounded, members: 75, meets: 'Fridays · 6:30 PM', description: 'Jam sessions, open mics and the campus band.'),
  Club(id: 'nss', name: 'NSS Volunteers', category: 'Service', icon: Icons.volunteer_activism_rounded, members: 156, meets: 'Sundays · 7:00 AM', description: 'Community drives, clean-ups and teaching in nearby schools.'),
];

const List<Announcement> announcements = [
  Announcement(
    id: 'registration',
    title: 'Semester 6 course registration',
    message: 'Register for your Semester 6 courses on the student portal. Late registration carries a ₹1,000 fee and limited seat choice.',
    date: 'Posted 05 Oct 2026 · Academic Office',
    deadline: 'Closes Sun, 18 Oct 2026 at 5:00 PM',
    badge: 'Due soon',
    tone: BadgeTone.warning,
    icon: Icons.edit_calendar_rounded,
  ),
  Announcement(
    id: 'midsem',
    title: 'Mid-semester exam timetable published',
    message: 'The mid-semester examination schedule for all Year 3 programmes is now available. Check your seat allocation before exam week.',
    date: 'Posted 06 Oct 2026 · Examination Cell',
    deadline: 'Exams begin Mon, 26 Oct 2026',
    badge: 'New',
    tone: BadgeTone.success,
    icon: Icons.assignment_rounded,
  ),
  Announcement(
    id: 'scholarship',
    title: 'Merit scholarship briefing',
    message: 'Students with a CGPA of 3.5 or above are invited to a briefing on the 2027 merit scholarship. Bring your student ID.',
    date: 'Posted 04 Oct 2026 · Student Affairs',
    deadline: 'Wed, 14 Oct 2026 · 3:00 PM · Seminar Hall 2',
    badge: 'Eligible',
    tone: BadgeTone.info,
    icon: Icons.workspace_premium_rounded,
  ),
  Announcement(
    id: 'maintenance',
    title: 'Library e-resources maintenance',
    message: 'Online journals and e-books will be unavailable during scheduled network maintenance. Download what you need in advance.',
    date: 'Posted 03 Oct 2026 · Central Library',
    deadline: 'Sun, 11 Oct 2026 · 10:00 PM – 2:00 AM',
    badge: 'Notice',
    tone: BadgeTone.light,
    icon: Icons.build_circle_rounded,
  ),
];

const List<CampusEvent> campusEvents = [
  CampusEvent(
    id: 'career-fair',
    title: 'Tech Career Fair 2026',
    day: '15',
    month: 'OCT',
    weekday: 'Thursday',
    time: '10:00 AM – 4:00 PM',
    venue: 'Main Auditorium',
    category: 'Careers',
    description: 'Meet recruiters from 40+ technology companies, get your résumé reviewed and attend live mock interviews. Formal dress recommended.',
    icon: Icons.business_center_rounded,
    capacity: 600,
    registered: 472,
  ),
  CampusEvent(
    id: 'football-trials',
    title: 'Inter-hostel Football Trials',
    day: '10',
    month: 'OCT',
    weekday: 'Saturday',
    time: '7:00 AM – 9:30 AM',
    venue: 'Sports Complex · Ground 1',
    category: 'Sports',
    description: 'Selections for the inter-hostel championship squad. Bring your own boots and shin guards; water will be provided.',
    icon: Icons.sports_soccer_rounded,
    capacity: 80,
    registered: 51,
  ),
  CampusEvent(
    id: 'robotics-build-night',
    title: 'Robotics Society Build Night',
    day: '13',
    month: 'OCT',
    weekday: 'Tuesday',
    time: '5:30 PM – 9:00 PM',
    venue: 'Innovation Lab, Block D',
    category: 'Club',
    description: 'Hands-on build session for the line-follower challenge. Components and pizza provided for registered members.',
    icon: Icons.precision_manufacturing_rounded,
    capacity: 40,
    registered: 33,
  ),
  CampusEvent(
    id: 'beach-cleanup',
    title: 'NSS Beach Clean-up Drive',
    day: '18',
    month: 'OCT',
    weekday: 'Sunday',
    time: '6:30 AM – 10:00 AM',
    venue: 'Meet at Main Gate · bus provided',
    category: 'Volunteering',
    description: 'Join NSS volunteers for a coastal clean-up. Gloves and bags provided; volunteering hours count toward your service credits.',
    icon: Icons.volunteer_activism_rounded,
    capacity: 120,
    registered: 64,
  ),
  CampusEvent(
    id: 'flutter-workshop',
    title: 'Build Apps with Flutter',
    day: '21',
    month: 'OCT',
    weekday: 'Wednesday',
    time: '2:00 PM – 5:00 PM',
    venue: 'Computing Lab 3',
    category: 'Workshop',
    description: 'A beginner-friendly workshop on building cross-platform apps with Flutter. Bring a laptop with Flutter installed.',
    icon: Icons.phone_android_rounded,
    capacity: 60,
    registered: 58,
  ),
];
