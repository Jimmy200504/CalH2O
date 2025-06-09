import { z } from "genkit";
import { ai } from "../config";

// --- Input Schema ---
export const statusSchema = z.object({
  waterIntake: z.number().describe("Today's total water consumed in ml"),
  waterNeed: z.number().describe("Daily water requirement in ml"),
  caloriesIntake: z.number().describe("Today's total calories consumed in kcal"),
  caloriesNeed: z.number().describe("Daily calorie requirement in kcal"),
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
  return `You are a creative and engaging ${role}. Based on the user’s daily status, generate exactly 9 stylized emotional blackmail messages.
- 6 short messages should be last than 9 words.
- Water: consumed {{waterIntake}} ml / goal {{waterNeed}} ml
- Calories: consumed {{caloriesIntake}} kcal / goal {{caloriesNeed}} kcal

Return only a JSON array of strings, e.g.: ["msg1","msg2",...]; no extra text.`;
}

// --- Prompts ---
const politePrompt = ai.definePrompt({
  name: "politeFriendPrompt",
  model: "vertexai/gemini-2.0-flash",
  messages: makePrompt("polite friend"),
  input: { schema: statusSchema.pick({ waterIntake: true, waterNeed: true, caloriesIntake: true, caloriesNeed: true }) },
  output: { schema: ebOutputSchema },
});

const viciousPrompt = ai.definePrompt({
  name: "viciousFriendPrompt",
  model: "vertexai/gemini-2.0-flash",
  messages: makePrompt("vicious friend"),
  input: { schema: statusSchema.pick({ waterIntake: true, waterNeed: true, caloriesIntake: true, caloriesNeed: true }) },
  output: { schema: ebOutputSchema },
});

// const momPrompt = ai.definePrompt({
//   name: "momPrompt",
//   model: "vertexai/gemini-2.0-flash",
//   messages: makePrompt("mom"),
//   input: { schema: statusSchema.pick({ waterIntake: true, waterNeed: true, caloriesIntake: true, caloriesNeed: true }) },
//   output: { schema: ebOutputSchema },
// });

// --- Flow Definition ---
export const generateEmotionalBlackmailFlow = ai.defineFlow({
  name: "generateEmotionalBlackmailFlow",
  inputSchema: statusSchema,
  outputSchema: ebOutputSchema,
}, async (input: Status): Promise<EBOutput> => {
  const { waterIntake, waterNeed, caloriesIntake, caloriesNeed, EB_Type } = input;

  if (EB_Type === "Polite") {
    const resp = await politePrompt({ waterIntake, waterNeed, caloriesIntake, caloriesNeed });
    return resp.output!;
  }
  const resp = await viciousPrompt({ waterIntake, waterNeed, caloriesIntake, caloriesNeed });
  return resp.output!;
});
