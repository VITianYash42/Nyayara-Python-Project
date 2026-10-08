import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint_model.dart';

// ── 15+ AI Case Categories ──────────────────────────────────────────────
const List<String> kCaseCategories = [
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

// ── Legal sections map per category ────────────────────────────────────
const Map<String, List<String>> kCategoryLegalMap = {
  'Workplace Sexual Harassment (POSH)': [
    'POSH Act 2013 — Section 2(n)',
    'IPC Section 354A (Sexual Harassment)',
    'IPC Section 509 (Insulting Modesty)',
  ],
  'Domestic Violence': [
    'Protection of Women from Domestic Violence Act 2005',
    'IPC Section 498A (Cruelty by Husband)',
    'IPC Section 304B (Dowry Death)',
  ],
  'Dowry Harassment': [
    'Dowry Prohibition Act 1961',
    'IPC Section 498A',
    'IPC Section 304B',
  ],
  'Cyber Harassment / Online Abuse': [
    'IT Act Section 67 (Obscene Material)',
    'IPC Section 354D (Stalking)',
    'IPC Section 507 (Criminal Intimidation)',
  ],
  'Deepfake / Non-Consensual Intimate Images': [
    'IT Act Section 66E (Privacy Violation)',
    'IT Act Section 67A (Sexually Explicit Material)',
    'IPC Section 354C (Voyeurism)',
  ],
  'Stalking (Physical)': [
    'IPC Section 354D (Stalking)',
    'IPC Section 507 (Criminal Intimidation)',
  ],
  'Cyberstalking': [
    'IT Act Section 66A',
    'IPC Section 354D (Stalking)',
    'IPC Section 507',
  ],
  'Acid Attack / Threat of Acid Attack': [
    'IPC Section 326A (Acid Attack)',
    'IPC Section 326B (Attempt to Acid Attack)',
  ],
  'Child Marriage / Trafficking': [
    'Protection of Children from Sexual Offences Act (POCSO) 2012',
    'Child Marriage Restraint Act 2006',
    'Immoral Traffic Prevention Act 1956',
  ],
  'Marital Rape': [
    'IPC Section 376 (Rape)',
    'Protection of Women from Domestic Violence Act 2005',
  ],
  'Eve-Teasing / Street Harassment': [
    'IPC Section 354 (Assault on Woman)',
    'IPC Section 509 (Insulting Modesty)',
  ],
  'Verbal / Emotional Abuse': [
    'IPC Section 504 (Intentional Insult)',
    'IPC Section 506 (Criminal Intimidation)',
    'Protection of Women from Domestic Violence Act 2005',
  ],
  'Financial Abuse / Fraud': [
    'IPC Section 420 (Cheating)',
    'IPC Section 406 (Criminal Breach of Trust)',
  ],
  'Discrimination at Workplace': [
    'Constitution of India — Article 14 (Equality)',
    'Constitution of India — Article 15 (Non-Discrimination)',
    'POSH Act 2013',
  ],
  'Sexual Assault / Rape': [
    'IPC Section 376 (Rape)',
    'IPC Section 375 (Definition of Rape)',
    'POCSO Act 2012 (if minor involved)',
  ],
  'Other': [
    'IPC Section 354 (Assault on Woman)',
    'IPC Section 509',
  ],
};

// ── AI Analysis Result ──────────────────────────────────────────────────
class AIAnalysisResult {
  final String caseType;
  final String severityScore; // Low / Medium / High / Critical
  final int severityPercent;  // 0-100
  final int caseStrengthPercent;
  final List<String> legalSections;
  final List<String> actionPlan;
  final String aiSummary;
  final String nextBestAction;
  final String similarCaseSummary;
  final DateTime timestamp;

  AIAnalysisResult({
    required this.caseType,
    required this.severityScore,
    required this.severityPercent,
    required this.caseStrengthPercent,
    required this.legalSections,
    required this.actionPlan,
    required this.aiSummary,
    required this.nextBestAction,
    required this.similarCaseSummary,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    // Normalize caseType against known categories
    final rawType = (json['caseType'] as String? ?? 'Other').trim();
    final caseType = kCaseCategories.firstWhere(
      (c) => c.toLowerCase().contains(rawType.toLowerCase()) ||
          rawType.toLowerCase().contains(c.toLowerCase().split(' ').first),
      orElse: () => rawType.isNotEmpty ? rawType : 'Other',
    );

    final legalSections = (json['legalSections'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        kCategoryLegalMap[caseType] ??
        kCategoryLegalMap['Other']!;

    return AIAnalysisResult(
      caseType: caseType,
      severityScore: json['severityScore'] as String? ?? 'Medium',
      severityPercent: _parseInt(json['severityPercent'], 60),
      caseStrengthPercent: _parseInt(json['caseStrengthPercent'], 65),
      legalSections: legalSections,
      actionPlan: (json['actionPlan'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      aiSummary: json['aiSummary'] as String? ?? '',
      nextBestAction: json['nextBestAction'] as String? ?? '',
      similarCaseSummary: json['similarCaseSummary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'caseType': caseType,
        'severityScore': severityScore,
        'severityPercent': severityPercent,
        'caseStrengthPercent': caseStrengthPercent,
        'legalSections': legalSections,
        'actionPlan': actionPlan,
        'aiSummary': aiSummary,
        'nextBestAction': nextBestAction,
        'similarCaseSummary': similarCaseSummary,
        'timestamp': timestamp.toIso8601String(),
      };

  static int _parseInt(dynamic val, int fallback) {
    if (val == null) return fallback;
    if (val is int) return val.clamp(0, 100);
    if (val is double) return val.round().clamp(0, 100);
    return int.tryParse(val.toString()) ?? fallback;
  }

  /// Keyword-based fallback mock — returns plausible result without AI
  static AIAnalysisResult mock(String description) {
    final lower = description.toLowerCase();

    String caseType = 'Workplace Sexual Harassment (POSH)';
    if (lower.contains('husband') || lower.contains('wife') || lower.contains('domestic') || lower.contains('home') || lower.contains('marriage')) {
      caseType = 'Domestic Violence';
    } else if (lower.contains('dowry') || lower.contains('in-law')) {
      caseType = 'Dowry Harassment';
    } else if (lower.contains('deepfake') || lower.contains('nude') || lower.contains('intimate') || lower.contains('photo')) {
      caseType = 'Deepfake / Non-Consensual Intimate Images';
    } else if (lower.contains('online') || lower.contains('social media') || lower.contains('instagram') || lower.contains('whatsapp') || lower.contains('message')) {
      caseType = 'Cyber Harassment / Online Abuse';
    } else if (lower.contains('follow') || lower.contains('stalk') || lower.contains('watching')) {
      caseType = lower.contains('online') ? 'Cyberstalking' : 'Stalking (Physical)';
    } else if (lower.contains('acid')) {
      caseType = 'Acid Attack / Threat of Acid Attack';
    } else if (lower.contains('street') || lower.contains('eve') || lower.contains('teasing') || lower.contains('catcall')) {
      caseType = 'Eve-Teasing / Street Harassment';
    } else if (lower.contains('rape') || lower.contains('assault') || lower.contains('touch') || lower.contains('molest')) {
      caseType = lower.contains('husband') ? 'Marital Rape' : 'Sexual Assault / Rape';
    } else if (lower.contains('shout') || lower.contains('verbal') || lower.contains('emotional') || lower.contains('abuse')) {
      caseType = 'Verbal / Emotional Abuse';
    } else if (lower.contains('money') || lower.contains('salary') || lower.contains('fraud')) {
      caseType = 'Financial Abuse / Fraud';
    } else if (lower.contains('discriminat') || lower.contains('promotion')) {
      caseType = 'Discrimination at Workplace';
    }

    final sections = kCategoryLegalMap[caseType] ?? kCategoryLegalMap['Other']!;

    return AIAnalysisResult(
      caseType: caseType,
      severityScore: 'High',
      severityPercent: 75,
      caseStrengthPercent: 72,
      legalSections: sections,
      actionPlan: [
        'Document all incidents with dates, times, and witnesses',
        'Collect and preserve all evidence (screenshots, messages, recordings)',
        'File a written complaint with the appropriate authority',
        'Consult a legal advocate specializing in women\'s rights',
        'Contact the National Commission for Women (NCW) helpline: 7827170170',
        'If in immediate danger, call 112 (Emergency) or 181 (Women Helpline)',
      ],
      aiSummary:
          'Based on your description, this appears to be a serious case of $caseType. '
          'You have strong legal protections under Indian law. '
          'Immediate documentation and reporting is essential to build your case.',
      nextBestAction:
          'File a formal written complaint with the appropriate authority immediately and preserve all evidence.',
      similarCaseSummary:
          'Similar cases in India have resulted in legal action against the accused when proper documentation and timely reporting were maintained.',
    );
  }
}

// ── AI Service ─────────────────────────────────────────────────────────
class AIService {
  static const String _groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static bool get _hasApiKey =>
      _groqApiKey.isNotEmpty && !_groqApiKey.contains('YOUR_GROQ');

  // ── System Prompt ──────────────────────────────────────────────────
  static const String _systemPrompt = '''You are Nyayara, a compassionate and expert legal assistant for women's safety in India.
Your role is to analyze incidents and classify them accurately.

AVAILABLE CASE CATEGORIES (pick the BEST match; use "Other" if none fit):
- Workplace Sexual Harassment (POSH)
- Domestic Violence
- Dowry Harassment
- Cyber Harassment / Online Abuse
- Deepfake / Non-Consensual Intimate Images
- Stalking (Physical)
- Cyberstalking
- Acid Attack / Threat of Acid Attack
- Child Marriage / Trafficking
- Marital Rape
- Eve-Teasing / Street Harassment
- Verbal / Emotional Abuse
- Financial Abuse / Fraud
- Discrimination at Workplace
- Sexual Assault / Rape
- Other

SEVERITY LEVELS:
- Low (1-3): Minor incidents, verbal, no physical contact
- Medium (4-6): Repeated incidents, pattern of behavior, emotional impact
- High (7-8): Physical contact, threats, clear legal violation
- Critical (9-10): Immediate danger, violent, criminal offense

RULES:
2. Be empathetic and non-judgmental in aiSummary.
3. Pick legal sections specifically applicable under Indian law.
4. actionPlan must be practical and actionable steps.
5. caseStrengthPercent reflects likelihood of legal success with proper evidence.''';

  // ── Core Groq Call ─────────────────────────────────────────────────
  static Future<String> _callGroq(String userPrompt) async {
    final response = await http.post(
      Uri.parse(_groqBaseUrl),
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.2,
        'max_tokens': 2048,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    }
    throw Exception('Groq API error ${response.statusCode}: ${response.body}');
  }

  // ── 1. Analyze Incident ────────────────────────────────────────────
  static Future<AIAnalysisResult> analyzeIncident(String description) async {
    if (!_hasApiKey) {
      await Future.delayed(const Duration(seconds: 2));
      return AIAnalysisResult.mock(description);
    }

    try {
      final prompt = '''Analyze this incident and respond with ONLY this JSON (no other text):
{
  "caseType": "<best matching category from the list>",
  "severityScore": "<Low|Medium|High|Critical>",
  "severityPercent": <integer 0-100>,
  "caseStrengthPercent": <integer 0-100>,
  "legalSections": ["<Indian law section 1>", "<section 2>", "<section 3>"],
  "actionPlan": ["<step 1>", "<step 2>", "<step 3>", "<step 4>", "<step 5>"],
  "aiSummary": "<2-3 empathetic sentences analyzing the situation>",
  "nextBestAction": "<single most important immediate action>",
  "similarCaseSummary": "<1-2 sentences about similar case outcomes in India>"
}

Incident description: "$description"''';

      final text = await _callGroq(prompt);
      final jsonStr = _extractJson(text);
      if (jsonStr != null) {
        return AIAnalysisResult.fromJson(jsonDecode(jsonStr));
      }
      return AIAnalysisResult.mock(description);
    } catch (e) {
      return AIAnalysisResult.mock(description);
    }
  }

  // ── 2. Generate FIR Draft ──────────────────────────────────────────
  static Future<String> generateFIRDraft({
    required String complainantName,
    required String incidentDate,
    required String incidentLocation,
    required String description,
    required String caseType,
  }) async {
    if (!_hasApiKey) {
      return _mockFIR(complainantName, incidentDate, incidentLocation, description, caseType);
    }
    try {
      final prompt = '''Generate a complete, formal FIR (First Information Report) for submission to an Indian police station.

Complainant Name: $complainantName
Case Type: $caseType
Date of Incident: $incidentDate
Location: $incidentLocation
Description: $description

Include:
1. FIR header with date placeholder and police station placeholder
2. Section: Complainant Details
3. Section: Date, Time & Place of Incident  
4. Section: Detailed Account of Incident (expand the description into formal language)
5. Section: Applicable Laws & Sections (IPC, POSH Act, IT Act as relevant)
6. Section: Witnesses (if any — leave blank template)
7. Section: Evidence Available  
8. Section: Prayer / Relief Sought
9. Signature block

Make it ready to print and submit. Formal legal language.''';

      return await _callGroq(prompt);
    } catch (e) {
      return _mockFIR(complainantName, incidentDate, incidentLocation, description, caseType);
    }
  }

  // ── 3. Generate HR Complaint Email ─────────────────────────────────
  static Future<String> generateHRComplaintEmail({
    required String complainantName,
    required bool isAnonymous,
    required String harasserName,
    required String department,
    required String incidentDate,
    required String description,
  }) async {
    if (!_hasApiKey) {
      return _mockHREmail(
          complainantName, isAnonymous, harasserName, department, incidentDate, description);
    }
    try {
      final from = isAnonymous ? 'An Anonymous Employee' : complainantName;
      final prompt = '''Write a formal HR complaint email under the POSH Act 2013 (India).

From: $from
Reported Person: $harasserName ($department Department)
Date of Incident: $incidentDate
Incident: $description

Requirements:
- Subject line referencing POSH Act 2013
- Formal professional tone
- Reference relevant POSH Act sections
- Request ICC investigation within statutory 60-day period
- Request interim protection measures
- ${isAnonymous ? "Do NOT include any identifying information about the complainant" : "Include complainant details"}
- Professional closing''';

      return await _callGroq(prompt);
    } catch (e) {
      return _mockHREmail(
          complainantName, isAnonymous, harasserName, department, incidentDate, description);
    }
  }

  // ── 4. Chat Response ───────────────────────────────────────────────
  static Future<String> getChatResponse(String userMessage,
      {List<Map<String, String>> history = const []}) async {
    if (!_hasApiKey) {
      await Future.delayed(const Duration(milliseconds: 1500));
      return _mockChatResponse(userMessage);
    }
    try {
      final response = await http.post(
        Uri.parse(_groqBaseUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ...history,
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.4,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      return _mockChatResponse(userMessage);
    } catch (e) {
      return _mockChatResponse(userMessage);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────
  static String? _extractJson(String text) {
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    return match?.group(0);
  }

  static String _mockChatResponse(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('fir') || lower.contains('police')) {
      return '📋 **Filing an FIR** — You can file an FIR at any police station free of charge. Under Section 154 CrPC, the police are legally bound to register it. If they refuse, you can approach the SP/DSP directly or file an e-FIR online at your state police website.\n\nFor women\'s cases, you can also call **181** (Women Helpline) for assistance in filing.';
    }
    if (lower.contains('posh') || lower.contains('workplace') || lower.contains('office')) {
      return '⚖️ **POSH Act 2013 Rights** — Every organization with 10+ employees must have an Internal Complaints Committee (ICC). You can file a complaint within **3 months** of the incident. The ICC must complete inquiry in 60 days. Your identity is protected and retaliation is prohibited under Section 13.\n\nWould you like me to help draft a complaint email to your HR?';
    }
    if (lower.contains('domestic') || lower.contains('husband') || lower.contains('home')) {
      return '🏠 **Domestic Violence Support** — Under the Protection of Women from Domestic Violence Act 2005, you can get:\n• **Protection Orders** — stops abuser from contacting you\n• **Residence Orders** — right to stay in shared household\n• **Compensation Orders** — monetary relief\n\nCall **181** (Women Helpline) or **1091** (Women Police Helpline) for immediate help. You can also contact your nearest District Legal Services Authority for free legal aid.';
    }
    if (lower.contains('cyber') || lower.contains('online') || lower.contains('photo') || lower.contains('revenge')) {
      return '💻 **Cyber Crime Support** — Report at **cybercrime.gov.in** (National Cyber Crime Reporting Portal) immediately. For non-consensual intimate images, this is punishable under IT Act Section 66E and 67A.\n\nPreserve all evidence (screenshots with URLs, timestamps). You can also call **1930** (Cyber Crime Helpline).';
    }
    return '🤝 I understand you may be going through a difficult situation. I\'m here to help.\n\nCould you share more details about what happened? I can help you:\n• **Understand your legal rights**\n• **Identify applicable laws**\n• **Draft an FIR or HR complaint**\n• **Find the right authority to report to**\n\nEverything you share is confidential.';
  }

  static String _mockFIR(String name, String date, String location, String desc, String type) {
    return '''FIRST INFORMATION REPORT
Under Section 154 Cr.P.C.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FIR No.: ________________    Date: ${DateTime.now().toString().substring(0, 10)}
Police Station: ________________
District: ________________    State: ________________
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. COMPLAINANT DETAILS:
   Full Name: $name
   Address: ________________
   Phone: ________________
   Email: ________________

2. DATE & TIME OF INCIDENT:
   Date: $date
   Time (approximate): ________________

3. PLACE OF OCCURRENCE:
   $location

4. NATURE OF OFFENCE:
   $type

5. DETAILED ACCOUNT OF INCIDENT:
   $desc

6. APPLICABLE LAWS & SECTIONS:
   • ${kCategoryLegalMap[type]?.join('\n   • ') ?? 'IPC Section 354A (Sexual Harassment)'}

7. WITNESSES (if any):
   a. Name: ________________, Contact: ________________
   b. Name: ________________, Contact: ________________

8. EVIDENCE AVAILABLE:
   □ Screenshots / Messages
   □ Audio / Video Recordings  
   □ Medical Reports
   □ Electronic Communication Records
   □ Other: ________________

9. PRAYER:
   I request the Hon'ble Police to register this FIR and initiate
   appropriate legal proceedings against the accused as per the law.
   I further request interim protection measures during the investigation.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Signature of Complainant: ________________
Name: $name
Date: ${DateTime.now().toString().substring(0, 10)}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[For Police Use]
Receiving Officer: ________________
Signature & Stamp: ________________
Date & Time Received: ________________
''';
  }

  static String _mockHREmail(
      String name, bool anon, String harasser, String dept, String date, String desc) {
    final from = anon ? 'An Anonymous Employee' : name;
    return '''Subject: Formal Complaint Under POSH Act 2013 — Workplace Sexual Harassment

Date: ${DateTime.now().toString().substring(0, 10)}

To,
The Presiding Officer,
Internal Complaints Committee (ICC)
[Organization Name]

Dear Presiding Officer,

I, $from, am writing to formally report an incident of workplace sexual harassment as defined under Section 2(n) of the Sexual Harassment of Women at Workplace (Prevention, Prohibition and Redressal) Act, 2013.

━━━━━━━━━━━━━━━━━━━━━━━━━
COMPLAINT DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━

Reported Person: $harasser
Department: $dept
Date of Incident: $date

Description of Incident:
$desc

━━━━━━━━━━━━━━━━━━━━━━━━━
RELIEF SOUGHT
━━━━━━━━━━━━━━━━━━━━━━━━━

I hereby request the ICC to:

1. Register this complaint and initiate a formal inquiry under Section 11 of the POSH Act 2013
2. Complete the inquiry within the 60-day statutory period as mandated by Section 11(4)
3. Provide interim relief as deemed appropriate under Section 12, including:
   - Transfer of the respondent to another department/location
   - Leave with pay during the inquiry period
4. Maintain strict confidentiality of this complaint as required under Section 16
5. Take appropriate action against the respondent upon completion of inquiry

I am prepared to cooperate fully with the inquiry process and provide additional evidence or testimony as required.

━━━━━━━━━━━━━━━━━━━━━━━━━

${anon ? '[Identity Protected under POSH Act Section 16 — Anonymous Complainant]' : '''Yours sincerely,
$name'''}

Date: ${DateTime.now().toString().substring(0, 10)}

[Filed via Nyayara — Women Safety Platform]
''';
  }
}
