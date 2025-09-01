class MCPTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final String serverUrl;

  MCPTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.serverUrl,
  });

  factory MCPTool.fromJson(Map<String, dynamic> json, String serverUrl) {
    return MCPTool(
      name: json['name'],
      description: json['description'],
      inputSchema: json['input_schema'] ?? {},
      serverUrl: serverUrl,
    );
  }

  Map<String, dynamic> toAnthropicTool() {
    return {
      'name': name,
      'description': description,
      'input_schema': {
        'properties' : inputSchema["properties"] ?? {},
        'required' : inputSchema["required"] ?? [],
        'type' : 'object',
      },
    };
  }

}