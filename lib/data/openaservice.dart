import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/app_constrants.dart';
import '../../core/app_logger.dart';
import '../../core/services/remote_confiq_services.dart';
import 'models/pest_results.dart';

class OpenAIService {
  static const int _maxRetries = 3;

  Future<PestResult> analyzeImage(
      String base64Image,
      String languageName, {
        String analysisType = 'pest',
      }) async {
    return _analyzeWithRetry(base64Image, languageName, analysisType, attempt: 1);
  }

  Future<PestResult> _analyzeWithRetry(
      String base64Image,
      String languageName,
      String analysisType, {
        required int attempt,
      }) async {
    try {
      AppLogger.info(
        "Sending request to AI Analysis Service (attempt $attempt, type: $analysisType)...",
        "AIAnalysisService",
      );

      final prompt = _getSystemPrompt(languageName, analysisType);

      final response = await http.post(
        Uri.parse(AppConstants.openAIBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${RemoteConfigService().getOpenAIApiKey()}',
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content": prompt,
            },
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": "Analyze this plant image and provide results in $languageName.",
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image",
                  },
                },
              ],
            },
          ],
          "response_format": {"type": "json_object"},
          "temperature": 0.1,
          "max_tokens": 2500,
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 429) {
        if (attempt >= _maxRetries) throw Exception('Rate limit reached.');
        final waitSeconds = _backoffSeconds(attempt);
        await Future.delayed(Duration(seconds: waitSeconds));
        return _analyzeWithRetry(base64Image, languageName, analysisType, attempt: attempt + 1);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final jsonResponse = jsonDecode(content);

        // Inject scanType into JSON so model can pick it up
        jsonResponse['scanType'] = analysisType;

        return PestResult.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      AppLogger.error("AI Analysis error", e, stack, "AIAnalysisService");
      rethrow;
    }
  }

  String _getSystemPrompt(String languageName, String analysisType) {
    String focus = "";
    String jsonFormat = "";

    if (analysisType == 'identify') {
      focus = "FOCUS: Ultra-rich plant identification. CRITICAL MANDATE: ALL descriptions, names, texts, and values MUST be fully written in $languageName. Do not return any English words or titles.";
      jsonFormat = """
{
  "plant_name": "($languageName)",
  "scientific_name": "String",
  "confidence_score": 0.0,
  "basic_info": {
    "family": "($languageName)",
    "genus": "($languageName)",
    "species": "($languageName)",
    "common_names": ["Array of names ($languageName)"]
  },
  "history": {
    "origin_history": "($languageName)",
    "historical_uses": "($languageName)",
    "discovery_info": "($languageName)",
    "cultural_significance": "($languageName)"
  },
  "growth": {
    "growth_stages": ["Array ($languageName)"],
    "growth_duration_days": 0,
    "max_height": "($languageName)",
    "spread_width": "($languageName)",
    "seasonal_behavior": "($languageName)",
    "harvest_time": "($languageName)"
  },
  "care": {
    "water_requirement": "($languageName)",
    "sunlight": "($languageName)",
    "soil_type": "($languageName)",
    "growth_rate": "($languageName)",
    "fertilizers": ["Array ($languageName)"]
  },
  "safety": {
    "is_edible": false,
    "is_toxic": false,
    "warnings": "($languageName)"
  },
  "usage": {
    "usage_types": ["Array ($languageName)"],
    "parts_used": ["Array ($languageName)"],
    "how_to_use": "($languageName)"
  },
  "benefits": {
    "health_benefits": ["Array ($languageName)"],
    "environmental_benefits": "($languageName)",
    "economic_value": "($languageName)",
    "air_purification_score": 0
  },
  "cost": {
    "average_price": 0,
    "price_range_min": 0,
    "price_range_max": 0,
    "currency": "($languageName)",
    "market_availability": "($languageName)",
    "nursery_availability": true
  },
  "inspiration": {
    "gardening_difficulty_level": "($languageName)",
    "success_rate": 0,
    "time_to_reward": 0,
    "expected_yield": "($languageName)",
    "why_grow_this_plant": "($languageName)",
    "success_stories": ["Array ($languageName)"],
    "daily_tips": ["Array ($languageName)"]
  },
  "gardening": {
    "step_by_step_growing": ["Array ($languageName)"],
    "tools_required": ["Array ($languageName)"],
    "common_mistakes": ["Array ($languageName)"]
  },
  "harvesting": {
    "harvest_method": "($languageName)",
    "harvest_time": "($languageName)",
    "harvest_frequency": "($languageName)",
    "storage_methods": "($languageName)",
    "post_harvest_processing": "($languageName)"
  },
  "business": {
    "market_demand": "($languageName)",
    "selling_price_range": "($languageName)",
    "profit_margin_estimate": "($languageName)",
    "target_customers": ["Array ($languageName)"],
    "business_models": ["Array ($languageName)"],
    "roi_estimation": "($languageName)",
    "scaling_potential": "($languageName)"
  },
  "finance": {
    "cost_per_plant": "(\$ with value)",
    "total_investment": "(\$ with value)",
    "expected_revenue": "(\$ with value)",
    "net_profit": "(\$ with value)",
    "break_even_time": "($languageName)"
  },
  "location": {
    "latitude": 0.0,
    "longitude": 0.0,
    "climate_type": "($languageName)"
  },
  "ai_features": {
    "ai_description": "($languageName)",
    "disease_detection": "($languageName)",
    "health_status": "($languageName)",
    "treatment_suggestions": ["Array ($languageName)"],
    "ai_gardening_advice": "($languageName)",
    "ai_business_advice": "($languageName)"
  }
}""";
    } else if (analysisType == 'diagnose') {
      focus = "FOCUS: Ultra-rich plant health diagnostics. Provide detailed disease analysis, treatment options (organic/chemical), and management strategies. CRITICAL MANDATE: ALL descriptions, names, texts, paragraphs, and values MUST be fully written in $languageName. Do not return any English words or titles unless scientific names.";
      jsonFormat = """
{
  "plant_name": "($languageName)",
  "scientific_name": "String",
  "confidence_score": 0.0,
  "health_status": "($languageName)",
  "health_confidence": 0.0,
  "disease": {
    "name": "($languageName)",
    "scientific_name": "String",
    "type": "($languageName)",
    "category": "($languageName)",
    "severity": "Low/Medium/High",
    "stage": "($languageName)",
    "affected_area_percentage": 0,
    "spread_risk": "($languageName)",
    "disease_details": {
      "description": "($languageName)",
      "lifecycle": "($languageName)",
      "favorable_conditions": ["Array ($languageName)"],
      "transmission": ["Array ($languageName)"]
    }
  },
  "symptoms": ["Array ($languageName)"],
  "causes": ["Array ($languageName)"],
  "treatment": {
    "immediate": ["Array ($languageName)"],
    "organic": ["Array ($languageName)"],
    "chemical": ["Array ($languageName)"],
    "advanced_methods": ["Array ($languageName)"],
    "duration_days": 0,
    "recovery_chance": "($languageName)"
  },
  "prevention": {
    "daily_care": ["Array ($languageName)"],
    "seasonal_prevention": ["Array ($languageName)"],
    "monitoring": ["Array ($languageName)"]
  },
  "protection": {
    "how_to_protect": ["Array ($languageName)"],
    "tools": ["Array ($languageName)"]
  },
  "safety": {
    "for_humans": ["Array ($languageName)"],
    "for_plants": ["Array ($languageName)"],
    "environmental_safety": ["Array ($languageName)"]
  },
  "impact": {
    "yield_loss": "($languageName)",
    "growth_effect": "($languageName)",
    "spread_to_other_plants": true
  },
  "harvest": {
    "safe_to_harvest": false,
    "waiting_days": 0,
    "quality": "($languageName)"
  },
  "management": {
    "small_scale": {
      "strategy": ["Array ($languageName)"],
      "cost_estimate": "($languageName)",
      "difficulty": "($languageName)"
    },
    "large_scale": {
      "strategy": ["Array ($languageName)"],
      "cost_estimate": "($languageName)",
      "risk_control": "($languageName)"
    }
  },
  "ai_advice": {
    "summary": "($languageName)",
    "urgency": "($languageName)",
    "next_step": "($languageName)",
    "business_tip": "($languageName)"
  }
}""";
    } else {
      focus = "FOCUS: Complete agricultural report. Detect pests, diseases, and provide detailed treatment/prevention strategies. CRITICAL MANDATE: ALL descriptions, names, texts, paragraphs, and values MUST be fully written in $languageName. Do not return any English words or titles unless scientific names.";
      jsonFormat = """
{
  "is_pest_detected": "yes/no/not_sure",
  "plant_name": "($languageName)",
  "pest_name": "($languageName) or 'N/A'",
  "scientific_name": "String",
  "confidence": 0.0,
  "severity_level": "Low/Medium/High/N/A",
  "affected_area_estimate": "($languageName)",
  "symptoms_detected": "($languageName)",
  "description": "($languageName)",
  "treatment": {
    "organic": ["Array ($languageName)"],
    "chemical": ["Array ($languageName)"]
  },
  "prevention_tips": ["Array ($languageName)"]
}""";
    }

    return """
You are an expert botanist and plant pathologist. 
$focus

LANGUAGE INSTRUCTION: Provide ALL values in $languageName. Keys must be in English.
CURRENCY INSTRUCTION: All financial estimations, costs, prices, ROI, and market values MUST be provided in US Dollars (\$). Ensure that every such value in the JSON includes the '\$' symbol (e.g., "\$100", "\$500 - \$800").

Return ONLY valid JSON in this format (Skip any section entirely if no information is available by using 'N/A' for values):
$jsonFormat
""";
  }

  int _backoffSeconds(int attempt) => (5 * pow(3, attempt - 1)).toInt();
}
