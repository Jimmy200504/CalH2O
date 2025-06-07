import { z } from "genkit";
import { ai } from "../config";

// --- 型別定義 ---
export const UserProfileSchema = z.object({
  gender: z.enum(["Men", "Women", "Other"]).describe("性別"),
  birthday: z.string().describe("生日，格式 YYYYMMDD"),
  height: z.number().describe("身高，單位 cm"),
  weight: z.number().describe("體重，單位 kg"),
  activityLevel: z.enum([
    "sedentary",
    "light",
    "active",
    "very active",
    "extra active"
  ]).describe("活動等級"),
  goal: z.enum([
    "gain weight",
    "maintain weight",
    "lose weight",
    "drink more water"
  ]).describe("健康目標"),
});
export type UserProfile = z.infer<typeof UserProfileSchema>;

export const DailyNeedsSchema = z.object({
  calories: z.number().describe("每日建議熱量攝取，單位 kcal"),
  water: z.number().describe("每日建議水分攝取量，單位 ml"),
  proteinTarget: z.number().describe("每日建議蛋白質攝取量，單位 g"),
  carbsTarget: z.number().describe("每日建議碳水化合物攝取量，單位 g"),
  fatsTarget: z.number().describe("每日建議脂肪攝取量，單位 g"),
});
export type DailyNeeds = z.infer<typeof DailyNeedsSchema>;

const activityFactors: Record<string, number> = {
  sedentary: 1.2,
  light: 1.375,
  active: 1.55,
  "very active": 1.72,
  "extra active": 1.9,
};

// --- AI Prompt: 根據使用者目標估算額外調整係數 ---
const goalAdjustmentPrompt = ai.definePrompt({
  name: "goalAdjustmentPrompt",
  model: "vertexai/gemini-2.0-flash",
  messages: `
You are a professional dietitian. Given a user's goal, suggest an adjustment factor to apply on top of the activity multiplier.

- "gain weight": increase calories by ~10-20%.
- "maintain weight": no change.
- "lose weight": decrease calories by ~10-20%.
- "drink more water": no calorie change, increase water by ~10-20%.

Return **only** a JSON object:
{
  "calorieFactor": number,
  "waterFactor": number
}

Do not include any extra text.

User Goal: {{goal}}
  `,
  input: { schema: z.object({ goal: UserProfileSchema.shape.goal }) },
  output: { schema: z.object({ calorieFactor: z.number(), waterFactor: z.number() }) },
});

// --- AI Prompt: 計算宏量營養素分配 ---
const macroTargetsPrompt = ai.definePrompt({
  name: "macroTargetsPrompt",
  model: "vertexai/gemini-2.0-flash",
  messages: `
You are a professional dietitian. Given a user's daily calorie target, suggest an appropriate macronutrient split (protein, carbs, fats) in grams.

- Provide protein, carbs, and fats in grams.
- Use common ratios (e.g., protein 1.2-2.0g/kg body weight, carbs 45-65% of calories, fats 20-35% of calories).

Return **only** a JSON object:
{
  "proteinTarget": number,
  "carbsTarget": number,
  "fatsTarget": number
}

User Info:
- Calories: {{calories}}
- Weight: {{weight}}
- Goal: {{goal}}
  `,
  input: {
    schema: z.object({
      calories: z.number(),
      weight: z.number(),
      goal: UserProfileSchema.shape.goal
    })
  },
  output: {
    schema: z.object({
      proteinTarget: z.number(),
      carbsTarget: z.number(),
      fatsTarget: z.number()
    })
  }
});

// --- 合併成 flow ---
export const dailyNeedsFlow = ai.defineFlow({
  name: "dailyNeedsFlow",
  inputSchema: UserProfileSchema,
  outputSchema: DailyNeedsSchema,
}, async (input) => {
  const { gender, birthday, height, weight, activityLevel, goal } = input;

  // 計算年齡
  const currentYear = new Date().getFullYear();
  const birthYear = parseInt(birthday.substring(0, 4), 10);
  const age = currentYear - birthYear;

  // 計算 BMR
  let bmr: number;
  if (gender === "Men") {
    bmr = 9.99 * weight + 6.25 * height - 4.92 * age + 5;
  } else {
    bmr = 9.99 * weight + 6.25 * height - 4.92 * age - 161;
  }

  // 計算基礎 TDEE
  const baseFactor = activityFactors[activityLevel];
  const baseTDEE = Math.round(bmr * baseFactor);

  // AI 計算目標調整係數
  const adjResp = await goalAdjustmentPrompt({ goal });
  const { calorieFactor, waterFactor } = adjResp.output!;

  // 計算最終 calories 和 water
  const calories = Math.round(baseTDEE * calorieFactor);
  const water = Math.round(weight * 35 * waterFactor);

  // AI 計算宏量目標
  const macroResp = await macroTargetsPrompt({ calories, weight, goal });
  const { proteinTarget, carbsTarget, fatsTarget } = macroResp.output!;

  return { calories, water, proteinTarget, carbsTarget, fatsTarget };
});
