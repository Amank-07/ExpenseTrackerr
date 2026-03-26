/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const twilio = require("twilio");

admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

/**
 * Sends a monthly expense summary SMS using Twilio.
 *
 * Flutter calls this endpoint with:
 * - Authorization: Bearer <FirebaseIDToken>
 * - body: { toPhoneNumber, userEmail, currentBalance, monthlySpending }
 *
 * IMPORTANT: Twilio credentials must be set on the backend (Firebase Functions secrets),
 * never in the frontend app.
 */
exports.sendSmsSummary = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed. Use POST." });
    }

    const authHeader = req.get("Authorization") || "";
    if (!authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Missing Firebase auth token." });
    }
    const idToken = authHeader.substring("Bearer ".length);
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;

    const {
      toPhoneNumber,
      userEmail,
      currentBalance,
      monthlySpending,
    } = req.body || {};

    if (!toPhoneNumber || typeof toPhoneNumber !== "string") {
      return res.status(400).json({ error: "toPhoneNumber is required." });
    }
    if (!userEmail || typeof userEmail !== "string") {
      return res.status(400).json({ error: "userEmail is required." });
    }
    if (typeof currentBalance !== "number") {
      return res.status(400).json({ error: "currentBalance must be a number." });
    }
    if (typeof monthlySpending !== "number") {
      return res.status(400).json({ error: "monthlySpending must be a number." });
    }

    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const fromNumber = process.env.TWILIO_FROM_NUMBER;

    if (!accountSid || !authToken || !fromNumber) {
      return res.status(500).json({
        error:
          "Twilio credentials are missing on the server. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER secrets.",
      });
    }

    const client = twilio(accountSid, authToken);

    const message = [
      "Expense Tracker Summary",
      `User: ${userEmail}`,
      `Current Balance: Rs ${currentBalance.toFixed(2)}`,
      `Monthly Spending: Rs ${monthlySpending.toFixed(2)}`,
    ].join("\n");

    // Send SMS
    const twilioResult = await client.messages.create({
      body: message,
      to: toPhoneNumber,
      from: fromNumber,
    });

    logger.info("Twilio SMS sent", {
      uid,
      to: toPhoneNumber,
      messageSid: twilioResult.sid,
    });

    return res.json({ success: true, messageSid: twilioResult.sid });
  } catch (e) {
    logger.error("Failed to send Twilio SMS", e);
    return res.status(500).json({ error: e?.message || "Unknown error" });
  }
});
