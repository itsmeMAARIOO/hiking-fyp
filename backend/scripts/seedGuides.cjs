// to use scripts to seed the database with the guides

require("dotenv").config();
const { MongoClient } = require("mongodb");

const guides = [
  {
    title: "CPR (Adults)",
    content: [
      "Check for responsiveness and normal breathing.",
      "Call emergency services immediately (or send someone).",
      "Place hands in center of chest. Push HARD and FAST (100-120 bpm).",
      "Allow chest to recoil completely between compressions.",
      "Perform 30 compressions followed by 2 rescue breaths.",
      "Continue until help arrives or victim wakes up.",
    ],
  },
  {
    title: "Choking (Adults)",
    content: [
      'Ask "Are you choking?" If they cannot speak, act immediately.',
      "Stand behind victim, wrap arms around waist.",
      "Make a fist above the navel, grab it with other hand.",
      "Perform quick, upward abdominal thrusts (Heimlich).",
      "Repeat until object is cleared or victim becomes unconscious.",
      "If unconscious, lower to ground and begin CPR.",
    ],
  },
  {
    title: "Severe Bleeding",
    content: [
      "Protect yourself: Wear gloves if available.",
      "Apply direct, firm pressure with a clean cloth/gauze.",
      "If blood soaks through, add more layers (do not remove original).",
      "Use a tourniquet 2-3 inches above wound for life-threatening limb bleeding.",
      "Tighten tourniquet until bleeding stops completely.",
      "Note the time tourniquet was applied. Do NOT remove it.",
    ],
  },
  {
    title: "Anaphylaxis (Allergic Reaction)",
    content: [
      "Identify symptoms: Swollen lips/tongue, difficulty breathing, hives.",
      "Ask if they carry an Epinephrine Auto-Injector (EpiPen).",
      "Assist them: Inject into outer thigh (through clothes if needed).",
      "Hold in place for 10 seconds (or as directed on device).",
      "Massage injection site for 10 seconds.",
      "Evacuate immediately. Symptoms can return after 15-20 mins.",
    ],
  },
  {
    title: "Heat Stroke",
    content: [
      "Signs: Hot dry skin (no sweating), confusion, rapid pulse.",
      "Move victim to shade immediately.",
      "Cool rapidly: Pour water over them, fan them, apply wet cloths.",
      "Place cold packs on neck, armpits, and groin.",
      "Do NOT force fluids if they are confused or vomiting.",
      "This is a life-threatening emergency. Evacuate.",
    ],
  },
  {
    title: "Hypothermia",
    content: [
      "Signs: Shivering, clumsiness, confusion, slurred speech.",
      "Move to shelter/tent; block wind and rain.",
      "Remove wet clothing immediately and replace with dry layers.",
      "Wrap in blankets/sleeping bag (skin-to-skin contact helps).",
      "Give warm, sweet drinks if conscious (NO alcohol/caffeine).",
      "Handle gently; rough movement can trigger heart issues.",
    ],
  },
  {
    title: "Snake Bite",
    content: [
      "Keep victim calm and still to slow venom spread.",
      "Remove tight clothing/jewelry near bite before swelling starts.",
      "Keep the bite site below heart level.",
      "Clean gently, but do NOT flush with water (if snake ID needed).",
      "Do NOT cut, suck, apply ice, or use a tourniquet.",
      "Mark the edge of swelling with a pen and note the time.",
    ],
  },
  {
    title: "Fractures & Sprains",
    content: [
      "Check Circulation/Sensation: Can they feel/move toes/fingers?",
      "Immobilize the injury in the position found using a splint.",
      "Pad the splint for comfort; secure above and below the injury.",
      "Apply cold pack (20 min on, 20 min off) to reduce swelling.",
      "Elevate the limb if possible.",
      "Do not move the person if a neck/spine injury is suspected.",
    ],
  },
  {
    title: "Head Injury (Concussion)",
    content: [
      "Check for consciousness and memory loss.",
      "Look for unequal pupils, vomiting, or fluid from ears/nose.",
      "Keep victim still and head slightly elevated (if no neck injury).",
      "Monitor breathing and alertness constantly.",
      "Do not give medication that thins blood (e.g., Aspirin/Ibuprofen).",
      "Evacuate if they lose consciousness, vomit, or become confused.",
    ],
  },
  {
    title: "Burns",
    content: [
      "Cool the burn under cool (not cold) running water for 10-20 mins.",
      "Remove jewelry/clothing near burn before swelling occurs.",
      "Do NOT break blisters or apply butter/ice/creams.",
      "Cover loosely with a sterile, non-stick dressing or cling film.",
      "Keep the patient warm to prevent shock.",
    ],
  },
  {
    title: "Blisters",
    content: [
      "Hot spot (red area): Apply tape or moleskin immediately.",
      "Intact blister: Protect with a doughnut-shaped pad/moleskin.",
      "Do not pop a blister unless it is painful and likely to burst.",
      "If popping: Sterilize a needle, drain at edge, keep skin flap on.",
      "Apply antibiotic ointment and cover with a clean bandage.",
    ],
  },
  {
    title: "Tick Bite",
    content: [
      "Use fine-tipped tweezers to grasp tick as close to skin as possible.",
      "Pull upward with steady, even pressure. Do not twist.",
      "Ensure the head/mouthparts are removed.",
      "Clean the bite area and your hands with alcohol or soap.",
      "Save the tick in a bag/photo for ID if symptoms develop.",
    ],
  },
  {
    title: "Nosebleed",
    content: [
      "Sit upright and lean forward slightly (do NOT tilt head back).",
      "Pinch the soft part of the nose (just below the bridge).",
      "Hold pressure continuously for 10-15 minutes.",
      "Breathe through the mouth.",
      "Apply a cold pack to the bridge of the nose.",
    ],
  },
];

async function seed() {
  const client = new MongoClient(process.env.MONGO_URI);

  try {
    await client.connect();
    const db = client.db("hikingapp");
    const collection = db.collection("guides");

    await collection.deleteMany({});

    await collection.insertMany(guides);

  } catch (err) {
    console.error("Error seeding:", err);
  } finally {
    client.close();
  }
}

seed();
