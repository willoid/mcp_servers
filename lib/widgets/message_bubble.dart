import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';
import 'typing_indicator.dart';
import 'dart:math' as math;

/// ============================================
/// MESSAGE BUBBLE WIDGET
/// ============================================
/// This is the main visual component that displays each message in the chat
/// It handles both user and AI messages with different styling
///
/// FEATURES:
/// - Markdown rendering for formatted text
/// - Tool usage indicators
/// - Timestamp display
/// - Avatar support
/// - Animated typing indicator
///
/// DATA FLOW:
/// INPUT: Message object containing all message data
/// OUTPUT: Rendered UI widget displayed in the chat list
/// ============================================

class MessageBubble extends StatelessWidget {
  // The message data object containing content, role, timestamp, etc.
  final Message message;

  // Whether to show the avatar (usually hidden for consecutive messages from same sender)
  final bool showAvatar;

  const MessageBubble({
    Key? key,
    required this.message,
    this.showAvatar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // STEP 1: Determine if this is a user message or AI message
    // This affects positioning, colors, and styling
    final isUser = message.role == MessageRole.user;

    // Get the current theme for consistent styling
    final theme = Theme.of(context);

    return Padding(
      // Add vertical spacing between messages
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        // POSITIONING LOGIC:
        // User messages align to the right (end)
        // AI messages align to the left (start)
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, // Align avatars to top
        children: [
          // ============================================
          // AI AVATAR (Left side)
          // Only shown for AI messages when showAvatar is true
          // ============================================
          if (!isUser && showAvatar) ...[
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              radius: 18,
              child: const Icon(
                Icons.smart_toy, // Robot icon for AI
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8), // Space between avatar and bubble
          ],

          // ============================================
          // MESSAGE BUBBLE CONTAINER
          // This is the main content area
          // ============================================
          Flexible(
            // Flexible allows the bubble to grow/shrink based on content
            child: Container(
              // CONSTRAINT: Maximum width is 75% of screen width
              // This prevents messages from spanning the entire screen
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),

              // STYLING: Different colors and borders for user vs AI
              decoration: BoxDecoration(
                // Color scheme:
                // - User messages: Primary color (usually blue)
                // - AI messages: Card color (usually grey/white)
                color: isUser
                    ? theme.primaryColor
                    : theme.cardColor,

                // Rounded corners with chat bubble style
                // Notice the smaller radius on the side near the sender
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4), // Sharp corner for AI
                  bottomRight: Radius.circular(isUser ? 4 : 16), // Sharp corner for user
                ),

                // Subtle shadow for depth
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),

              // ============================================
              // MESSAGE CONTENT
              // ============================================
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // TOOL USAGE INDICATOR
                  // Shows which MCP tools were used for this response
                  // ============================================
                  if (message.toolCalls != null && message.toolCalls!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        // Semi-transparent blue background
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.build, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            // List all tools used, separated by commas
                            'Used: ${message.toolCalls!.map((t) => t.name).join(', ')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ============================================
                  // MAIN MESSAGE CONTENT
                  // Handles three cases:
                  // 1. Streaming with no content yet (show typing indicator)
                  // 2. Markdown content (render with MarkdownBody)
                  // 3. Plain text (render with Text widget)
                  // ============================================
                  if (message.isStreaming && message.content.isEmpty)
                  // Show typing animation while AI is thinking
                    const TypingIndicator()
                  else if (message.content.contains('```') || // Code blocks
                      message.content.contains('**') ||  // Bold text
                      message.content.contains('##'))    // Headers
                  // Render as Markdown for formatted content
                    MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        // Custom styling for markdown elements
                        p: TextStyle(
                          color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
                          fontSize: 14,
                        ),
                        // Code blocks get special styling
                        code: TextStyle(
                          backgroundColor: Colors.grey[800],
                          color: Colors.green[300],
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  else
                  // Plain text rendering
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                    ),

                  // ============================================
                  // TIMESTAMP
                  // Shows when the message was sent
                  // ============================================
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      // Slightly transparent for subtle appearance
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============================================
          // USER AVATAR (Right side)
          // Only shown for user messages when showAvatar is true
          // ============================================
          if (isUser && showAvatar) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              radius: 18,
              child: const Icon(
                Icons.person, // Person icon for user
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Helper method to format timestamp
  /// Converts DateTime to HH:MM format
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
