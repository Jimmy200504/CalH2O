import { z } from "genkit";
import { ai } from "../config";

// --- Input Schema ---
export const statusSchema = z.object({
  waterIntake: z.number().describe("Today's total water consumed in ml"),
  waterNeed: z.number().describe("Daily water requirement in ml"),
  caloriesIntake: z.number().describe("Today's total calories consumed in kcal"),
  caloriesNeed: z.number().describe("Daily calorie requirement in kcal"),
  calories: z.number().describe("Calories contained in last meal"),
  carbohydrate: z.number().describe("Carbohydrate contained in last meal"),
  protein: z.number().describe("Protein contained in last meal"),
  fat: z.number().describe("Fat contained in last meal"),
  carbTarget: z.number().describe("Daily carbs target"),
  proteinTarget: z.number().describe("Daily protein target"),
  fatTarget: z.number().describe("Daily fat target"),
  EB_Type: z.enum(["Polite", "Vicious"]).describe("Emotional blackmail style"),
});
export type Status = z.infer<typeof statusSchema>;

// --- Output Schema ---
export const ebOutputSchema = z.object({
  messages: z.array(z.string()).describe("List of blackmail messages, at least 9 items"),
});
export type EBOutput = z.infer<typeof ebOutputSchema>;

// --- Prompt Factory ---
function makePrompt(role: string) {
  return `You are a creative and ${role} (sometimes encouraging) friend. Based on the user’s daily status, generate exactly 9 stylized emotional blackmail messages.
- 6 short messages should be last than 9 words.
- Water: consumed {{waterIntake}} ml / goal {{waterNeed}} ml
- Calories: consumed {{caloriesIntake}} kcal / goal {{caloriesNeed}} kcal
- Last Meal: {{calories}} kcal, {{carbohydrate}}g carbs, {{protein}}g protein, {{fat}}g fat

Return only a JSON array of strings, e.g.: ["msg1","msg2",...]; no extra text.`;
}

// --- Prompts ---
const politePrompt = ai.definePrompt({
  name: "politeFriendPrompt",
  model: "vertexai/gemini-2.0-flash",
  messages: makePrompt("polite friend"),
  input: { schema: statusSchema.pick({ 
    waterIntake: true,
    waterNeed: true,
    caloriesIntake: true,
    caloriesNeed: true,
    calories: true,
    carbohydrate: true,
    protein: true,
    fat: true,
    carbTarget: true,
    proteinTarget: true,
    fatTarget: true,
    EB_Type: true }) },
  output: { schema: ebOutputSchema },
});

const viciousPrompt = ai.definePrompt({
  name: "viciousFriendPrompt",
  model: "vertexai/gemini-2.0-flash",
  messages: makePrompt("vicious friend"),
  input: { schema: statusSchema.pick({
    waterIntake: true,
    waterNeed: true,
    caloriesIntake: true,
    caloriesNeed: true,
    calories: true,
    carbohydrate: true,
    protein: true,
    fat: true,
    carbTarget: true,
    proteinTarget: true,
    fatTarget: true,
    EB_Type: true }) },
  output: { schema: ebOutputSchema },
});

// --- Flow Definition ---
export const generateEmotionalBlackmailFlow = ai.defineFlow({
  name: "generateEmotionalBlackmailFlow",
  inputSchema: statusSchema,
  outputSchema: ebOutputSchema,
}, async (input: Status): Promise<EBOutput> => {
  const { waterIntake, waterNeed, caloriesIntake, caloriesNeed, calories, carbohydrate, protein, fat, carbTarget, proteinTarget, fatTarget, EB_Type } = input;

  if (EB_Type === "Polite") {
    const resp = await politePrompt({ waterIntake, waterNeed, caloriesIntake, caloriesNeed, calories, carbohydrate, protein, fat, carbTarget, proteinTarget, fatTarget, EB_Type });
    return resp.output!;
  }
  const resp = await viciousPrompt({ waterIntake, waterNeed, caloriesIntake, caloriesNeed, calories, carbohydrate, protein, fat, carbTarget, proteinTarget, fatTarget, EB_Type });
  return resp.output!;
});
