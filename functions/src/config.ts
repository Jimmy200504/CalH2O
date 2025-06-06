import {genkit} from "genkit";
import {vertexAI} from "@genkit-ai/vertexai";


const firebaseConfig = {
    apiKey: "AIzaSyD1ATIXersARB_ltS_BarWC6QU_3MltFIU",
    authDomain: "calh2o.firebaseapp.com",
    projectId: "calh2o",
    storageBucket: "calh2o.firebasestorage.app",
    messagingSenderId: "94238638413",
    appId: "1:94238638413:web:d6de4f178e63f9a44b3704"
  };

export const getProjectId = () => firebaseConfig.projectId;

export const ai = genkit({
  plugins: [
    vertexAI({
      projectId: getProjectId(),
      location: "us-central1",
    }),
  ],
});


