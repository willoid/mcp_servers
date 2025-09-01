import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/mcp_tool.dart';
import '../models/message.dart';
import 'package:flutter/foundation.dart';

class AnthropicService {
  // Use local proxy server for web, direct API for mobile
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Local proxy server
    }
    return 'https://api.anthropic.com/v1';
  }

  static const String _model = 'claude-sonnet-4-20250514';
  late final String _apiKey;

  AnthropicService() {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      throw Exception('Anthropic API key not found in environment');
    }
  }

  Stream<String> sendMessage({
    required List<Message> messages,
    List<MCPTool>? availableTools,
    Future<dynamic> Function(String toolName, Map<String, dynamic> toolInput)? onToolUse,
  }) async* {
    try {
      final body = {
        'model': _model,
        'max_tokens': 4096,
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': true,
      };

      if (availableTools != null && availableTools.isNotEmpty) {
        body['tools'] = availableTools.map((t) => t.toAnthropicTool()).toList();
        body['tool_choice'] = {'type': 'auto'};
      }

      final client = http.Client();
      final request = http.Request('POST', Uri.parse('${_baseUrl}/messages'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      });
      request.body = json.encode(body);

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('Error: ${streamedResponse.statusCode} - $errorBody');
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String buffer = '';
      String? currentToolName;
      String? currentToolId;
      Map<String, dynamic> currentToolInput = {};
      String toolInputBuffer = '';

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();

          if (data == '[DONE]') {
            break;
          }

          if (data.isEmpty) continue;

          try {
            final json = jsonDecode(data);

            if (json['type'] == 'content_block_delta') {
              if (json['delta'] != null) {
                if (json['delta']['text'] != null) {
                  final text = json['delta']['text'];
                  buffer += text;
                  yield buffer;
                } else if (json['delta']['partial_json'] != null) {
                  toolInputBuffer += json['delta']['partial_json'];
                }
              }
            }
            else if (json['type'] == 'content_block_start') {
              if (json['content_block'] != null) {
                if (json['content_block']['type'] == 'text') {
                  final text = json['content_block']['text'] ?? '';

                  if (text.isNotEmpty) {
                    buffer += text;
                    yield buffer;
                  }
                } else if (json['content_block']['type'] == 'tool_use') {
                  currentToolName = json['content_block']['name'];
                  currentToolId = json['content_block']['id'];
                  toolInputBuffer = '';
                  print('Tool use started ${currentToolName}');
                }
              }
            } else if (json['type'] == 'content_block_stop') {
              if(currentToolName != null && toolInputBuffer.isNotEmpty){
                try{
                  currentToolInput = jsonDecode(toolInputBuffer);
                  print("Executing Tool: $currentToolName with: $currentToolInput");

                  if(onToolUse != null){
                    final result = await onToolUse(currentToolName, currentToolInput);
                    buffer += '\n\ToolResult: ${jsonEncode(result)}';
                    yield buffer;
                  }
                }catch (e){
                  print('Error catching tool usage $e');
                }

                currentToolName = null;
                currentToolId= null;
                toolInputBuffer = '';
              }
            }
          }catch (e){
            print('Error reading json package $e');
          }
        }
      }

      client.close();
    } catch (e) {
      yield 'Error: ${e.toString()}';
    }
  }

  Future<bool> validateApiKey() async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'Hi'},
          ],
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
