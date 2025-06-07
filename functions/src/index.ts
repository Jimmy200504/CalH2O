import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { foodPhotoNutritionFlow } from "./flow/foodPhotoToNutritionFlow";
import { textToNutritionFlow } from "./flow/textToNutritionFlow";
import { dailyNeedsFlow } from './flow/dailyNeedsFlow';
import { Request, Response } from "express";

// Initialize Admin SDK
admin.initializeApp();

export const foodPhotoNutrition = functionsV1
  .runWith({ timeoutSeconds: 540})
  .https.onRequest(async (req: Request, res: Response) => {
    // 只接受 POST 並且 Content-Type: application/json
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed too " });
      return;
    }
    if (!req.is("application/json")) {
      res.status(415).json({ error: "Content-Type must be application/json" });
      return;
    }
    try {
      const { image } = req.body;
      if (!image || typeof image !== "string") {
        res.status(400).json({ error: "Missing or invalid 'image' field" });
        return;
      }
      const result = await foodPhotoNutritionFlow({ image });
      res.status(200).json(result);
    } catch (error) {
      console.error("foodPhotoNutrition error:", error);
      res.status(500).json({ error: (error instanceof Error && error.message) ? error.message : String(error) });
    }
  });

export const textToNutrition = functionsV1
  .runWith({ timeoutSeconds: 540 })
  .https.onRequest(async (req: Request, res: Response) => {
    // 只接受 POST 並且 Content-Type: application/json
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed" });
      return;
    }
    if (!req.is("application/json")) {
      res.status(415).json({ error: "Content-Type must be application/json" });
      return;
    }
    try {
      const { chatHistory, prevNutrition, text } = req.body;
      if (
        typeof chatHistory !== "string" ||
        !prevNutrition || typeof prevNutrition !== "object" ||
        typeof text !== "string"
      ) {
        res.status(400).json({ error: "Missing or invalid fields: chatHistory, prevNutrition, text" });
        return;
      } 
      const result = await textToNutritionFlow({ chatHistory, prevNutrition, text });
      res.status(200).json(result);
    } catch (error) {
      console.error("textToNutrition error:", error);
    res.status(500).json({
      error: error instanceof Error && error.message ? error.message : String(error),
    });
  }
});

// Handle daily needs and store to Firestore
export const dailyNeeds = functionsV1
  .runWith({ timeoutSeconds: 540 })
  .https.onRequest(async (req: Request, res: Response) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }
    if (!req.is('application/json')) {
      res.status(415).json({ error: 'Content-Type must be application/json' });
      return;
    }
    try {
      const { userId, gender, birthday, height, weight, activityLevel, goal } = req.body;
      if (
        typeof userId !== 'string' ||
        typeof gender !== 'string' ||
        typeof birthday !== 'string' ||
        typeof height !== 'number' ||
        typeof weight !== 'number' ||
        typeof activityLevel !== 'string' ||
        typeof goal !== 'string'
      ) {
        res.status(400).json({ error: 'Missing or invalid fields' });
        return;
      }
      // Validate enum values
      const validGenders = ["Men", "Women", "Other"] as const;
      const validActivities = ["sedentary","light","active","very active","extra active"] as const;
      const validGoals = ["gain weight","maintain weight","lose weight","drink more water"] as const;
      if (
        !validGenders.includes(gender as any) ||
        !validActivities.includes(activityLevel as any) ||
        !validGoals.includes(goal as any)
      ) {
        res.status(400).json({ error: 'Invalid enum value for gender, activityLevel, or goal' });
        return;
      }
      // Call flow
      const result = await dailyNeedsFlow({
        gender: gender as typeof validGenders[number],
        birthday,
        height,
        weight,
        activityLevel: activityLevel as typeof validActivities[number],
        goal: goal as typeof validGoals[number],
      });
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .set(
          {...result},
           { merge: true }   
        );
      res.status(200).json(result);
    } catch (error: any) {
      console.error('dailyNeeds error:', error);
      res.status(500).json({ error: error.message || String(error) });
    }
  });
