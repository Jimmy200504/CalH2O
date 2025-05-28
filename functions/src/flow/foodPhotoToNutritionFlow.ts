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

// --- Prompt 1: 辨識食物與份量 ---
const recognizeFoodPrompt = ai.definePrompt({
  name: "recognizeFoodPrompt",
  messages: `You are a professional nutritionist. Analyze the following food photo and identify each individual food item present. For each item, provide a **precise** quantity—use specific units (e.g., grams, ml, pieces) and avoid ranges or approximations.\n\nReturn the result as a JSON array. Each object must contain:\n- \"name\": the name of the food\n- \"amount\": the exact quantity with unit\n\nDo not include any extra commentary or explanation. Only output valid JSON.\n\n{{media url=image}}`,
  input: {
    schema: z.object({
      image: z.string().describe("A photo in base64 format"),
    }),
  },
  output: {
    schema: z.object({ foods: z.array(FoodItemSchema) }),
  },
});

// --- Prompt 2: 計算營養成分 ---
const nutritionAnalysisPrompt = ai.definePrompt({
  name: "nutritionAnalysisPrompt",
  messages: `You are a professional nutritionist.  \nGiven the following list of foods with their amounts, 
  estimate the **total nutrition values** for the entire list and avoid ranges or approximations.\n\n
  Include the following fields (units in parentheses):  \n- \"calories\" (kcal)  \n- \"carbohydrate\" (g)  \n- \"protein\" (g)  \n- \"fat\" (g)  \n\n
  Return only a valid JSON object with **numeric values**, without any explanation or extra text.\n\nFoods: {{foods}}`,
  input: {
    schema: z.object({ foods: z.string() }),
  },
  output: {
    schema: NutritionSchema,
  },
});

// --- Flow 1: 辨識食物 ---
export const recognizeFoodFlow = ai.defineFlow({
  name: "recognizeFoodFlow",
  inputSchema: z.object({ image: z.string() }),
  outputSchema: z.object({ foods: z.array(FoodItemSchema) }),
},
async (input) => {
  try {
    const response = await recognizeFoodPrompt({ image: input.image });
    if (!response?.output) {
      throw new Error("Failed to recognize foods from image");
    }
    return response.output;
  } catch (error) {
    console.warn("Error in recognizeFoodFlow:", error);
    throw error;
  }
});

// --- Flow 2: 計算營養成分 ---
export const nutritionAnalysisFlow = ai.defineFlow({
  name: "nutritionAnalysisFlow",
  inputSchema: z.object({ foods: z.string() }),
  outputSchema: NutritionSchema,
},
async (input) => {
  try {
    const response = await nutritionAnalysisPrompt({ foods: input.foods });
    if (!response?.output) {
      throw new Error("Failed to analyze nutrition");
    }
    return response.output;
  } catch (error) {
    console.warn("Error in nutritionAnalysisFlow:", error);
    throw error;
  }
});

// --- 串接兩個 flow ---
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
  let foods: FoodItem[] = [];
  let nutrition: Nutrition = { calories: 0, carbohydrate: 0, protein: 0, fat: 0 };
  try {
    const foodResult = await recognizeFoodFlow({ image: input.image });
    foods = foodResult.foods;
    if (!foods || foods.length === 0) {
      throw new Error("No foods recognized in the image");
    }
  } catch (error) {
    console.warn("Error recognizing foods:", error);
    throw error;
  }
  try {
    const foodsString = JSON.stringify(foods);
    nutrition = await nutritionAnalysisFlow({ foods: foodsString });
  } catch (error) {
    console.warn("Error analyzing nutrition:", error);
    throw error;
  }
  return { foods, ...nutrition };
});