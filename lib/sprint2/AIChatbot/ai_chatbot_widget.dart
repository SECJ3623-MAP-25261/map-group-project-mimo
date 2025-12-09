import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/home/models/item_model.dart';
import 'package:profile_managemenr/home/screens/item_detail_screen.dart'; // Add this import
import '../../services/item_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

class AIChatbotWidget extends StatefulWidget {
  final Function(ItemModel) onItemSelected;

  const AIChatbotWidget({
    super.key,
    required this.onItemSelected,
  });

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
        "3. Restart the app"
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
        "I have ${_allItems.length} items ready. Try: 'formal outfit', 'casual wear', or 'traditional clothes'."
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
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );
    debugPrint(_speechAvailable ? '✅ Speech ready' : '⚠️ Speech not available');
  }

  void _startListening() async {
    if (!_speechAvailable) {
      _addBotMessage("Voice not available on this device.");
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _messageController.text = result.recognizedWords;
          _sendMessage();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _addBotMessage(String text, {List<ItemModel>? suggestedItems}) {
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

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
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
      setState(() => _isProcessing = false);
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

RULES:
1. Respond ONLY with valid JSON (no markdown, no explanations)
2. Format: {"reply": "friendly message", "item_ids": ["id1", "id2"]}
3. Match items by category/name/description
4. Return 3-6 items max
5. Use Malaysian English (friendly tone)
6. For non-outfit questions, use empty item_ids: []

Examples:
{"reply": "Here are some nice formal outfits!", "item_ids": ["item1", "item2"]}
{"reply": "Check out these casual pieces!", "item_ids": ["item3"]}
{"reply": "You can pay via bank transfer.", "item_ids": []}''';

      // Make API call
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile', // Fast & free model
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      debugPrint('📡 Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ API Error: ${response.body}');
        throw Exception('Groq API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final aiResponse = data['choices'][0]['message']['content'] as String;
      
      debugPrint('📥 AI Response: $aiResponse');

      // Extract JSON
      String jsonString = _extractJSON(aiResponse);
      debugPrint('🔍 Extracted JSON: $jsonString');

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
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
      debugPrint('🔥 Error: $e');
      debugPrint('Stack: $stack');
      return ChatbotResponse(
        message: "Oops! Try asking: 'formal outfit', 'casual wear', or 'traditional clothes'.",
        items: [],
      );
    }
  }

  String _extractJSON(String text) {
    String cleaned = text.trim();
    
    // Remove markdown
    final markdownMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(cleaned);
    if (markdownMatch != null) {
      cleaned = markdownMatch.group(1)!.trim();
    }
    
    // Extract { ... }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    
    if (start != -1 && end > start) {
      cleaned = cleaned.substring(start, end + 1);
    }
    
    if (!cleaned.startsWith('{') || !cleaned.endsWith('}')) {
      throw Exception('Invalid JSON: $cleaned');
    }
    
    return cleaned;
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
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Groq AI Assistant',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  isReady ? 'Online • ${_allItems.length} items • $_debugInfo' : _debugInfo,
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
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
          if (message.suggestedItems != null && message.suggestedItems!.isNotEmpty)
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
                // Convert ItemModel to Map for ItemDetailScreen
                final itemMap = {
                  'id': item.id,
                  'name': item.name,
                  'category': item.category,
                  'pricePerDay': item.pricePerDay,
                  'description': item.description,
                  'size': item.size,
                  'images': item.images,
                  'renterId': item.renterId,
                  //'availability': item.availability,
                };
                
                // Close the chatbot widget first
                Navigator.pop(context);
                
                // Then navigate to item detail
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(item: itemMap),
                  ),
                );
              } catch (e) {
                debugPrint('❌ Navigation error: $e');
                // If navigation fails, just call the callback
                widget.onItemSelected(item);
              }
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentColor.withOpacity(0.3)),
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
                            item.images[0],
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
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
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
                    hintText: isReady ? 'Try: formal outfit...' : 'Setup required...',
                    border: InputBorder.none,
                    hintStyle: const TextStyle(fontSize: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isReady ? (_isListening ? _stopListening : _startListening) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: !isReady ? Colors.grey : _isListening ? Colors.red : AppColors.accentColor,
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
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
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