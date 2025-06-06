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
const foodAndNutritionPrompt = ai.definePrompt({
  name: "foodAndNutritionPrompt",
  model: "vertexai/gemini-2.5-pro-preview-05-06",
  messages: `You are a professional nutritionist. Given the following food photo, do the following in one step:\n\n1. List all foods in the image and estimate their amount as precisely as possible (use specific units, e.g., grams, ml, pieces).\n2. For the recognized foods and their amounts, estimate the total nutrition facts: calories (kcal), carbohydrate (g), protein (g), and fat (g).\n\nReturn a valid JSON object with two fields:\n- \"foods\": an array of objects, each with \"name\" and \"amount\"\n- \"nutrition\": an object with fields \"calories\", \"carbohydrate\", \"protein\", \"fat\" (all numbers)\n\nDo not include any extra commentary or explanation. Only output valid JSON.\n\n{{media url=image}}`,
  input: {
    schema: z.object({
      image: z.string().describe("A photo in base64 format"),
    }),
  },
  output: {
    schema: z.object({
      foods: z.array(FoodItemSchema),
      nutrition: NutritionSchema,
    }),
  },
});

// --- 合併後的 flow ---
export const foodPhotoNutritionFlow = ai.defineFlow({
  name: "foodPhotoNutritionFlow",
  inputSchema: z.object({ image: z.string() }),
  outputSchema: z.object({
    foods: z.array(FoodItemSchema),
    calories: z.number(),
    carbohydrate: z.number(),
    protein: z.number(),
    fat: z.number(),
  }),
},
async (input) => {
  try {
    const response = await foodAndNutritionPrompt({ image: input.image });
    if (!response?.output) {
      throw new Error("Failed to analyze food and nutrition from image");
    }
    const { foods, nutrition } = response.output;
    return { foods, ...nutrition };
  } catch (error) {
    console.warn("Error in foodPhotoNutritionFlow:", error);
    throw error;
  }
});