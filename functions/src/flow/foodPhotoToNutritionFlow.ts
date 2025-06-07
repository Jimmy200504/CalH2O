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

// --- 第一個 prompt：從照片中提取食物資訊 ---
const extractFoodItemsPrompt = ai.definePrompt({
  name: "extractFoodItemsPrompt",
  model: "vertexai/gemini-2.5-pro-preview-05-06",
  messages: `You are a professional food recognition expert. 
  Given the following food photo, 
  1. list all foods in the image and estimate their amount as precisely as possible (use specific units, e.g., grams, ml, pieces).
  2. if there are multiple foods in the image, list them all.
  3. if the image is not a food photo, return an empty array.
  \n\n
  Return a valid JSON object with a "foods" array, where each object has "name" and "amount" fields.
  If there are no foods in the image, return an empty array.\n\n
  Also return a name of the image "imageName", ex. "cheese burger".
  Do not include any extra commentary or explanation. 
  Only output valid JSON.\n\n
  {{media url=image}}`,
  input: {
    schema: z.object({
      image: z.string().describe("A photo in base64 format"),
    }),
  },
  output: {
    schema: z.object({
      foods: z.array(FoodItemSchema).optional(),
      imageName: z.string().optional(),
    }),
  },
});

// --- 第二個 prompt：計算營養資訊 ---
const calculateNutritionPrompt = ai.definePrompt({
  name: "calculateNutritionPrompt",
  model: "vertexai/gemini-2.0-flash",
  messages: `You are a professional nutritionist. 
  Given the following list of foods and their amounts, 
  calculate the total nutrition facts: calories (kcal), carbohydrate (g), protein (g), and fat (g).

  Food List:
  {{#each foods}}
  - {{name}}: {{amount}}
  {{/each}}

  Return a valid JSON object with fields "calories", "carbohydrate", "protein", "fat" (all numbers).

  Do not include any extra commentary or explanation. Only output valid JSON.`,
  input: {
    schema: z.object({
      foods: z.array(FoodItemSchema),
    }),
  },
  output: {
    schema: NutritionSchema,
  },
});

// --- 合併後的 flow ---
export const foodPhotoNutritionFlow = ai.defineFlow({
  name: "foodPhotoNutritionFlow",
  inputSchema: z.object({ image: z.string() }),
  outputSchema: z.object({
    calories: z.number(),
    carbohydrate: z.number(),
    protein: z.number(),
    fat: z.number(),
    imageName: z.string().optional(),
  }),
},
async (input) => {
  try {
    // 第一步：從照片中提取食物資訊
    const foodResponse = await extractFoodItemsPrompt({ image: input.image });
    if (!foodResponse?.output) {
      throw new Error("Failed to extract food items from image");
    }
    const { foods, imageName } = foodResponse.output;

    console.log("Image Analyzation finished");
    console.log("foods", foods);

    // 第二步：計算營養資訊
    const nutritionResponse = await calculateNutritionPrompt({ foods: foods ?? [] });
    if (!nutritionResponse?.output) {
      throw new Error("Failed to calculate nutrition information");
    }
    const nutrition = nutritionResponse.output;

    console.log("Nutrition Calculation finished");
    console.log("nutrition", nutrition);

    return {...nutrition, imageName};
  } catch (error) {
    console.warn("Error in foodPhotoNutritionFlow:", error);
    throw error;
  }
});