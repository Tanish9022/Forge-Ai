import os
import json
import re
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("GOOGLE_API_KEY")
if API_KEY:
    genai.configure(api_key=API_KEY)
else:
    print("Warning: GOOGLE_API_KEY not found in environment variables.")

def simple_fallback_analysis(text):
    """
    A heuristic-based fallback when the AI API fails.
    """
    text_lower = text.lower()
    
    # Keyword analysis for threat score
    high_threat_keywords = ['attack', 'infiltration', 'buildup', 'suspicious', 'weapon', 'crossing', 'ied', 'ambush']
    medium_threat_keywords = ['movement', 'drone', 'unidentified', 'patrol', 'sighting']
    
    score = 0.1
    confidence = 0.5
    
    if any(k in text_lower for k in high_threat_keywords):
        score = 0.85
        confidence = 0.7
    elif any(k in text_lower for k in medium_threat_keywords):
        score = 0.5
        confidence = 0.6
        
    # Simple Entity Extraction (Mock)
    entities = []
    
    # Common J&K locations
    locations = {
        "ladakh": {"lat": 34.1526, "lng": 77.5770},
        "poonch": {"lat": 33.7731, "lng": 74.0965},
        "uri": {"lat": 34.0822, "lng": 74.0343},
        "galwan": {"lat": 34.7578, "lng": 78.2897},
        "kargil": {"lat": 34.5539, "lng": 76.1349},
        "srinagar": {"lat": 34.0837, "lng": 74.7973},
        "kupwara": {"lat": 34.5322, "lng": 74.2566}
    }
    
    found_loc = False
    for loc, coords in locations.items():
        if loc in text_lower:
            entities.append({
                "type": "LOC",
                "value": loc.capitalize(),
                "lat": coords["lat"],
                "lng": coords["lng"]
            })
            found_loc = True
            
    if not found_loc:
         entities.append({"type": "LOC", "value": "Unknown Sector", "lat": 28.6139, "lng": 77.2090}) # Default Delhi

    # Extract number as UNIT if present
    # Regex to find things like "3 soldiers", "5 insurgents"
    unit_match = re.search(r'(\d+)\s+([a-z]+)', text_lower)
    if unit_match:
         entities.append({"type": "UNIT", "value": f"{unit_match.group(1)} {unit_match.group(2)}"})
    else:
         entities.append({"type": "UNIT", "value": "Unknown Unit"})
         
    entities.append({"type": "STATUS", "value": "Analyzed (Fallback Mode)"})

    return {
        "threat_score": score,
        "confidence_score": confidence,
        "entities": entities,
        "note": "AI Quota Exceeded - Using Fallback Logic"
    }

def assess_threat(text):
    """
    Analyzes the text using Gemini API to extract threat score and entities.
    Returns a dictionary with structured data.
    """
    if not API_KEY:
        return simple_fallback_analysis(text)

    # Use a model confirmed to be available for this API key
    model = genai.GenerativeModel('gemini-2.0-flash')

    prompt = f"""
    You are a highly advanced Military Intelligence Analyst AI specializing in the Indian Army operational context.
    Analyze the following intelligence report text.
    
    Your task is to:
    1. Determine a 'threat_score' from 0.0 (Safe) to 1.0 (Critical Threat).
    2. Provide a 'confidence_score' in your assessment (0.0 to 1.0).
    3. Extract key entities:
       - LOC: Specific locations, sector names, or coordinates. **Crucial:** Try to provide estimated Latitude and Longitude for the location if it is a known place (e.g., "Poonch", "Ladakh", "Galwan").
       - UNIT: Military units or groups identified.
       - STATUS: Activity or status.

    Report Text: "{text}"

    Return the result strictly as a JSON object with the following keys:
    "threat_score": float,
    "confidence_score": float,
    "entities": [
        {{"type": "LOC", "value": "Name of Location", "lat": 34.0, "lng": 77.0}},
        {{"type": "UNIT", "value": "..."}},
        {{"type": "STATUS", "value": "..."}}
    ]
    
    If you cannot estimate coordinates for a LOC, omit the lat/lng keys for that entity.
    Do not include markdown formatting. Just the raw JSON string.
    """

    try:
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # Clean up any potential markdown formatting
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
            
        data = json.loads(response_text)
        return data
    except Exception as e:
        print(f"Error in AI assessment: {e}")
        return simple_fallback_analysis(text)
