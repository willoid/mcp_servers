import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:collection';
import '../models/message.dart';
import '../services/anthropic_service.dart';
import '../services/mcp_service.dart';
import '../widgets/message_bubble.dart';

/// ============================================
/// CHAT SCREEN - MAIN INTERFACE
/// ============================================
/// This is the primary screen of the application
/// It manages the entire chat experience including:
/// - Message display and scrolling
/// - User input handling
/// - API communication
/// - MCP tool integration
/// - State management
///
/// ARCHITECTURE:
/// - Stateful widget to manage conversation state
/// - Integrates with AnthropicService for AI responses
/// - Integrates with MCPService for tool capabilities
/// - Manages message list and UI updates
/// ============================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ============================================
  // CONTROLLERS AND SERVICES
  // ============================================

  // Controls the text input field
  final TextEditingController _textController = TextEditingController();

  // Controls scrolling of the message list
  final ScrollController _scrollController = ScrollController();

  // Stores all messages in the conversation
  final List<Message> _messages = [];

  // Service for communicating with Anthropic's Claude API
  final AnthropicService _anthropicService = AnthropicService();

  // Service for managing MCP (Model Context Protocol) tools
  final MCPService _mcpService = MCPService();

  // ============================================
  // STATE VARIABLES
  // ============================================

  bool _isLoading = false;

  bool _mcpInitialized = false;

  @override
  void initState() {
    super.initState();
    _addSystemMessage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMCP();
    });
  }

  /// ============================================
  /// MCP INITIALIZATION
  /// ============================================
  /// Connects to MCP servers for tool capabilities
  /// These servers provide:
  /// - Weather information
  /// - Calculator functions
  /// - Web search capabilities
  ///
  /// In production, these would be actual server URLs
  /// For learning, we simulate with local implementations
  /// ============================================
  Future<void> _initializeMCP() async {
    try {
      await _mcpService.initialize();

      setState(() {
        _mcpInitialized = true;
      });

      _showSnackBar(
        'Connected to ${_mcpService.availableTools.length} MCP tools',
        isError: false,
      );
    } catch (e) {
      print('MCP initialization failed: $e');
    }
  }

  /// ============================================
  /// WELCOME MESSAGE
  /// ============================================
  /// Shows initial greeting and capabilities
  /// Helps users understand what they can do
  /// ============================================
  void _addSystemMessage() {
    setState(() {
      _messages.add(
        Message(
          id: DateTime.now().toString(),
          content: 'Hello! I\'m Claude, your AI assistant. I can help you with:\n\n'
              '• General questions and conversations\n'
              '• Weather information (using MCP)\n'
              '• Calculations (using MCP)\n'
              '• Web searches (using MCP)\n\n'
              'How can I help you today?',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  /// ============================================
  /// SEND MESSAGE LOGIC
  /// ============================================
  /// Main function that handles sending messages to AI
  ///
  /// PROCESS FLOW:
  /// 1. Validate input
  /// 2. Add user message to chat
  /// 3. Create placeholder for AI response
  /// 4. Stream AI response in real-time
  /// 5. Handle errors gracefully
  /// ============================================
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();

    if (text.isEmpty || _isLoading) return;

    _textController.clear();

    final userMessage = Message(
      id: DateTime.now().toString(),
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _scrollToBottom();


    final assistantMessage = Message(
      id: '${DateTime.now()}_assistant',
      content: '', // Starts empty, will be filled by streaming
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isStreaming: true, // Shows typing indicator
    );

    setState(() {
      _messages.add(assistantMessage);
    });

    try {

      final tools = _mcpInitialized ? _mcpService.availableTools : null;

      String fullResponse = '';

      await for (final chunk in _anthropicService.sendMessage(
        messages: _messages.where((m) => m.role != MessageRole.system).toList(),
        availableTools: tools,
        onToolUse: (toolName, args) async {
          return await _mcpService.executeTool(toolName, args);
        },
      )) {
        fullResponse = chunk;

        setState(() {
          final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
          if (index != -1) {
            _messages[index] = assistantMessage.copyWith(
              content: fullResponse,
              isStreaming: true,
            );
          }
        });
        // Keep scrolling as new content arrives
        _scrollToBottom();
      }
      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
        if (index != -1) {
          _messages[index] = assistantMessage.copyWith(
            content: fullResponse,
            isStreaming: false, // Stop showing typing indicator
          );
        }
      });
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');

      setState(() {
        _messages.removeWhere((m) => m.id == assistantMessage.id);
      });
    } finally {
      // CLEANUP: Always reset loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ============================================
  /// UTILITY FUNCTIONS
  /// ============================================

  /// Scrolls the chat to the bottom (latest message)
  /// Uses PostFrameCallback to ensure it runs after the UI updates
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Shows a temporary message at the bottom of the screen
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ============================================
  /// BUILD METHOD - UI CONSTRUCTION
  /// ============================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline),
            const SizedBox(width: 8),
            const Text('AI Chat with MCP'),
            const Spacer(),

            // MCP STATUS INDICATOR
            // Shows number of connected tools
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // Green if connected, orange if not
                color: _mcpInitialized ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _mcpInitialized ? Icons.check_circle : Icons.warning,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _mcpInitialized
                        ? '${_mcpService.availableTools.length} tools'
                        : 'No MCP',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 2,
      ),

      body: Column(
        children: [
          // ============================================
          // TOOL BAR
          // Shows available MCP tools as chips
          // ============================================
          if (_mcpInitialized && _mcpService.availableTools.isNotEmpty)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _mcpService.availableTools.map((tool) {
                  IconData icon;
                  switch (tool.name) {
                    case 'get_weather':
                      icon = Icons.cloud;
                      break;
                    case 'calculate':
                      icon = Icons.calculate;
                      break;
                    case 'web_search':
                      icon = Icons.search;
                      break;
                    default:
                      icon = Icons.extension;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: Icon(icon, size: 16),
                      label: Text(
                        tool.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ============================================
          // MESSAGE LIST
          // Displays all messages with scrolling
          // ============================================
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(
                  message: _messages[index],
                  showAvatar: index == 0 ||
                      _messages[index].role != _messages[index - 1].role,
                );
              },
            ),
          ),

          // ============================================
          // INPUT AREA
          // Text field and send button
          // ============================================
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null, // Allow multiple lines
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      // KEYBOARD SHORTCUT: Cmd/Ctrl + Enter to send
                      onChanged: (text) {
                        if (text.endsWith('\n') &&
                            (HardwareKeyboard.instance.isControlPressed ||
                                HardwareKeyboard.instance.isMetaPressed)) {
                          _sendMessage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // SEND BUTTON
                  CircleAvatar(
                    backgroundColor: theme.primaryColor,
                    radius: 24,
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // CLEANUP: Prevent memory leaks
    _textController.dispose();
    _scrollController.dispose();
    _mcpService.dispose();
    super.dispose();
  }
}