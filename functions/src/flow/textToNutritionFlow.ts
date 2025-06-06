import { z } from "genkit";
import { ai } from "../config";

// --- 型別定義 ---
export const FoodItemSchema = z.object({
  name: z.string(),
  amount: z.string(), // e.g. "100g", "1 bowl"
});
export type FoodItem = z.infer<typeof FoodItemSchema>;

export const NutritionSchema = z.object({
  calories: z.number(),
  carbohydrate: z.number(),
  protein: z.number(),
  fat: z.number(),
});
export type Nutrition = z.infer<typeof NutritionSchema>;

// --- 單一 prompt ---
const textToNutritionPrompt = ai.definePrompt({
  name: "textToNutritionPrompt",
  model: "vertexai/gemini-2.0-flash",
  messages: `You are a professional nutritionist. 
  Given the following context:
  - chatHistory: the full conversation history between user and AI, as a single string (latest last)
  - prevNutrition: the previous nutrition analysis result, with the following fields:
      - calories
      - carbohydrate
      - protein
      - fat
  - userInput: the latest user message

  Your task:
  1. If the user is asking to correct or update the previous nutrition result, use their description and prevNutrition to make corrections and output the corrected nutrition.
  2. If the user is describing a new meal, ignore prevNutrition and generate a new nutrition analysis based on their description.
  3. If the input is unrelated to food, only return a comment telling the user their input is not related to food, and do not output nutrition.
  4. Always give a short, positive, and encouraging comment to the user about their meal and encourage them to keep recording.

  Return a valid JSON object with:
  - If nutrition is available: "nutrition": {calories, carbohydrate, protein, fat (all numbers)}, "comment": string
  - If not related to food: only "comment": string

  Do not include any extra commentary or explanation. Only output valid JSON.

  chatHistory: {{chatHistory}}
  prevNutrition: calories={{prevNutrition.calories}}, carbohydrate={{prevNutrition.carbohydrate}}, protein={{prevNutrition.protein}}, fat={{prevNutrition.fat}}
  userInput: {{text}}
  `,
  input: {
    schema: z.object({
      chatHistory: z.string().describe("Full conversation history as a single string, latest last"),
      prevNutrition: NutritionSchema.describe("Previous nutrition result, or empty if none"),
      text: z.string().describe("A user description of foods consumed or correction request"),
    }),
  },
  output: {
    schema: z.object({
      nutrition: NutritionSchema.optional(),
      comment: z.string(),
    }),
  },
});

// --- Flow ---
export const textToNutritionFlow = ai.defineFlow({
  name: "textToNutritionFlow",
  inputSchema: z.object({
    chatHistory: z.string(),
    prevNutrition: NutritionSchema,
    text: z.string(),
  }),
  outputSchema: z.object({
    calories: z.number().optional(),
    carbohydrate: z.number().optional(),
    protein: z.number().optional(),
    fat: z.number().optional(),
    comment: z.string(),
  }),
},
async (input) => {
  try {
    const response = await textToNutritionPrompt({
      chatHistory: input.chatHistory,
      prevNutrition: input.prevNutrition,
      text: input.text,
    });
    if (!response?.output) {
      throw new Error("Failed to analyze nutrition from text");
    }
    const { nutrition, comment } = response.output;
    // 判斷 AI 回傳的 nutrition 是否合理，若無法判斷則只回傳 comment
    const isNutritionValid = nutrition &&
      typeof nutrition.calories === 'number' && nutrition.calories > 0 &&
      typeof nutrition.carbohydrate === 'number' &&
      typeof nutrition.protein === 'number' &&
      typeof nutrition.fat === 'number';
    if (!isNutritionValid) {
      return { comment: comment || '你輸入的內容與飲食無關，請重新描述你吃了什麼。' };
    }
    return { ...nutrition, comment };
  } catch (error) {
    console.warn("Error in textToNutritionFlow:", error);
    return { comment: '你輸入的內容與飲食無關，請重新描述你吃了什麼。' };
  }
});
