/// The logged-in student's account, as stored in the backend database.
class Student {
  const Student({
    required this.pk,
    required this.id,
    required this.name,
    required this.email,
    required this.programme,
    required this.semester,
    required this.totalSemesters,
    required this.cgpa,
    required this.creditsEarned,
    required this.creditsRequired,
    required this.advisor,
    this.phone,
    this.residence,
    this.photoUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        pk: json['id'] as int,
        id: json['student_id'] as String,
        name: json['full_name'] as String,
        email: json['email'] as String,
        programme: json['programme'] as String,
        semester: json['semester'] as int,
        totalSemesters: json['total_semesters'] as int,
        cgpa: (json['cgpa'] as num?)?.toDouble(),
        creditsEarned: json['credits_earned'] as int,
        creditsRequired: json['credits_required'] as int,
        advisor: json['advisor'] as String,
        phone: json['phone'] as String?,
        residence: json['residence'] as String?,
        photoUrl: json['photo_url'] as String?,
      );

  final int pk;

  /// University student ID, e.g. I23012345.
  final String id;
  final String name;
  final String email;
  final String programme;
  final int semester;
  final int totalSemesters;
  final double? cgpa;
  final int creditsEarned;
  final int creditsRequired;
  final String advisor;
  final String? phone;
  final String? residence;

  /// Server path of the profile photo (e.g. /media/abc.jpg), if uploaded.
  final String? photoUrl;

  String get firstName => name.split(' ').first;

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  String get year => 'Year ${(semester + 1) ~/ 2}';

  String get cgpaLabel => cgpa == null ? '—' : cgpa!.toStringAsFixed(2);
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.announcements,
    required this.classReminders,
    required this.shuttleAlerts,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        announcements: json['announcements'] as bool,
        classReminders: json['class_reminders'] as bool,
        shuttleAlerts: json['shuttle_alerts'] as bool,
      );

  static const defaults = NotificationPreferences(
    announcements: true,
    classReminders: true,
    shuttleAlerts: false,
  );

  final bool announcements;
  final bool classReminders;
  final bool shuttleAlerts;

  NotificationPreferences copyWith({
    bool? announcements,
    bool? classReminders,
    bool? shuttleAlerts,
  }) =>
      NotificationPreferences(
        announcements: announcements ?? this.announcements,
        classReminders: classReminders ?? this.classReminders,
        shuttleAlerts: shuttleAlerts ?? this.shuttleAlerts,
      );

  Map<String, dynamic> toJson() => {
        'announcements': announcements,
        'class_reminders': classReminders,
        'shuttle_alerts': shuttleAlerts,
      };
}

class HelpdeskTicket {
  const HelpdeskTicket({
    required this.ticketNo,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
    this.subject,
    this.priority,
    this.preferredDate,
    this.contactMethod,
    this.contactPhone,
  });

  factory HelpdeskTicket.fromJson(Map<String, dynamic> json) => HelpdeskTicket(
        ticketNo: json['ticket_no'] as String,
        category: json['category'] as String,
        message: json['message'] as String,
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
        subject: json['subject'] as String?,
        priority: json['priority'] as String?,
        preferredDate: json['preferred_date'] as String?,
        contactMethod: json['contact_method'] as String?,
        contactPhone: json['contact_phone'] as String?,
      );

  final String ticketNo;
  final String category;
  final String message;
  final String status;
  final String createdAt;

  /// Added with the step-by-step ticket form; older tickets leave them null.
  final String? subject;
  final String? priority;

  /// "YYYY-MM-DD" the student would like to be contacted or seen.
  final String? preferredDate;
  final String? contactMethod;
  final String? contactPhone;

  /// Subject if given, otherwise the first line of the message.
  String get headline => (subject?.isNotEmpty ?? false) ? subject! : message.split('\n').first;
}

/// What the student fills in when raising a ticket.
class TicketRequest {
  const TicketRequest({
    required this.category,
    required this.message,
    this.subject,
    this.priority,
    this.preferredDate,
    this.contactMethod,
    this.contactPhone,
  });

  final String category;
  final String message;
  final String? subject;
  final String? priority;
  final DateTime? preferredDate;
  final String? contactMethod;
  final String? contactPhone;

  String? get preferredDateIso => preferredDate == null
      ? null
      : '${preferredDate!.year.toString().padLeft(4, '0')}-'
          '${preferredDate!.month.toString().padLeft(2, '0')}-'
          '${preferredDate!.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'category': category,
        'message': message.trim(),
        if (subject != null && subject!.trim().isNotEmpty) 'subject': subject!.trim(),
        if (priority != null) 'priority': priority,
        if (preferredDate != null) 'preferred_date': preferredDateIso,
        if (contactMethod != null) 'contact_method': contactMethod,
        if (contactPhone != null && contactPhone!.trim().isNotEmpty) 'contact_phone': contactPhone!.trim(),
      };
}

/// Everything GET /api/me returns.
class ProfileBundle {
  const ProfileBundle({
    required this.student,
    required this.preferences,
    required this.registeredEvents,
    required this.joinedClubs,
    required this.readAnnouncements,
    required this.renewedBooks,
    required this.shuttleAlerts,
    required this.tickets,
  });

  factory ProfileBundle.fromJson(Map<String, dynamic> json) {
    Set<String> ids(String key) =>
        (json[key] as List<dynamic>).map((e) => e as String).toSet();
    return ProfileBundle(
      student: Student.fromJson(json['student'] as Map<String, dynamic>),
      preferences: NotificationPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      ),
      registeredEvents: ids('registered_events'),
      joinedClubs: ids('joined_clubs'),
      readAnnouncements: ids('read_announcements'),
      renewedBooks: ids('renewed_books'),
      shuttleAlerts: ids('shuttle_alerts'),
      tickets: (json['tickets'] as List<dynamic>)
          .map((t) => HelpdeskTicket.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  final Student student;
  final NotificationPreferences preferences;
  final Set<String> registeredEvents;
  final Set<String> joinedClubs;
  final Set<String> readAnnouncements;
  final Set<String> renewedBooks;
  final Set<String> shuttleAlerts;
  final List<HelpdeskTicket> tickets;
}

/// Data collected by the Create account page.
class RegistrationData {
  const RegistrationData({
    required this.fullName,
    required this.studentId,
    required this.email,
    required this.password,
    required this.programme,
    required this.semester,
    this.cgpa,
    this.creditsEarned = 0,
    this.phone,
  });

  final String fullName;
  final String studentId;
  final String email;
  final String password;
  final String programme;
  final int semester;
  final double? cgpa;
  final int creditsEarned;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'student_id': studentId,
        'email': email,
        'password': password,
        'programme': programme,
        'semester': semester,
        'cgpa': cgpa,
        'credits_earned': creditsEarned,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
      };
}
