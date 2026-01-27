const functions = require("firebase-functions");

const CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";
const CLAUDE_MODEL = "claude-haiku-4-5";

// Get Claude API key from Firebase config
const getApiKey = () => {
  return process.env.CLAUDE_API_KEY || functions.config().claude?.api_key;
};

// Set CORS headers - restricted to app requests only
// In production, consider using Firebase App Check for additional security
const setCorsHeaders = (res) => {
  // Allow requests from the app (mobile apps don't send Origin header)
  // For web testing, you can temporarily add specific origins
  res.set("Access-Control-Allow-Origin", "*"); // TODO: Consider Firebase App Check for production
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
};

// Input validation constants
const MAX_HABIT_NAME_LENGTH = 100;
const MAX_AI_PROMPT_LENGTH = 2000;
const MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024; // 10MB

// Sanitize user input to prevent prompt injection
// Escapes characters that could be used to break out of prompt context
const sanitizeForPrompt = (input) => {
  if (!input || typeof input !== 'string') return '';

  // Limit length
  let sanitized = input.slice(0, MAX_AI_PROMPT_LENGTH);

  // Escape characters that could be used for prompt injection
  sanitized = sanitized
    .replace(/\\/g, '\\\\')  // Escape backslashes
    .replace(/"/g, '\\"')    // Escape quotes
    .replace(/\n/g, ' ')     // Replace newlines with spaces
    .replace(/\r/g, '')      // Remove carriage returns
    .trim();

  return sanitized;
};

// Validate habit name
const validateHabitName = (name) => {
  if (!name || typeof name !== 'string') {
    return { valid: false, error: 'Habit name is required' };
  }
  if (name.trim().length === 0) {
    return { valid: false, error: 'Habit name cannot be empty' };
  }
  if (name.length > MAX_HABIT_NAME_LENGTH) {
    return { valid: false, error: `Habit name must be ${MAX_HABIT_NAME_LENGTH} characters or less` };
  }
  return { valid: true };
};

// Validate AI prompt
const validateAIPrompt = (prompt) => {
  if (prompt && typeof prompt === 'string' && prompt.length > MAX_AI_PROMPT_LENGTH) {
    return { valid: false, error: `AI prompt must be ${MAX_AI_PROMPT_LENGTH} characters or less` };
  }
  return { valid: true };
};

// Prompts for each verification type
const PROMPTS = {
  bed: `ROLE: You are a friendly morning habit verifier. Your job is to answer: "Did this person make their bed?"

This is NOT a hotel inspection. Normal wrinkles, natural fabric draping, and everyday bed-making are totally fine. Only fail beds that are genuinely unmade.

IMPORTANT: The user only sees PASS or FAIL with your feedback message. They do NOT see any scores. Never mention scores, points, or numbers in your feedback.

═══════════════════════════════════════════════════════════════
STEP 1: IDENTIFY WHAT'S IN THE PHOTO
═══════════════════════════════════════════════════════════════
First, describe what you ACTUALLY see. Set detected_subject to one of:
- "bed" - if a real bed with mattress/bedding is visible
- "bathroom" - toilet, shower, sink, etc.
- "kitchen" - stove, fridge, counters, etc.
- "desk" - workspace, computer setup
- "couch" - sofa or loveseat (NOT a bed)
- "screenshot" - clearly a photo of a screen or another photo
- "stock_photo" - unnaturally perfect/staged, watermarks, or obviously not personal
- "other" - anything else (pet, food, random object, person without bed)

If detected_subject is NOT "bed", respond immediately:
{"is_made": false, "detected_subject": "[what you see]", "feedback": "I see [specific thing], but I need to see your bed!"}

═══════════════════════════════════════════════════════════════
STEP 2: SCORE THE BED (only if bed is visible)
═══════════════════════════════════════════════════════════════
Ask yourself: "Did they make their bed?" NOT "Is this hotel-quality?"

DUVET/COMFORTER (0-35):
  35: Pulled up and covering the bed (wrinkles are fine!)
  25: Mostly covering, some bunching at edges
  15: Partially pulled up but effort visible
  0:  Not pulled up at all - mattress/sheets fully exposed

PILLOWS (0-35):
  35: Placed on bed (arranged, stacked, or just set there - all fine!)
  25: On bed but messy/fallen over
  15: Partially off bed or half-effort
  0:  Missing, on floor, or scattered around room

OVERALL EFFORT (0-30):
  30: Clearly made an effort - this is a made bed
  20: Quick job but they tried
  10: Minimal effort visible
  0:  No attempt / obviously just woke up and left

═══════════════════════════════════════════════════════════════
STEP 3: RESPOND
═══════════════════════════════════════════════════════════════
- is_made = true if score >= 50
- Be encouraging! This is about building a morning habit, not perfection.
- Feedback must be SPECIFIC to what you see. Keep it to 2 sentences max. NEVER mention scores/points/numbers.
  * Pass (high effort): Celebrate! ("Nice work! Your bed looks great.")
  * Pass (decent effort): Positive acknowledgment ("Bed's made - you're good to go!")
  * Fail (almost there): Helpful, not harsh ("Just pull that comforter up and you're set!")
  * Fail (not made): Friendly nudge ("Looks like the bed still needs making - pull up that blanket!")

JSON format (detected_subject required):
{"is_made": boolean, "detected_subject": "bed", "feedback": "specific message"}`,

  sunlight: `TASK: Verify this photo shows NATURAL LIGHT exposure.

═══════════════════════════════════════════════════════════════
STEP 1: IDENTIFY WHAT'S IN THE PHOTO
═══════════════════════════════════════════════════════════════
Set detected_subject to what best describes the scene:
- "outdoor_daylight" - outside with natural sunlight/daylight
- "window_daylight" - indoors but with visible natural light from windows
- "dark_indoor" - indoor space with no natural light
- "artificial_light" - room lit only by lamps/screens/LEDs
- "nighttime" - clearly night (dark sky, stars, moon)
- "screenshot" - photo of a screen or another image
- "unrelated" - random object with no light context

═══════════════════════════════════════════════════════════════
STEP 2: DETERMINE PASS/FAIL
═══════════════════════════════════════════════════════════════
PASS (is_outside: true) if:
- Outdoor daylight (sunny, overcast, cloudy all count)
- Indoors with visible natural daylight through windows

FAIL (is_outside: false) if:
- Nighttime scene
- Only artificial lighting visible
- Dark indoor space
- Screenshot or unrelated image

═══════════════════════════════════════════════════════════════
STEP 3: RESPOND WITH SPECIFIC FEEDBACK
═══════════════════════════════════════════════════════════════
Keep feedback to 2 sentences max.
- If unrelated/screenshot: "I see [what's there], but I need to see natural light exposure!"
- If artificial light only: "That's artificial light - step outside or near a window!"
- If nighttime: "It's dark out! Catch some rays tomorrow morning."
- If passed: Acknowledge the light ("Beautiful morning light!" or "Good window setup!")

JSON format:
{"is_outside": boolean, "detected_subject": "category", "feedback": "specific message"}`,

  hydration: `TASK: Verify this photo shows HYDRATION (a beverage or drinking vessel).

═══════════════════════════════════════════════════════════════
STEP 1: IDENTIFY WHAT'S IN THE PHOTO
═══════════════════════════════════════════════════════════════
Set detected_subject to what you see:
- "water_bottle" - reusable water bottle or tumbler
- "glass" - drinking glass with beverage
- "mug" - coffee mug or tea cup
- "person_drinking" - someone actively drinking
- "food" - food items (not drinks)
- "electronics" - phone, computer, etc.
- "furniture" - bed, desk, couch
- "screenshot" - photo of a screen
- "other" - anything else unrelated

═══════════════════════════════════════════════════════════════
STEP 2: DETERMINE PASS/FAIL
═══════════════════════════════════════════════════════════════
PASS (is_water: true) if:
- Any drinking vessel visible (full, partially full, or empty)
- Person actively drinking
- Water, coffee, tea, juice, smoothie, sports drink - all count!

FAIL (is_water: false) if:
- No drinking vessel at all
- Only food, no drinks
- Random objects, electronics, furniture

Be lenient - the goal is encouraging hydration!

═══════════════════════════════════════════════════════════════
STEP 3: SPECIFIC FEEDBACK
═══════════════════════════════════════════════════════════════
Keep feedback to 2 sentences max.
- If wrong subject: "I see [what's there], but where's your drink?"
- If passed: Acknowledge what you see ("Nice water bottle!" or "Coffee counts!")
- Empty vessel: "Already finished? That's the spirit!"

JSON format:
{"is_water": boolean, "detected_subject": "category", "feedback": "specific message"}`,

  healthyBreakfast: `TASK: Verify this photo shows a HEALTHY BREAKFAST.

═══════════════════════════════════════════════════════════════
STEP 1: IDENTIFY WHAT'S IN THE PHOTO
═══════════════════════════════════════════════════════════════
Set detected_subject to one of:
- "healthy_meal" - fruits, vegetables, eggs, oatmeal, yogurt, whole grains, smoothie, avocado toast
- "unhealthy_meal" - donuts, sugary cereal, pastries, candy, chips
- "beverage_only" - just coffee/tea with no food
- "screenshot" - photo of a screen
- "other" - unrelated content

═══════════════════════════════════════════════════════════════
STEP 2: DETERMINE PASS/FAIL
═══════════════════════════════════════════════════════════════
PASS (is_verified: true) if:
- Nutritious food visible: eggs, avocado, oatmeal, yogurt, fruit, vegetables, whole grain toast, smoothie
- Mixed meals count if they include healthy components

FAIL (is_verified: false) if:
- Only sugary/processed foods (donuts, pastries, sugary cereal)
- No food visible (beverage only)
- Unrelated content

Be encouraging about healthy eating choices!

═══════════════════════════════════════════════════════════════
STEP 3: SPECIFIC FEEDBACK
═══════════════════════════════════════════════════════════════
Keep feedback to 2 sentences max.
- If passed: Celebrate the healthy choice! ("Great choice! Protein and fiber to fuel your morning.")
- If failed (unhealthy): Gentle nudge ("That looks tasty, but try adding some fruit or eggs!")
- If unrelated: "I see [what's there], but where's your breakfast?"

JSON format:
{"is_verified": boolean, "detected_subject": "category", "feedback": "specific message"}`,

  morningJournal: `TASK: Verify this photo shows a JOURNAL with writing.

═══════════════════════════════════════════════════════════════
STEP 1: IDENTIFY WHAT'S IN THE PHOTO
═══════════════════════════════════════════════════════════════
Set detected_subject to one of:
- "journal_writing" - open notebook/journal with visible handwriting
- "journal_closed" - closed notebook or journal
- "journal_blank" - open but blank pages
- "digital_journal" - tablet or phone showing notes app with writing
- "screenshot" - photo of a screen showing something else
- "other" - unrelated content

═══════════════════════════════════════════════════════════════
STEP 2: DETERMINE PASS/FAIL
═══════════════════════════════════════════════════════════════
PASS (is_verified: true) if:
- Open journal/notebook with visible handwriting (doesn't need to be readable)
- Digital notes app showing today's writing

FAIL (is_verified: false) if:
- Closed journal (no proof of writing)
- Blank pages
- Unrelated content

═══════════════════════════════════════════════════════════════
STEP 3: SPECIFIC FEEDBACK
═══════════════════════════════════════════════════════════════
Keep feedback to 2 sentences max.
- If passed: Acknowledge the effort ("Love to see those morning thoughts on paper!")
- If closed: "Open it up and show me today's entry!"
- If blank: "Those pages look empty - time to write!"

JSON format:
{"is_verified": boolean, "detected_subject": "category", "feedback": "specific message"}`,

  vitamins: `TASK: Verify this photo shows VITAMINS or SUPPLEMENTS being taken.

═══════════════════════════════════════════════════════════════
STEP 1: IDENTIFY WHAT'S IN THE PHOTO
═══════════════════════════════════════════════════════════════
Set detected_subject to one of:
- "vitamins_visible" - vitamin bottles, pill organizers, loose vitamins/supplements
- "person_taking" - someone holding or taking vitamins
- "pill_organizer" - weekly pill organizer with compartments
- "screenshot" - photo of a screen
- "other" - unrelated content

═══════════════════════════════════════════════════════════════
STEP 2: DETERMINE PASS/FAIL
═══════════════════════════════════════════════════════════════
PASS (is_verified: true) if:
- Vitamins, supplements, or pill organizer visible
- Person actively taking vitamins

FAIL (is_verified: false) if:
- No vitamins or supplements visible
- Unrelated content

Be encouraging - taking vitamins is a great habit!

═══════════════════════════════════════════════════════════════
STEP 3: SPECIFIC FEEDBACK
═══════════════════════════════════════════════════════════════
Keep feedback to 2 sentences max.
- If passed: "Nice! Keeping up with your supplements."
- If wrong subject: "I see [what's there], but where are your vitamins?"

JSON format:
{"is_verified": boolean, "detected_subject": "category", "feedback": "specific message"}`,

  skincare: `TASK: Verify this photo shows SKINCARE products or routine.

═══════════════════════════════════════════════════════════════
STEP 1: IDENTIFY WHAT'S IN THE PHOTO
═══════════════════════════════════════════════════════════════
Set detected_subject to one of:
- "skincare_products" - moisturizer, serum, sunscreen, cleanser, toner
- "person_applying" - someone applying skincare products
- "makeup_only" - only makeup products (not skincare)
- "screenshot" - photo of a screen
- "other" - unrelated content

═══════════════════════════════════════════════════════════════
STEP 2: DETERMINE PASS/FAIL
═══════════════════════════════════════════════════════════════
PASS (is_verified: true) if:
- Skincare products visible (moisturizer, sunscreen, serum, cleanser, etc.)
- Person applying skincare

FAIL (is_verified: false) if:
- Only makeup products (no skincare)
- Unrelated content

═══════════════════════════════════════════════════════════════
STEP 3: SPECIFIC FEEDBACK
═══════════════════════════════════════════════════════════════
Keep feedback to 2 sentences max.
- If passed: "Your skin will thank you! Great routine."
- If makeup only: "I see makeup, but show me your skincare products!"
- If unrelated: "I see [what's there], but where's your skincare?"

JSON format:
{"is_verified": boolean, "detected_subject": "category", "feedback": "specific message"}`,

  mealPrep: `TASK: Verify this photo shows MEAL PREP.

═══════════════════════════════════════════════════════════════
STEP 1: IDENTIFY WHAT'S IN THE PHOTO
═══════════════════════════════════════════════════════════════
Set detected_subject to one of:
- "meal_containers" - food storage containers with prepared meals
- "packed_lunch" - lunch box or bag with food
- "prep_in_progress" - actively cooking or chopping ingredients
- "groceries" - raw ingredients not being prepped
- "screenshot" - photo of a screen
- "other" - unrelated content

═══════════════════════════════════════════════════════════════
STEP 2: DETERMINE PASS/FAIL
═══════════════════════════════════════════════════════════════
PASS (is_verified: true) if:
- Meal prep containers with food inside
- Packed lunch/lunchbox ready to go
- Active food preparation (cooking, chopping, assembling)

FAIL (is_verified: false) if:
- Empty containers
- Just raw groceries sitting there
- Unrelated content

═══════════════════════════════════════════════════════════════
STEP 3: SPECIFIC FEEDBACK
═══════════════════════════════════════════════════════════════
Keep feedback to 2 sentences max.
- If passed: "Prepped and ready! That's setting yourself up for success."
- If groceries: "Great ingredients! Now let's see them prepped."
- If unrelated: "I see [what's there], but where's your meal prep?"

JSON format:
{"is_verified": boolean, "detected_subject": "category", "feedback": "specific message"}`
};

// Helper to call Claude API
async function callClaudeAPI(apiKey, imageBase64, prompt, maxTokens = 512) {
  const requestBody = {
    model: CLAUDE_MODEL,
    max_tokens: maxTokens,
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: "image/jpeg",
              data: imageBase64
            }
          },
          {
            type: "text",
            text: prompt
          }
        ]
      }
    ]
  };

  const response = await fetch(CLAUDE_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "anthropic-version": "2023-06-01",
      "x-api-key": apiKey
    },
    body: JSON.stringify(requestBody)
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error(`Claude API error: ${response.status} - ${errorText}`);
    throw new Error(`Claude API error: ${response.status}`);
  }

  const data = await response.json();
  const textContent = data.content.find(c => c.type === "text");

  if (!textContent || !textContent.text) {
    throw new Error("No text response from Claude");
  }

  // Extract JSON from response
  let responseText = textContent.text.trim();

  // Remove markdown code blocks if present
  if (responseText.startsWith("```json")) {
    responseText = responseText.slice(7);
  } else if (responseText.startsWith("```")) {
    responseText = responseText.slice(3);
  }
  if (responseText.endsWith("```")) {
    responseText = responseText.slice(0, -3);
  }
  responseText = responseText.trim();

  // Find JSON object
  const jsonStart = responseText.indexOf("{");
  const jsonEnd = responseText.lastIndexOf("}");
  if (jsonStart !== -1 && jsonEnd !== -1) {
    responseText = responseText.slice(jsonStart, jsonEnd + 1);
  }

  return JSON.parse(responseText);
}

// Verify Bed endpoint
exports.verifyBed = functions
  .runWith({ secrets: ["CLAUDE_API_KEY"] })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const { imageBase64 } = req.body;

      if (!imageBase64) {
        res.status(400).json({ error: "Missing imageBase64" });
        return;
      }

      const result = await callClaudeAPI(
        getApiKey(),
        imageBase64,
        PROMPTS.bed,
        512
      );

      res.json(result);
    } catch (error) {
      console.error("verifyBed error:", error);
      res.status(500).json({ error: "Verification failed" });
    }
  });

// Verify Sunlight endpoint
exports.verifySunlight = functions
  .runWith({ secrets: ["CLAUDE_API_KEY"] })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const { imageBase64 } = req.body;

      if (!imageBase64) {
        res.status(400).json({ error: "Missing imageBase64" });
        return;
      }

      const result = await callClaudeAPI(
        getApiKey(),
        imageBase64,
        PROMPTS.sunlight,
        256
      );

      res.json(result);
    } catch (error) {
      console.error("verifySunlight error:", error);
      res.status(500).json({ error: "Verification failed" });
    }
  });

// Verify Hydration endpoint
exports.verifyHydration = functions
  .runWith({ secrets: ["CLAUDE_API_KEY"] })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const { imageBase64 } = req.body;

      if (!imageBase64) {
        res.status(400).json({ error: "Missing imageBase64" });
        return;
      }

      const result = await callClaudeAPI(
        getApiKey(),
        imageBase64,
        PROMPTS.hydration,
        256
      );

      res.json(result);
    } catch (error) {
      console.error("verifyHydration error:", error);
      res.status(500).json({ error: "Verification failed" });
    }
  });

// Verify Custom Habit endpoint
exports.verifyCustomHabit = functions
  .runWith({ secrets: ["CLAUDE_API_KEY"] })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const { imageBase64, habitName, aiPrompt, allowsScreenshots } = req.body;

      if (!imageBase64 || !habitName) {
        res.status(400).json({ error: "Missing required fields" });
        return;
      }

      // Validate and sanitize inputs to prevent prompt injection
      const habitNameValidation = validateHabitName(habitName);
      if (!habitNameValidation.valid) {
        res.status(400).json({ error: habitNameValidation.error });
        return;
      }

      const aiPromptValidation = validateAIPrompt(aiPrompt);
      if (!aiPromptValidation.valid) {
        res.status(400).json({ error: aiPromptValidation.error });
        return;
      }

      // Sanitize inputs before using in prompt
      const sanitizedHabitName = sanitizeForPrompt(habitName);
      const sanitizedCriteria = aiPrompt ? sanitizeForPrompt(aiPrompt) : "Verify that this habit has been completed.";

      const screenshotGuidance = allowsScreenshots ? `SCREENSHOT POLICY: Screenshots ARE ACCEPTED for this habit.
- Screenshots showing app interfaces, phone calls, messages, or activity are valid proof
- Only reject screenshots if they're obviously fake, heavily edited, or completely unrelated
- Focus on whether the screenshot shows legitimate proof of the habit` : `SCREENSHOT POLICY: Screenshots are NOT ACCEPTED for this habit.
- If this appears to be a screenshot (phone screen, app interface, status bar visible), reject it
- The user must provide a live camera photo as proof
- Politely ask them to take a real photo if you detect a screenshot`;

      const prompt = `ROLE: You are a sharp-eyed habit verification AI. Be honest, specific, and catch gaming attempts.

TASK: Verify this photo for the custom habit "${sanitizedHabitName}" using the user's criteria.

User's verification criteria: ${sanitizedCriteria}

${screenshotGuidance}

═══════════════════════════════════════════════════════════════
STEP 1: IDENTIFY WHAT'S IN THE PHOTO
═══════════════════════════════════════════════════════════════
Set detected_subject to a brief description of what you actually see.
Examples: "person exercising", "notebook with writing", "kitchen counter", "bathroom sink", "random object", "screenshot"

Gaming detection - FAIL immediately if you see:
- Stock photo / obviously not personal
- Completely unrelated to "${sanitizedHabitName}"

If unrelated, respond:
{"is_verified": false, "detected_subject": "[what you see]", "feedback": "I see [specific thing], but I need to see proof of ${sanitizedHabitName}!"}

═══════════════════════════════════════════════════════════════
STEP 2: SCORE THE PHOTO (0-100 points)
═══════════════════════════════════════════════════════════════

RELEVANCE TO HABIT (0-40):
  40: Perfectly captures the habit being done
  30: Clearly shows the habit activity
  20: Related but indirect evidence
  10: Loosely connected
  0:  Completely unrelated

CRITERIA MATCH (0-40):
  40: Fully meets user's verification criteria
  30: Mostly meets criteria
  20: Partially meets criteria
  10: Barely addresses criteria
  0:  Doesn't match at all

CLARITY & EFFORT (0-20):
  20: Clear photo, obvious effort
  15: Reasonably clear
  10: Somewhat unclear but acceptable
  5:  Poor quality but discernible
  0:  Cannot determine what's shown

═══════════════════════════════════════════════════════════════
STEP 3: RESPOND WITH SPECIFIC FEEDBACK
═══════════════════════════════════════════════════════════════
- is_verified = true ONLY if score >= 65
- Feedback must be SPECIFIC to what you see. Keep it to 2 sentences max.
  * Score >= 85: Celebrate! ("Perfect! That's exactly what I'm looking for!")
  * Score 65-84: Acknowledge with encouragement
  * Score 40-64: Name what's missing ("I see X, but I need to see Y")
  * Score < 40: Explain what would count as valid proof

JSON format (detected_subject required):
{"is_verified": boolean, "detected_subject": "brief description", "feedback": "specific message"}`;

      const result = await callClaudeAPI(
        getApiKey(),
        imageBase64,
        prompt,
        512
      );

      res.json(result);
    } catch (error) {
      console.error("verifyCustomHabit error:", error);
      res.status(500).json({ error: "Verification failed" });
    }
  });

// Verify Video endpoint
exports.verifyVideo = functions
  .runWith({ secrets: ["CLAUDE_API_KEY"] })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const { frames, habitName, aiPrompt, duration } = req.body;

      if (!frames || !Array.isArray(frames) || frames.length === 0 || !habitName) {
        res.status(400).json({ error: "Missing required fields" });
        return;
      }

      // Validate and sanitize inputs
      const habitNameValidation = validateHabitName(habitName);
      if (!habitNameValidation.valid) {
        res.status(400).json({ error: habitNameValidation.error });
        return;
      }

      const aiPromptValidation = validateAIPrompt(aiPrompt);
      if (!aiPromptValidation.valid) {
        res.status(400).json({ error: aiPromptValidation.error });
        return;
      }

      const sanitizedHabitName = sanitizeForPrompt(habitName);
      const sanitizedCriteria = aiPrompt ? sanitizeForPrompt(aiPrompt) : "Verify that this action was performed.";

      // Build content array with all frames
      const content = [];
      frames.forEach((frameBase64, index) => {
        content.push({
          type: "image",
          source: {
            type: "base64",
            media_type: "image/jpeg",
            data: frameBase64
          }
        });
        content.push({
          type: "text",
          text: `Frame ${index + 1} of ${frames.length}`
        });
      });

      const prompt = `ROLE: You are a sharp-eyed action verification AI. Analyze video frames to verify the user completed their habit.

TASK: Verify this video for the habit "${sanitizedHabitName}" using the user's criteria.

You are seeing ${frames.length} frames extracted from a ${Math.round(duration)}-second video, shown in chronological order.

User's verification criteria: ${sanitizedCriteria}

═══════════════════════════════════════════════════════════════
CRITICAL - ANALYZE AS A SEQUENCE
═══════════════════════════════════════════════════════════════
These frames show PROGRESSION over time, not separate photos:
1. Look for evidence the ACTION was actually performed
2. Verify movement/change between frames shows the activity
3. Be lenient on form/perfection but verify the core action happened

═══════════════════════════════════════════════════════════════
DETECT CHEATING
═══════════════════════════════════════════════════════════════
FAIL immediately if you detect:
- Video of a video / screen recording
- Still images with no movement between frames
- Completely unrelated content
- Someone else doing the action (not the user)

═══════════════════════════════════════════════════════════════
VERIFICATION CRITERIA
═══════════════════════════════════════════════════════════════
PASS (is_verified: true) if:
- Frames show clear progression of the described action
- The action matches the habit "${sanitizedHabitName}"
- Movement between frames indicates real activity

FAIL (is_verified: false) if:
- No relevant action visible
- Static/no movement (just showing equipment doesn't count)
- Content doesn't match the criteria
- Obvious cheating attempt

═══════════════════════════════════════════════════════════════
RESPOND WITH SPECIFIC FEEDBACK
═══════════════════════════════════════════════════════════════
Keep feedback to 2 sentences max.
- If passed: Acknowledge what you saw ("Great form on those pushups!")
- If failed: Explain specifically what was missing or wrong
- detected_action: Brief description of what you actually saw happen
- confidence: "high" if very clear, "medium" if some uncertainty, "low" if barely passed

JSON format (all fields required):
{"is_verified": boolean, "feedback": "specific message", "detected_action": "what happened", "confidence": "high/medium/low"}`;

      content.push({
        type: "text",
        text: prompt
      });

      // Call Claude API with video frames
      const requestBody = {
        model: CLAUDE_MODEL,
        max_tokens: 512,
        messages: [
          {
            role: "user",
            content: content
          }
        ]
      };

      const response = await fetch(CLAUDE_API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01",
          "x-api-key": getApiKey()
        },
        body: JSON.stringify(requestBody)
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`Claude API error: ${response.status} - ${errorText}`);
        res.status(500).json({ error: "Verification failed" });
        return;
      }

      const responseData = await response.json();
      const textContent = responseData.content.find(c => c.type === "text");

      if (!textContent || !textContent.text) {
        res.status(500).json({ error: "No text response from Claude" });
        return;
      }

      // Extract JSON from response
      let responseText = textContent.text.trim();
      if (responseText.startsWith("```json")) {
        responseText = responseText.slice(7);
      } else if (responseText.startsWith("```")) {
        responseText = responseText.slice(3);
      }
      if (responseText.endsWith("```")) {
        responseText = responseText.slice(0, -3);
      }
      responseText = responseText.trim();

      const jsonStart = responseText.indexOf("{");
      const jsonEnd = responseText.lastIndexOf("}");
      if (jsonStart !== -1 && jsonEnd !== -1) {
        responseText = responseText.slice(jsonStart, jsonEnd + 1);
      }

      res.json(JSON.parse(responseText));
    } catch (error) {
      console.error("verifyVideo error:", error);
      res.status(500).json({ error: "Verification failed" });
    }
  });

// Verify Predefined Habit endpoint (generic for new AI-verified habits)
exports.verifyPredefinedHabit = functions
  .runWith({ secrets: ["CLAUDE_API_KEY"] })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const { imageBase64, habitType } = req.body;

      if (!imageBase64 || !habitType) {
        res.status(400).json({ error: "Missing imageBase64 or habitType" });
        return;
      }

      // Look up prompt by habit type
      const prompt = PROMPTS[habitType];
      if (!prompt) {
        res.status(400).json({ error: `Unknown habit type: ${habitType}` });
        return;
      }

      const result = await callClaudeAPI(
        getApiKey(),
        imageBase64,
        prompt,
        256
      );

      res.json(result);
    } catch (error) {
      console.error("verifyPredefinedHabit error:", error);
      res.status(500).json({ error: "Verification failed" });
    }
  });
