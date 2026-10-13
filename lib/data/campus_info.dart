import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// ---------------------------------------------------------------------------
// Campus map places. Coordinates come from OpenStreetMap
// (© OpenStreetMap contributors, ODbL). Pins are as accurate as the OSM data;
// adjust them here if a building moves on the ground.
// ---------------------------------------------------------------------------

class CampusPlace {
  const CampusPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.point,
    required this.description,
  });

  final String id;
  final String name;
  final String category;
  final IconData icon;
  final LatLng point;
  final String description;
}

const LatLng campusCenter = LatLng(2.81240, 101.75826);

/// OSM bounding box of the university grounds (approximate outline).
const List<LatLng> campusOutline = [
  LatLng(2.81704, 101.75677),
  LatLng(2.81704, 101.75975),
  LatLng(2.80772, 101.75975),
  LatLng(2.80772, 101.75677),
];

const List<CampusPlace> campusPlaces = [
  CampusPlace(
    id: 'main',
    name: 'Main Building',
    category: 'Administration',
    icon: Icons.account_balance_rounded,
    point: LatLng(2.81296, 101.75840),
    description: 'The landmark building with the INTI logo at the front.',
  ),
  CampusPlace(
    id: 'block-a',
    name: 'Academic Block A',
    category: 'Classes',
    icon: Icons.school_rounded,
    point: LatLng(2.81424, 101.75795),
    description: 'Academic block on the north side of campus.',
  ),
  CampusPlace(
    id: 'block-d',
    name: 'Academic Block D',
    category: 'Classes',
    icon: Icons.school_rounded,
    point: LatLng(2.81370, 101.75791),
    description: 'Academic block next to Block A.',
  ),
  CampusPlace(
    id: 'hall',
    name: 'Tan Yew Sing Multipurpose Hall',
    category: 'Events',
    icon: Icons.celebration_rounded,
    point: LatLng(2.81222, 101.75819),
    description: 'Multipurpose hall in the middle of campus.',
  ),
  CampusPlace(
    id: 'lincoln',
    name: 'Lincoln Hall',
    category: 'Residence',
    icon: Icons.bed_rounded,
    point: LatLng(2.80818, 101.75934),
    description: 'Student dormitory on the south side of campus.',
  ),
  CampusPlace(
    id: 'north-gate',
    name: 'North Entrance',
    category: 'Entrance',
    icon: Icons.login_rounded,
    point: LatLng(2.81320, 101.75735),
    description: 'Entrance from Jalan BBN 12/1.',
  ),
  CampusPlace(
    id: 'south-gate',
    name: 'South Entrance',
    category: 'Entrance',
    icon: Icons.login_rounded,
    point: LatLng(2.81289, 101.75867),
    description: 'Entrance beside the main building.',
  ),
  CampusPlace(
    id: 'bus',
    name: 'Bus Parking',
    category: 'Transport',
    icon: Icons.directions_bus_rounded,
    point: LatLng(2.81261, 101.75938),
    description: 'Campus bus parking area.',
  ),
  CampusPlace(
    id: 'melati',
    name: 'Melati Square Bus Stop',
    category: 'Transport',
    icon: Icons.signpost_rounded,
    point: LatLng(2.81304, 101.75994),
    description: 'Public bus stop just east of campus.',
  ),
];

// ---------------------------------------------------------------------------
// About INTI University, Nilai (facts: Wikipedia, INTI official site).
// ---------------------------------------------------------------------------

const String intiAddress = 'Persiaran Perdana BBN, Putra Nilai, 71800 Nilai, Negeri Sembilan, Malaysia';

class AboutSlide {
  const AboutSlide({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String image;
  final String eyebrow;
  final String title;
  final String body;
}

const List<AboutSlide> aboutSlides = [
  AboutSlide(
    image: 'assets/images/inti_students.jpg',
    eyebrow: 'Since 1986',
    title: 'A community of learners',
    body: 'INTI began in 1986 in Brickfields, Kuala Lumpur, with just 37 students. '
        'Within 18 months it had grown to 400.',
  ),
  AboutSlide(
    image: 'assets/images/inti_aerial.jpg',
    eyebrow: 'Putra Nilai · since 1998',
    title: 'The Nilai campus',
    body: 'The main campus opened in 1998 on 82 acres of landscaped grounds in '
        'Putra Nilai, Negeri Sembilan, south of Kuala Lumpur.',
  ),
  AboutSlide(
    image: 'assets/images/inti_atrium.jpg',
    eyebrow: 'Learning spaces',
    title: 'Built for working together',
    body: 'Bright, open atriums and study areas give room for group work between '
        'classes, with flags from students’ home countries along the walls.',
  ),
  AboutSlide(
    image: 'assets/images/inti_graduates.jpg',
    eyebrow: 'University status · 2010',
    title: 'From college to university',
    body: 'INTI became a university college in 2006 and was upgraded to full '
        'university status on 31 May 2010 as INTI International University.',
  ),
];

/// Short facts for stat tiles: (value, label).
const List<(String, String)> intiFacts = [
  ('1986', 'Founded'),
  ('1998', 'Nilai campus opened'),
  ('82', 'Acres of grounds'),
  ('2010', 'University status'),
];

// ---------------------------------------------------------------------------
// Study, careers and international life at INTI (landing page).
// Sources: INTI student-mobility factsheets (Aug 2026, Jan 2027) for the
// faculty and programme list; INTI "Why INTI" page for career services and
// the 2017 Graduate Employability Survey; QS TopUniversities profile for the
// countries figure. Check newinti.edu.my for the current full catalogue.
// ---------------------------------------------------------------------------

class Faculty {
  const Faculty(this.name, this.icon, this.programmes);

  final String name;
  final IconData icon;
  final List<String> programmes;
}

const List<Faculty> intiFaculties = [
  Faculty('Business and Communications', Icons.business_center_rounded, [
    'Accounting and Finance',
    'Business (any major)',
    'Digital Media',
    'Mass Communication',
  ]),
  Faculty('Data Science and Information Technology', Icons.computer_rounded, [
    'Computer Science',
    'Information Technology',
  ]),
  Faculty('Engineering and Quantity Surveying', Icons.engineering_rounded, [
    'Civil Engineering',
    'Mechanical Engineering',
    'Quantity Surveying',
    'Diplomas in Civil and Mechanical Engineering',
  ]),
  Faculty('Health and Life Sciences', Icons.biotech_rounded, [
    'Physiotherapy',
    'Biotechnology',
  ]),
  Faculty('Education and Liberal Arts', Icons.auto_stories_rounded, [
    'Teaching Chinese as a Second Language',
  ]),
];

const List<String> intiPostgraduate = [
  'Master of Business Administration',
  'Master in Education Management',
  'MSc Construction Management (BIM / Facility Management)',
  'Master in Information Technology',
];

/// What INTI's Career Services Centre offers.
const List<(IconData, String, String)> intiCareerServices = [
  (Icons.support_agent_rounded, 'One-to-one career advice', 'Guidance from experienced career advisers.'),
  (Icons.work_rounded, 'Internship placements', 'Placements with INTI\u2019s industry partners.'),
  (Icons.school_rounded, 'Career-readiness workshops', 'Communication, professional etiquette and more.'),
  (Icons.groups_rounded, 'Career fairs and networking', 'Meet recruiters, employers and alumni.'),
];

/// (value, label, source note)
const (String, String, String) intiEmployability = (
  '99%',
  'of graduates employed within 6 months of graduating',
  'INTI Graduate Employability Survey 2017, validated by BDO',
);

const (String, String, String) intiInternational = (
  '100+',
  'countries represented in INTI\u2019s student community',
  'QS TopUniversities profile, across INTI\u2019s campuses',
);

/// Mapped places on the Nilai campus, shown on the landing page.
const List<(IconData, String, String)> intiCampusHighlights = [
  (Icons.landscape_rounded, '82 acres', 'Landscaped grounds in Putra Nilai'),
  (Icons.school_rounded, 'Academic Blocks A & D', 'Lecture and teaching blocks'),
  (Icons.celebration_rounded, 'Tan Yew Sing Hall', 'Multipurpose hall for events'),
  (Icons.bed_rounded, 'Lincoln Hall', 'Student residence on campus'),
  (Icons.directions_bus_rounded, 'Shuttles & buses', 'Campus bus parking and Melati Square stop'),
  (Icons.public_rounded, 'Student exchange', 'Mobility programmes each January and August intake'),
];
