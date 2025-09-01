import 'dart:convert';
import 'dart:async';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/mcp_tool.dart';
import 'mcp_servers/calculator_server.dart';
import 'mcp_servers/weather_server.dart';
import 'mcp_servers/web_search_server.dart';

class MCPService {
  final Map<String, MCPServerConnection> _servers = {};
  final CalculatorMCPServer _calculatorServer = CalculatorMCPServer();
  final WeatherMCPServer _weatherServer = WeatherMCPServer();
  final WebSearchMCPServer _webSearchServer = WebSearchMCPServer();

  List<MCPTool> _availableTools = [];
  List<MCPTool> get availableTools => _availableTools;

  Future<void> initialize() async {
    try {
      // Add all calculator tools
      _availableTools.addAll(_calculatorServer.tools);

      // Add weather tools
      _availableTools.addAll(_weatherServer.tools);

      // Add web search tools
      _availableTools.addAll(_webSearchServer.tools);

      print("MCP service initialized with ${_availableTools.length} tools");
    } catch (e) {
      print('Error initializing MCP service. Error: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> executeTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    // Check calculator server
    if (_calculatorServer.tools.any((tool) => tool.name == toolName)) {
      return await _calculatorServer.executeTools(toolName, arguments);
    }

    // Check weather server
    if (_weatherServer.tools.any((tool) => tool.name == toolName)) { // Corrected condition
      return await _weatherServer.executeTools(toolName, arguments); // Corrected call
    }

    // Check web search server
    if (_webSearchServer.tools.any((tool) => tool.name == toolName)) { // Corrected condition
      return await _webSearchServer.executeTools(toolName, arguments); // Corrected call
    }

    return {'error': 'Tool not found: $toolName'};
  }

  void dispose() {
    for (final server in _servers.values) {
      server.dispose();
    }
  }
}

class MCPServerConnection {
  final String url;
  late final WebSocketChannel _channel;
  late final Peer _peer;

  //this is a named private constructor
  MCPServerConnection._(this.url, this._channel, this._peer);

  static Future<MCPServerConnection> connect(String url) async {
    final wsUrl = url.replaceFirst('http', 'ws');
    final channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws'));
    final peer = Peer(
      channel.cast<String>(),
      onUnhandledError: (error, stack) {
        print('Unhandled MCP error: $error');
      },
    );
    unawaited(peer.listen());
    await peer.sendRequest('initialize', {
      'protocolVersion': '1.0.0',
      'clientInfo': {'name': 'flutter_ai_chat', 'version': '1.0.0'},
    });
    return MCPServerConnection._(url, channel, peer);
  }

  Future<List<MCPTool>> listTools() async {
    final response = await _peer.sendRequest(
      'tools/list',
    ); 
    final tools = response['tools'] as List<dynamic>;

    return tools.map((t) => MCPTool.fromJson(t, url)).toList();
  }

  Future<Map<String, dynamic>> executeTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    final response = await _peer.sendRequest('tools/call', {
      'name': name,
      'arguments': arguments,
    });
    return response as Map<String, dynamic>;
  }

  void dispose() {
    _peer.close();
    _channel.sink.close();
  }
}
