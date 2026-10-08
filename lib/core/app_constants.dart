class AppConstants {
  // App Info
  static const String appName = 'Nyayara';
  static const String appTagline = 'Your Shield. Your Voice. Your Rights.';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String colUsers = 'users';
  static const String colComplaints = 'complaints';
  static const String colEvidence = 'evidence';
  static const String colOrganizations = 'organizations';
  static const String colSosAlerts = 'sos_alerts';
  static const String colNotifications = 'notifications';

  // User Roles
  static const String roleUser = 'user';
  static const String roleHR = 'hr';
  static const String roleAdmin = 'admin';

  // Complaint Statuses
  static const String statusPending = 'Pending Review';
  static const String statusUnderReview = 'Under Review';
  static const String statusInvestigating = 'Investigating';
  static const String statusResolved = 'Resolved';
  static const String statusClosed = 'Closed';

  // Case Types — 15+ AI-recognized categories
  static const List<String> caseTypes = [
    'Workplace Sexual Harassment (POSH)',
    'Domestic Violence',
    'Dowry Harassment',
    'Cyber Harassment / Online Abuse',
    'Deepfake / Non-Consensual Intimate Images',
    'Stalking (Physical)',
    'Cyberstalking',
    'Acid Attack / Threat of Acid Attack',
    'Child Marriage / Trafficking',
    'Marital Rape',
    'Eve-Teasing / Street Harassment',
    'Verbal / Emotional Abuse',
    'Financial Abuse / Fraud',
    'Discrimination at Workplace',
    'Sexual Assault / Rape',
    'Other',
  ];

  // Emergency Helpline Numbers
  static const String helplinePolice = '112';
  static const String helplineWomen = '181';
  static const String helplineWomenPolice = '1091';
  static const String helplineCyberCrime = '1930';
  static const String helplineNCW = '7827170170'; // National Commission for Women

  // Severity Levels
  static const String severityLow = 'Low';
  static const String severityMedium = 'Medium';
  static const String severityHigh = 'High';
  static const String severityCritical = 'Critical';

  // Departments (mock data for demo)
  // EmailJS Configuration
  static const String emailJsServiceId = 'service_4z9g4m6';
  static const String emailJsTemplateId = 'template_napk02c';
  static const String emailJsPublicKey = 's6gQpwcwu8XLb9RsH';
  static const String emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  static const List<String> departments = [
    'Engineering',
    'Sales',
    'HR',
    'Finance',
    'Marketing',
    'Operations',
    'Legal',
    'Management',
    'Other',
  ];

  // Legal Acts
  static const Map<String, List<String>> legalSections = {
    'Workplace Harassment': [
      'POSH Act 2013 - Section 3: Prohibition of sexual harassment',
      'POSH Act 2013 - Section 4: Complaint Committee formation',
      'IPC Section 354A: Sexual harassment',
      'IPC Section 509: Words/gestures insulting modesty',
    ],
    'Domestic Violence': [
      'Protection of Women from Domestic Violence Act 2005',
      'IPC Section 498A: Cruelty by husband/relatives',
      'IPC Section 304B: Dowry death',
      'IPC Section 323: Voluntarily causing hurt',
    ],
    'Dowry Harassment': [
      'Dowry Prohibition Act 1961',
      'IPC Section 304B: Dowry death',
      'IPC Section 498A: Cruelty for dowry demands',
      'IPC Section 406: Criminal breach of trust',
    ],
    'Cyber Harassment / Deepfake': [
      'IT Act Section 66C: Identity theft',
      'IT Act Section 66E: Privacy violation',
      'IT Act Section 67: Obscene material publishing',
      'IPC Section 509: Words insulting modesty digitally',
    ],
    'Stalking': [
      'IPC Section 354D: Stalking',
      'IT Act Section 66C: Online stalking',
      'CrPC Section 144: Immediate restraining order',
    ],
    'Sexual Assault': [
      'IPC Section 375: Rape',
      'IPC Section 376: Punishment for rape',
      'IPC Section 354: Assault for outrage of modesty',
    ],
  };

  // Firebase Function Names
  static const String fnAnalyzeIncident = 'analyzeIncident';
  static const String fnSendEmailNotification = 'sendEmailNotification';
  static const String fnCheckRepeatOffender = 'checkRepeatOffender';
  static const String fnGenerateFIR = 'generateFIRDraft';

  // Storage Paths
  static const String storageEvidence = 'evidence';
  static const String storageProfilePics = 'profile_pictures';

  // SOS
  static const int sosCountdownSeconds = 3;
  static const int safeTimerMinutes = 30;

  // Official Reporting URLs
  static const String urlSheBox = 'https://shebox.nic.in';
  static const String urlCyberCrime = 'https://cybercrime.gov.in';
  static const String urlNCW = 'https://ncwapps.nic.in/onlinecomplaintsv2';
  static const String urlMahaPolice = 'https://citizen.mahapolice.gov.in';

  // Demo Organizational Data
  static const String demoOrgId = 'demo_org_001';
  static const String demoOrgName = 'TechCorp Solutions Ltd.';
}
