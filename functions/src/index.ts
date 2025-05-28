import {onCallGenkit} from "firebase-functions/https";

import {foodPhotoNutritionFlow} from "./flow/foodPhotoToNutritionFlow";

// 導出食譜檢索功能
export const foodPhotoNutrition = onCallGenkit(foodPhotoNutritionFlow);
