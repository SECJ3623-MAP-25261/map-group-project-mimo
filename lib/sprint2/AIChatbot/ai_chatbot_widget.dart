import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/home/models/item_model.dart';
import 'package:profile_managemenr/home/screens/item_detail_screen.dart';
import '../../services/item_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

class AIChatbotWidget extends StatefulWidget {
  final Function(ItemModel) onItemSelected;

  const AIChatbotWidget({super.key, required this.onItemSelected});

  @override
  State<AIChatbotWidget> createState() => _AIChatbotWidgetState();
}

class _AIChatbotWidgetState extends State<AIChatbotWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ItemService _itemService = ItemService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isProcessing = false;
  bool _speechAvailable = false;
  List<ItemModel> _allItems = [];
  String? _apiKey;
  String _debugInfo = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    debugPrint('🚀 ========== GROQ AI INITIALIZATION ==========');

    // 1. Check API Key
    _apiKey = dotenv.env['GROQ_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('❌ GROQ_API_KEY missing in .env');
      setState(() => _debugInfo = '❌ No API Key');
      _addBotMessage(
        "⚠️ Setup Required:\n\n"
        "1. Get FREE API key from: https://console.groq.com\n"
        "2. Add to .env file: GROQ_API_KEY=your_key_here\n"
        "3. Restart the app",
      );
      return;
    }

    debugPrint('✅ Groq API key found');
    setState(() => _debugInfo = '✅ Groq Connected');

    // 2. Initialize Speech
    await _initializeSpeech();

    // 3. Load items
    await _loadItems();

    // 4. Welcome message
    if (_allItems.isNotEmpty) {
      _addBotMessage(
        "Hi! I'm your Campus Closet AI assistant powered by Groq. "
        "I have ${_allItems.length} items ready. Try: 'formal outfit', 'casual wear', or 'traditional clothes'.",
      );
    } else {
      _addBotMessage("⚠️ No items in database. Please add some items first.");
    }

    debugPrint('🚀 ========== INITIALIZATION COMPLETE ==========');
  }

  Future<void> _loadItems() async {
    try {
      debugPrint('📦 Loading items...');
      _allItems = await _itemService.getItemsStream().first;
      debugPrint('✅ Loaded ${_allItems.length} items');

      if (_allItems.isNotEmpty) {
        debugPrint('📦 Sample items:');
        for (var i = 0; i < (_allItems.length > 3 ? 3 : _allItems.length); i++) {
          debugPrint('  ${i + 1}. ${_allItems[i].name} (${_allItems[i].category})');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading items: $e');
      _allItems = [];
    }
  }

  Future<void> _initializeSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        debugPrint('🎤 Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Speech error: $error');
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
    );
    debugPrint(_speechAvailable ? '✅ Speech ready' : '⚠️ Speech not available');
  }

  void _startListening() async {
    if (!_speechAvailable || _isListening) return;

    // Add haptic feedback
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 30);
      }
    } catch (e) {
      debugPrint('⚠️ Vibration not available: $e');
    }

    debugPrint('🎤 Starting to listen (press-and-hold)...');
    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        debugPrint('🎤 Recognized: ${result.recognizedWords}');
        _messageController.text = result.recognizedWords;
        if (result.finalResult) {
          _sendMessage();
          _stopListening();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() async {
    if (!_isListening) return;
    
    debugPrint('🎤 Stopping listening...');
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _addBotMessage(String text, {List<ItemModel>? suggestedItems}) {
    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: text,
            isUser: false,
            timestamp: DateTime.now(),
            suggestedItems: suggestedItems,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _addUserMessage(String text) {
    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_apiKey == null || _apiKey!.isEmpty) {
      _addBotMessage("Please add GROQ_API_KEY to your .env file first.");
      return;
    }

    if (_allItems.isEmpty) {
      _addBotMessage("No items in database.");
      return;
    }

    _addUserMessage(text);
    _messageController.clear();
    setState(() => _isProcessing = true);

    try {
      final response = await _callGroqAPI(text);
      _addBotMessage(response.message, suggestedItems: response.items);
    } catch (e) {
      debugPrint('❌ Error: $e');
      _addBotMessage("Sorry, error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<ChatbotResponse> _callGroqAPI(String userMessage) async {
    try {
      debugPrint('🤖 ========== CALLING GROQ API ==========');
      debugPrint('💬 User: "$userMessage"');

      // Prepare item catalog
      final itemSummaries = _allItems.map((item) => {
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'pricePerDay': item.pricePerDay,
        'description': item.description,
      }).toList();

      final systemPrompt = '''You are a fashion assistant for Campus Closet in Malaysia. Help users find outfits.

Available items:
${const JsonEncoder.withIndent('  ').convert(itemSummaries)}

CRITICAL: You MUST respond with ONLY valid JSON. No markdown, no code blocks, no explanations, no extra text before or after.

Required JSON format:
{
  "reply": "your friendly message here",
  "item_ids": ["id1", "id2", "id3"]
}

RULES:
1. ALWAYS respond with ONLY the JSON object, nothing else
2. Match items by category, name, or description from the available items list
3. Return 3-6 item IDs maximum (or empty array if no items match)
4. Use Malaysian English with friendly, casual tone
5. For general questions (payment, rental info, etc.), use empty item_ids: []
6. The reply should be helpful and conversational

Examples of CORRECT responses:
{"reply": "Here are some nice formal outfits for you!", "item_ids": ["abc123", "def456"]}
{"reply": "Check out these casual pieces!", "item_ids": ["ghi789"]}
{"reply": "You can pay via bank transfer or e-wallet.", "item_ids": []}

REMEMBER: Respond with ONLY the JSON object. No markdown, no code blocks, no explanations.''';

      // Make API call with timeout and retry logic
      http.Response? response;
      int retries = 0;
      const maxRetries = 2;
      
      while (retries <= maxRetries) {
        try {
          response = await http.post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': 0.7,
              'max_tokens': 500,
            }),
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout - please check your internet connection');
            },
          );
          
          break; // Success, exit retry loop
        } catch (e) {
          retries++;
          debugPrint('⚠️ Request attempt $retries failed: $e');
          
          if (retries > maxRetries) {
            if (e.toString().contains('timeout') || 
                e.toString().contains('SocketException') ||
                e.toString().contains('Failed host lookup') ||
                e.toString().contains('Network is unreachable')) {
              throw Exception('Network connection error. Please check your internet connection and try again.');
            }
            rethrow;
          }
          
          await Future.delayed(Duration(seconds: retries));
          debugPrint('🔄 Retrying... ($retries/$maxRetries)');
        }
      }

      if (response == null) {
        throw Exception('Failed to get response from API');
      }

      debugPrint('📡 Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ API Error: ${response.body}');
        
        if (response.statusCode == 401) {
          throw Exception('Invalid API key. Please check your GROQ_API_KEY in .env file.');
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please wait a moment and try again.');
        } else if (response.statusCode >= 500) {
          throw Exception('Groq API server error. Please try again in a moment.');
        } else {
          throw Exception('Groq API error: ${response.statusCode}');
        }
      }

      final data = jsonDecode(response.body);
      
      if (data['choices'] == null || 
          data['choices'].isEmpty || 
          data['choices'][0]['message'] == null ||
          data['choices'][0]['message']['content'] == null) {
        throw Exception('Invalid API response structure');
      }
      
      final aiResponse = data['choices'][0]['message']['content'] as String;
      debugPrint('📥 AI Response: $aiResponse');

      // Extract JSON
      String jsonString;
      try {
        jsonString = _extractJSON(aiResponse);
        debugPrint('🔍 Extracted JSON: $jsonString');
      } catch (extractError) {
        debugPrint('❌ JSON extraction failed: $extractError');
        if (aiResponse.trim().startsWith('{') && aiResponse.trim().endsWith('}')) {
          debugPrint('⚠️ Trying to use raw response as JSON...');
          jsonString = aiResponse.trim();
        } else {
          rethrow;
        }
      }

      // Parse JSON
      Map<String, dynamic> json;
      try {
        json = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (parseError) {
        debugPrint('❌ JSON parsing failed: $parseError');
        throw Exception('Failed to parse JSON: $parseError');
      }
      
      final reply = json['reply'] as String? ?? "I'm not sure how to help.";
      final List<dynamic> itemIds = json['item_ids'] ?? [];

      debugPrint('✅ Reply: "$reply"');
      debugPrint('✅ Item IDs: $itemIds');

      // Match items
      final suggestedItems = <ItemModel>[];
      for (var id in itemIds) {
        final item = _allItems.firstWhereOrNull((i) => i.id == id.toString());
        if (item != null) {
          suggestedItems.add(item);
          debugPrint('   ✓ Found: ${item.name}');
        }
      }

      debugPrint('🤖 ========== GROQ API COMPLETE ==========');

      return ChatbotResponse(
        message: reply,
        items: suggestedItems.take(6).toList(),
      );
    } catch (e, stack) {
      debugPrint('🔥 ========== ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      
      String errorMessage;
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('network') || 
          errorStr.contains('connection') || 
          errorStr.contains('timeout') ||
          errorStr.contains('socket') ||
          errorStr.contains('internet')) {
        errorMessage = "🌐 Connection Issue\n\n"
            "I couldn't connect to the AI service. Please:\n"
            "• Check your internet connection\n"
            "• Make sure you're connected to WiFi or mobile data\n"
            "• Try again in a moment";
      } else if (errorStr.contains('api key') || errorStr.contains('401')) {
        errorMessage = "🔑 API Key Issue\n\n"
            "The API key is missing or invalid. Please:\n"
            "• Check your .env file has GROQ_API_KEY\n"
            "• Get a free key from: https://console.groq.com\n"
            "• Restart the app after adding the key";
      } else if (errorStr.contains('rate limit') || errorStr.contains('429')) {
        errorMessage = "⏱️ Rate Limit\n\n"
            "Too many requests. Please wait a moment and try again.";
      } else if (errorStr.contains('json')) {
        errorMessage = "Sorry, I'm having trouble understanding that. "
            "Please try rephrasing your question.\n\n"
            "Try asking:\n"
            "• 'Show me formal outfits'\n"
            "• 'I need casual wear'\n"
            "• 'Traditional clothes'";
      } else {
        errorMessage = "Sorry, something went wrong. Please try again.\n\n"
            "If the problem persists, check:\n"
            "• Your internet connection\n"
            "• The API key in .env file\n"
            "• Try asking a different question";
      }
      
      return ChatbotResponse(
        message: errorMessage,
        items: [],
      );
    }
  }

  String _extractJSON(String text) {
    String cleaned = text.trim();
    
    // Remove markdown code blocks
    final markdownPatterns = [
      RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false),
      RegExp(r'```\s*([\s\S]*?)\s*```', caseSensitive: false),
    ];
    
    for (var pattern in markdownPatterns) {
      final match = pattern.firstMatch(cleaned);
      if (match != null && match.groupCount > 0) {
        cleaned = match.group(1)!.trim();
        break;
      }
    }
    
    // Find the first { and last }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    
    if (start == -1 || end == -1 || start >= end) {
      throw Exception('No valid JSON found in response');
    }
    
    cleaned = cleaned.substring(start, end + 1);
    
    // Validate JSON
    try {
      jsonDecode(cleaned);
      return cleaned;
    } catch (e) {
      throw Exception('Invalid JSON: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          if (_isProcessing) _buildProcessingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isReady = _apiKey != null && _allItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Groq AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isReady
                      ? 'Online • ${_allItems.length} items • $_debugInfo'
                      : _debugInfo,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: message.isUser ? AppColors.accentColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          if (message.suggestedItems != null &&
              message.suggestedItems!.isNotEmpty)
            _buildSuggestedItems(message.suggestedItems!),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSuggestedItems(List<ItemModel> items) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              debugPrint('🔗 Item tapped: ${item.name}');

              try {
                // Close the chatbot widget first
                if (!mounted) return;
                Navigator.pop(context);

                // Then navigate to item detail
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(item: item.toDetailMap()),
                  ),
                );
              } catch (e, stackTrace) {
                debugPrint('❌ Navigation error: $e');
                debugPrint('Stack: $stackTrace');
                widget.onItemSelected(item);
              }
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentColor.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: item.images.isNotEmpty
                        ? Image.network(
                            item.images[0].toString(),
                            height: 120,
                            width: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          )
                        : Container(
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'RM ${item.pricePerDay.toStringAsFixed(2)}/day',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: AppColors.accentColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentColor),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Thinking...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isReady = _apiKey != null && _allItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  enabled: isReady,
                  decoration: InputDecoration(
                    hintText: isReady
                        ? 'Try: formal outfit...'
                        : 'Setup required...',
                    border: InputBorder.none,
                    hintStyle: const TextStyle(fontSize: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTapDown: isReady && !_isListening ? (_) => _startListening() : null,
              onTapUp: isReady && _isListening ? (_) => _stopListening() : null,
              onTapCancel: isReady && _isListening ? () => _stopListening() : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: !isReady
                      ? Colors.grey
                      : _isListening
                      ? Colors.red
                      : AppColors.accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: (_isProcessing || !isReady) ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isProcessing || !isReady)
                      ? Colors.grey
                      : AppColors.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ItemModel>? suggestedItems;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedItems,
  });
}

class ChatbotResponse {
  final String message;
  final List<ItemModel> items;

  ChatbotResponse({required this.message, required this.items});
}