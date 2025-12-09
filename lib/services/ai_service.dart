import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  static const String _model = 'gemini-1.5-flash'; // or 'gemini-1.5-pro'

  static Future<String> generateContent(
    String userMessage,
    List<Map<String, dynamic>> chatHistory,
  ) async {
    // Build conversation history for Gemini
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [{'text': _systemPrompt}]
      },
      {
        'role': 'model',
        'parts': [{'text': 'Understood. I\'m ready to help!'}]
      },
      ...chatHistory.expand((msg) => [
            {
              'role': msg['isUser'] ? 'user' : 'model',
              'parts': [{'text': msg['text']}]
            }
          ]),
      {
        'role': 'user',
        'parts': [{'text': userMessage}]
      }
    ];

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'maxOutputTokens': 500,
          'temperature': 0.7,
          'topP': 0.9,
        },
        'safetySettings': [
          {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_ONLY_HIGH'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_ONLY_HIGH'},
          {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_ONLY_HIGH'},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }

    final parts = candidates[0]['content']['parts'] as List?;
    final text = parts?.first['text'] as String?;
    return text?.trim() ?? "Sorry, I couldn't generate a response.";
  }

  static const String _systemPrompt = '''
You are "Campus Closet Assistant", a helpful AI for a university clothing rental service.
Your job:
- Recommend outfits by occasion: formal, casual, sports, business, traditional.
- Explain rental process, pricing, returns.
- If the user asks to see items (e.g., "show me formal dresses"), respond with EXACTLY:
  ITEMS(category: <category_name>)
  Example: "ITEMS(category: formal)"
- NEVER mention you're an AI or Google.
- Keep replies friendly, concise, and student-focused.
- Only suggest categories: formal, casual, sports, business, traditional.
''';
}