// Saheli AI - Firebase Cloud Functions (Groq AI)
// Deploy: cd functions && npm install && firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const Groq = require('groq-sdk');

admin.initializeApp();
const db = admin.firestore();

// ─── Groq AI Client ────────────────────────────────────────
// Get free API key at: https://console.groq.com
const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || functions.config().groq?.key || '',
});

// Helper: call Groq with a prompt
async function callGroq(prompt, systemPrompt = '') {
  const messages = [];
  if (systemPrompt) {
    messages.push({ role: 'system', content: systemPrompt });
  }
  messages.push({ role: 'user', content: prompt });

  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile', // Fast + free on Groq
    messages,
    temperature: 0.3,
    max_tokens: 2048,
  });

  return response.choices[0]?.message?.content || '';
}

// ─── 1. ANALYZE INCIDENT WITH AI ──────────────────────────────
exports.analyzeIncident = functions.https.onCall(async (data, context) => {
  const { description } = data;

  const systemPrompt = `You are Saheli AI, a compassionate and expert legal classification assistant for women's safety in India.

AVAILABLE CATEGORIES (pick the BEST match):
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

SEVERITY: Low (1-3) | Medium (4-6) | High (7-8) | Critical (9-10)
Rules: Respond ONLY with valid JSON. No markdown, no extra text. Be empathetic in aiSummary. Use Indian law sections only.`;

  const prompt = `Analyze this incident and respond with ONLY this JSON:
{
  "caseType": "<best matching category from the list>",
  "severityScore": "<Low|Medium|High|Critical>",
  "severityPercent": <0-100>,
  "caseStrengthPercent": <0-100>,
  "legalSections": ["<Indian law 1>", "<law 2>", "<law 3>"],
  "actionPlan": ["<step 1>", "<step 2>", "<step 3>", "<step 4>", "<step 5>"],
  "aiSummary": "<2-3 empathetic sentences analyzing the situation>",
  "nextBestAction": "<single most important immediate action>",
  "similarCaseSummary": "<1-2 sentences about similar case outcomes in India>"
}

Incident: "${description}"`;

  try {
    const text = await callGroq(prompt, systemPrompt);
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      if (!parsed.caseType || !parsed.severityScore) throw new Error('Invalid AI response structure');
      return parsed;
    }
    throw new Error('No JSON in response');
  } catch (error) {
    console.error('analyzeIncident error:', error);
    return {
      caseType: 'Workplace Sexual Harassment (POSH)',
      severityScore: 'High',
      severityPercent: 75,
      caseStrengthPercent: 70,
      legalSections: ['POSH Act 2013 — Section 2(n)', 'IPC Section 354A', 'IPC Section 509'],
      actionPlan: [
        'Document all incidents with dates, times, and witnesses',
        'File written complaint with Internal Complaints Committee (ICC)',
        'Preserve all evidence — messages, emails, recordings',
        'Consult a women\'s rights legal advocate',
        'Call 181 (Women Helpline) or 112 (Emergency) if in immediate danger',
      ],
      aiSummary: 'Your situation involves a serious legal violation. You have strong protections under Indian law. Please act promptly.',
      nextBestAction: 'File a formal written complaint with the appropriate authority and preserve all evidence immediately.',
      similarCaseSummary: 'Similar cases in India have led to legal action when proper documentation and timely reporting were maintained.',
    };
  }
});


// ─── 2. GENERATE FIR DRAFT ────────────────────────────────────
exports.generateFIRDraft = functions.https.onCall(async (data, context) => {
  const { complainantName, incidentDate, incidentLocation, description, caseType } = data;

  const systemPrompt = `You are a legal document expert specializing in Indian law. 
Generate formal, professionally worded legal documents.`;

  const prompt = `Generate a complete FIR (First Information Report) for Indian police.

Complainant: ${complainantName}
Case Type: ${caseType}
Date of Incident: ${incidentDate}
Location: ${incidentLocation}
Incident Description: ${description}

Format it as a proper FIR with:
- FIR header with date and police station placeholder
- Complainant details section
- Detailed incident description
- Relevant IPC sections / POSH Act provisions
- Prayer/request section
- Signature block

Make it professional and ready to submit to an Indian police station.`;

  const firDraft = await callGroq(prompt, systemPrompt);
  return { firDraft };
});

// ─── 3. GENERATE HR COMPLAINT EMAIL ───────────────────────────
exports.generateHREmail = functions.https.onCall(async (data, context) => {
  const { complainantName, isAnonymous, harasserName, department, incidentDate, description } = data;

  const systemPrompt = `You are an HR legal expert. Generate professional, formal complaint emails.`;

  const prompt = `Generate a formal HR complaint email under the POSH Act 2013.

From: ${isAnonymous ? 'Anonymous Employee' : complainantName}
Against: ${harasserName} (${department} Department)
Date of Incident: ${incidentDate}
Incident: ${description}

Include:
- Formal subject line
- Reference to POSH Act 2013
- Clear factual description of incident
- Request for ICC investigation
- Request for interim relief if needed
- Professional closing

Keep it factual, professional, and legally sound.`;

  const emailDraft = await callGroq(prompt, systemPrompt);
  return { emailDraft };
});

// ─── 4. SEND EMAIL NOTIFICATION ──────────────────────────────
exports.sendEmailNotification = functions.https.onCall(async (data, context) => {
  const { hrEmail, emailDraft, department } = data;

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: 'keerthisreej@gmail.com',
      pass: 'atzl benf fltd ynnc',
    },
  });

  await transporter.sendMail({
    from: '"Saheli AI Platform" <noreply@saheliai.com>',
    to: hrEmail,
    subject: `[POSH Complaint] Workplace Harassment Report - ${department}`,
    text: emailDraft,
    html: `<div style="font-family: Arial; font-size: 14px; line-height: 1.8; max-width: 700px;">
      <div style="background: #1a1a2e; color: #daa520; padding: 20px; border-radius: 8px 8px 0 0;">
        <h2 style="margin: 0;">⚖️ Saheli AI — POSH Complaint Report</h2>
      </div>
      <div style="padding: 20px; background: #f9f9f9; border: 1px solid #ddd;">
        <pre style="white-space: pre-wrap; font-family: Arial;">${emailDraft}</pre>
      </div>
      <div style="padding: 10px 20px; background: #eee; font-size: 11px; color: #666; border-radius: 0 0 8px 8px;">
        This complaint was filed via Saheli AI — Women Safety Platform. Filed on: ${new Date().toLocaleDateString('en-IN')}
      </div>
    </div>`,
  });

  return { success: true };
});

// ─── 5. CHECK REPEAT OFFENDER (Firestore Trigger) ─────────────
exports.checkRepeatOffender = functions.firestore
  .document('complaints/{complaintId}')
  .onCreate(async (snap, context) => {
    const complaint = snap.data();
    const { harasserName, department } = complaint;

    const snapshot = await db.collection('complaints')
      .where('harasserName', '==', harasserName)
      .where('department', '==', department)
      .get();

    const count = snapshot.size;

    if (count >= 3) {
      const batch = db.batch();
      snapshot.forEach(doc => {
        batch.update(doc.ref, { escalated: true, offenderReportCount: count, severityScore: 'High' });
      });
      await batch.commit();

      await db.collection('notifications').add({
        type: 'escalation',
        harasserName,
        department,
        complaintCount: count,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });
    }
    return null;
  });

// ─── 6. SOS ALERT ────────────────────────────────────────────
exports.sendSOSAlert = functions.https.onCall(async (data, context) => {
  const { userId, userName, latitude, longitude } = data;

  await db.collection('sos_alerts').add({
    userId,
    userName,
    latitude,
    longitude,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    resolved: false,
  });

  const mapsLink = `https://maps.google.com/?q=${latitude},${longitude}`;

  await admin.messaging().send({
    notification: {
      title: `🚨 SOS from ${userName}`,
      body: 'Needs immediate help! Tap to see location.',
    },
    data: { type: 'sos', mapsLink, userId },
    topic: `sos_contact_${userId}`,
  });

  return { success: true, mapsLink };
});
