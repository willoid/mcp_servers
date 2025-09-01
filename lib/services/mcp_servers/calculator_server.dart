import 'dart:math';
import '../../models/mcp_tool.dart';

class CalculatorMCPServer {
  final String name = 'calculator';

  final List<MCPTool> tools = [
    MCPTool(
      name: 'add',
      description: 'add numbers together',
      inputSchema: {
        'type': 'object',
        'properties': {
          'a': {'type': 'number', 'description': 'first number'},
          'b': {'type': 'number', 'description': 'second number'},
        },
        'required': ['a', 'b'],
      },
      serverUrl: 'calculator',
    ),
    MCPTool(
      name: 'subtract',
      description: 'subtract numbers',
      inputSchema: {
        'type': 'object',
        'properties': {
          'a': {'type': 'number', 'description': 'first number'},
          'b': {'type': 'number', 'description': 'second number'},
        },
        'required': ['a', 'b'],
      },
      serverUrl: 'calculator',
    ),
    MCPTool(
      name: 'multiply',
      description: 'multiply numbers',
      inputSchema: {
        'type': 'object',
        'properties': {
          'a': {'type': 'number', 'description': 'first number'},
          'b': {'type': 'number', 'description': 'second number'},
        },
        'required': ['a', 'b'],
      },
      serverUrl: 'calculator',
    ),
    MCPTool(
      name: 'divide',
      description: 'divide first number by second',
      inputSchema: {
        'type': 'object',
        'properties': {
          'a': {'type': 'number', 'description': 'numerator'},
          'b': {
            'type': 'number',
            'description': 'denominator (cannot be zero)',
          },
        },
        'required': ['a', 'b'],
      },
      serverUrl: 'calculator',
    ),
    MCPTool(
      name: 'sqrt',
      description: 'take the square root of a number',
      inputSchema: {
        'type': 'object',
        'properties': {
          'number': {
            'type': 'number',
            'description': 'number to take the square root of',
          },
        },
        'required': ['number'],
      },
      serverUrl: 'calculator',
    ),
    MCPTool(
      name: 'power',
      description: 'raise a number to a power',
      inputSchema: {
        'type': 'object',
        'properties': {
          'base': {'type': 'number', 'description': 'base number'},
          'exponent': {'type': 'number', 'description': 'exponent'},
        },
        'required': ['base', 'exponent'],
      },
      serverUrl: 'calculator',
    ),
  ];

  Future<Map<String, dynamic>> executeTools(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      switch (toolName) {
        case 'add':
          final a = (arguments['a'] as num).toDouble();
          final b = (arguments['b'] as num).toDouble();
          return {'result': a + b};
        case 'subtract':
          final a = (arguments['a'] as num).toDouble();
          final b = (arguments['b'] as num).toDouble();
          return {'result': a - b};
        case 'multiply':
          final a = (arguments['a'] as num).toDouble();
          final b = (arguments['b'] as num).toDouble();
          return {'result': a * b};
        case 'divide':
          final a = (arguments['a'] as num).toDouble();
          final b = (arguments['b'] as num).toDouble();
          if (b == 0) {
            return {'error': 'Cannot divide by zero'};
          }
          return {'result': a / b};
        case 'sqrt':
          final number = (arguments['number'] as num).toDouble();
          if (number < 0) {
            return {
              'error': 'Cannot take the square root of a negative number',
            };
          }
          return {'result': sqrt(number)};
        case 'power':
          final base = (arguments['base'] as num).toDouble();
          final exponent = (arguments['exponent'] as num).toDouble();
          return {'result': pow(base, exponent)};
        default:
          return {'error': 'Unknown tool: $toolName'};
      }
    } catch (e) {
      return {'error': 'error executing tool: $e'};
    }
  }
}
