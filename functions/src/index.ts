import * as functionsV1 from "firebase-functions/v1";
import { foodPhotoNutritionFlow } from "./flow/foodPhotoToNutritionFlow";
import { Request, Response } from "express";

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
