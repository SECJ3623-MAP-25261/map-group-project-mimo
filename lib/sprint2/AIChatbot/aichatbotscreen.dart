import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/home/models/item_model.dart';
import 'package:profile_managemenr/home/screens/item_detail_screen.dart';
import '../../services/item_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
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
  String _userName = 'there';

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    debugPrint('🚀 ========== GROQ AI INITIALIZATION ==========');
    
    // 1. GET USER NAME FIRST
    await _loadUserName();
    
    // 2. Check API Key
    _apiKey = dotenv.env['GROQ_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('❌ GROQ_API_KEY missing in .env');
      if (mounted) {
        setState(() => _debugInfo = '❌ No API Key');
      }
      _addBotMessage(
        "⚠️ Setup Required:\n\n"
        "1. Get FREE API key from: https://console.groq.com\n"
        "2. Sign up (no credit card needed)\n"
        "3. Copy your API key\n"
        "4. Add to .env file:\n   GROQ_API_KEY=your_key_here\n"
        "5. Restart the app"
      );
      return;
    }
    
    debugPrint('✅ Groq API key found');
    if (mounted) {
      setState(() => _debugInfo = '✅ Groq Connected');
    }
    
    // 3. Initialize Speech
    await _initializeSpeech();
    
    // 4. Load items from database
    await _loadItems();
    
    // 5. Show welcome message
    _showWelcomeMessage();
    
    debugPrint('🚀 ========== INITIALIZATION COMPLETE ==========');
  }

  Future<void> _loadUserName() async {
    try {
      if (!mounted) return;
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId != null) {
        final userData = await authService.getUserData(userId);
        if (userData != null && mounted) {
          setState(() {
            _userName = userData['fullName'] ?? 'there';
          });
          debugPrint('✅ User name loaded: $_userName');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not load user name: $e');
      // Keep default 'there'
    }
  }

  Future<void> _loadItems() async {
    try {
      debugPrint('📦 Loading items from database...');
      _allItems = await _itemService.getItemsStream().first;
      debugPrint('✅ Loaded ${_allItems.length} items');
      
      if (_allItems.isNotEmpty) {
        debugPrint('📦 ========== ITEM CATALOG ==========');
        for (var i = 0; i < (_allItems.length > 5 ? 5 : _allItems.length); i++) {
          debugPrint('  ${i + 1}. ${_allItems[i].name} (${_allItems[i].category})');
        }
        debugPrint('📦 ====================================');
      }
    } catch (e) {
      debugPrint('❌ Error loading items: $e');
      _allItems = [];
    }
  }

  void _showWelcomeMessage() {
    if (_apiKey != null && _allItems.isNotEmpty) {
      _addBotMessage(
        "Hi $_userName! 👋 I'm your Campus Closet AI assistant powered by Groq ⚡\n\n"
        "I have ${_allItems.length} items ready for you. Try asking:\n"
        "• 'Show me formal outfits'\n"
        "• 'I need casual wear'\n"
        "• 'Traditional clothes'"
      );
    } else if (_allItems.isEmpty) {
      _addBotMessage("⚠️ No items found in database. Please add some items first.");
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
        _addBotMessage("Voice recognition error.");
      },
    );
    debugPrint(_speechAvailable ? '✅ Speech ready' : '⚠️ Speech not available');
    if (mounted) {
      setState(() {});
    }
  }

  void _startListening() async {
    if (!_speechAvailable || _isListening) return;
    
    // Add haptic feedback with error handling
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 30);
      }
    } catch (e) {
      debugPrint('⚠️ Vibration not available: $e');
    }

    debugPrint('🎤 Starting to listen (press-and-hold)...');
    if (mounted) {
      setState(() => _isListening = true);
    }

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
      pauseFor: const Duration(seconds: 2),
    );
  }

  void _stopListening() async {
    if (!_isListening) return;
    
    debugPrint('🎤 Stopping listening (release or timeout)...');
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _addBotMessage(String text, {List<ItemModel>? suggestedItems}) {
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          suggestedItems: suggestedItems,
        ));
      });
      _scrollToBottom();
    }
  }

  void _addUserMessage(String text) {
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ));
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

    debugPrint('💬 User message: "$text"');

    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('❌ Cannot send: No API key');
      _addBotMessage("Please add GROQ_API_KEY to your .env file first.");
      return;
    }

    if (_allItems.isEmpty) {
      debugPrint('❌ Cannot send: No items');
      _addBotMessage("No items in database. Please add items first.");
      return;
    }

    _addUserMessage(text);
    _messageController.clear();
    if (mounted) {
      setState(() => _isProcessing = true);
    }

    try {
      final response = await _callGroqAPI(text);
      debugPrint('✅ Got response: "${response.message}" with ${response.items.length} items');
      _addBotMessage(response.message, suggestedItems: response.items);
    } catch (e, stackTrace) {
      debugPrint('❌ Error: $e');
      debugPrint('Stack: $stackTrace');
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
      debugPrint('💬 User query: "$userMessage"');

      // Prepare item catalog
      final itemSummaries = _allItems.map((item) => {
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'pricePerDay': item.pricePerDay,
        'description': item.description ?? '',
      }).toList();

      debugPrint('🤖 Prepared ${itemSummaries.length} items for AI');

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

      debugPrint('📤 Sending to Groq API...');

      // Make API call to Groq with timeout and retry logic
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
          
          // If we got a response, break out of retry loop
          break;
        } catch (e) {
          retries++;
          debugPrint('⚠️ Request attempt $retries failed: $e');
          
          if (retries > maxRetries) {
            // Check if it's a network error
            if (e.toString().contains('timeout') || 
                e.toString().contains('SocketException') ||
                e.toString().contains('Failed host lookup') ||
                e.toString().contains('Network is unreachable')) {
              throw Exception('Network connection error. Please check your internet connection and try again.');
            }
            rethrow;
          }
          
          // Wait before retrying
          await Future.delayed(Duration(seconds: retries));
          debugPrint('🔄 Retrying... ($retries/$maxRetries)');
        }
      }

      if (response == null) {
        throw Exception('Failed to get response from API');
      }

      debugPrint('📡 API Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ API Error Response: ${response.body}');
        
        // Handle specific error codes
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
      
      // Check if response has expected structure
      if (data['choices'] == null || 
          data['choices'].isEmpty || 
          data['choices'][0]['message'] == null ||
          data['choices'][0]['message']['content'] == null) {
        throw Exception('Invalid API response structure');
      }
      
      final aiResponse = data['choices'][0]['message']['content'] as String;
      
      debugPrint('📥 ========== GROQ RAW RESPONSE ==========');
      debugPrint(aiResponse);
      debugPrint('📥 =========================================');

      // Extract JSON - with better error handling
      String jsonString;
      try {
        jsonString = _extractJSON(aiResponse);
        
        debugPrint('🔍 ========== EXTRACTED JSON ==========');
        debugPrint(jsonString);
        debugPrint('🔍 ======================================');
      } catch (extractError) {
        debugPrint('❌ JSON extraction failed: $extractError');
        debugPrint('❌ Raw response was: $aiResponse');
        // Try to use the raw response as a fallback if it looks like it might be JSON
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
        debugPrint('❌ JSON string was: $jsonString');
        throw Exception('Failed to parse JSON: $parseError');
      }
      
      final reply = (json['reply'] as String?)?.trim() ?? "I'm not sure how to help with that.";
      final List<dynamic> itemIds = json['item_ids'] ?? [];

      debugPrint('✅ Parsed successfully:');
      debugPrint('   Reply: "$reply"');
      debugPrint('   Item IDs: $itemIds');

      // Match items from database
      final suggestedItems = <ItemModel>[];
      debugPrint('🔎 Matching items from database...');
      for (var id in itemIds) {
        final item = _allItems.firstWhereOrNull((i) => i.id == id.toString());
        if (item != null) {
          suggestedItems.add(item);
          debugPrint('   ✓ Found: ${item.name} (${item.id})');
        } else {
          debugPrint('   ✗ Not found: $id');
        }
      }

      debugPrint('🤖 ========== GROQ API COMPLETE ==========');

      return ChatbotResponse(
        message: reply,
        items: suggestedItems.take(6).toList(),
      );

    } catch (e, stackTrace) {
      debugPrint('🔥 ========== ERROR ==========');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
      debugPrint('🔥 ============================');
      
      // More helpful error message based on error type
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
    
    debugPrint('🔧 Extracting JSON from response...');
    debugPrint('🔧 Original text length: ${text.length}');
    
    // Remove markdown code blocks (more flexible pattern)
    final markdownPatterns = [
      RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false),
      RegExp(r'```\s*([\s\S]*?)\s*```', caseSensitive: false),
    ];
    
    for (var pattern in markdownPatterns) {
      final match = pattern.firstMatch(cleaned);
      if (match != null && match.groupCount > 0) {
        cleaned = match.group(1)!.trim();
        debugPrint('   - Removed markdown wrapper');
        break;
      }
    }
    
    // Remove any leading/trailing text before/after JSON
    // Find the first { and last }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    
    if (start == -1 || end == -1 || start >= end) {
      debugPrint('   ❌ No valid JSON structure found');
      debugPrint('   ❌ Text: ${text.substring(0, text.length > 200 ? 200 : text.length)}...');
      throw Exception('No valid JSON found in response');
    }
    
    cleaned = cleaned.substring(start, end + 1);
    
    // Try to parse to validate it's valid JSON
    try {
      jsonDecode(cleaned);
      debugPrint('   ✅ JSON extracted and validated successfully');
      return cleaned;
    } catch (e) {
      debugPrint('   ❌ Extracted text is not valid JSON: $e');
      debugPrint('   ❌ Extracted: ${cleaned.substring(0, cleaned.length > 200 ? 200 : cleaned.length)}...');
      throw Exception('Invalid JSON: $e');
    }
  }

  void _navigateToItemDetail(ItemModel item) async {
    debugPrint('🔗 Navigating to item: ${item.name} (ID: ${item.id})');
    
    try {
      // CHECK IF USER IS LOGGED IN
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId == null) {
        debugPrint('❌ User not logged in!');
        
        // Show login required dialog
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Login Required'),
              content: const Text('Please login to view item details and make bookings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushNamed(context, '/login'); // Navigate to login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                  ),
                  child: const Text('Login'),
                ),
              ],
            );
          },
        );
        return;
      }
      
      debugPrint('✅ User is logged in: $userId');
      debugPrint('📦 Using toDetailMap() for navigation');
      
      // Navigate using MaterialPageRoute with the item map
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
      
      // Show error message
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open item details: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isProcessing) _buildProcessingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isReady = _apiKey != null && _allItems.isNotEmpty;
    
    return AppBar(
      backgroundColor: AppColors.accentColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Groq AI Assistant',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(
            isReady ? '${_allItems.length} items • $_debugInfo' : _debugInfo,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: message.isUser ? AppColors.accentColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!message.isUser)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (message.suggestedItems != null && message.suggestedItems!.isNotEmpty)
            _buildSuggestedItems(message.suggestedItems!),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSuggestedItems(List<ItemModel> items) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => _navigateToItemDetail(item),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: item.images.isNotEmpty
                        ? Image.network(
                            item.images[0].toString(),
                            height: 120,
                            width: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 120,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
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
                        Text(
                          'RM ${item.pricePerDay.toStringAsFixed(2)}/day',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
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
            'AI is thinking...',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                    hintText: isReady ? "Try: 'formal outfit'" : "Setup required...",
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
                  color: (_isProcessing || !isReady) ? Colors.grey : AppColors.accentColor,
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

// Helper extension
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// Supporting classes
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

  ChatbotResponse({
    required this.message,
    required this.items,
  });
}