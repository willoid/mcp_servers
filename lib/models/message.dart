class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<ToolCall>? toolCalls;
  final bool isStreaming;

  Message({
    required  this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.metadata,
    this.toolCalls,
    this.isStreaming = false,
  });

  Message copyWith({
    String? content,
    bool? isStreaming,
    List<ToolCall>? toolCalls,
  }){
    return Message(
      id:id,
      content: content ?? this.content,
      role:role,
      timestamp: timestamp,
      metadata: metadata,
      toolCalls: toolCalls ?? this.toolCalls,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'role': role.toString().split('.').last,
      'content': content,
      if (toolCalls != null)
        'tool_calls': toolCalls!.map((t) => t.toJson()).toList(),
    };
  }
}

enum MessageRole { user, assistant, system, tool }

class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic>? arguments;
  final String? result;

  ToolCall({required this.id, required this.name, this.arguments, this.result});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'arguments': arguments,
    if (result != null) 'result': result,
  };
}