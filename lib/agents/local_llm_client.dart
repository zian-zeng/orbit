import 'dart:async';
import 'dart:convert';

import 'package:chatbotapp/apis/api_service.dart';
import 'package:chatbotapp/constants/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class LocalLlmConfig {
  const LocalLlmConfig({
    required this.endpoint,
    required this.model,
    this.timeout = const Duration(seconds: 45),
  });

  static const String defaultEndpoint = 'http://127.0.0.1:11434';
  static const String defaultModel = 'gemma3:4b';

  final String endpoint;
  final String model;
  final Duration timeout;

  static LocalLlmConfig fromEnvironment() {
    const endpointDefine = String.fromEnvironment('LOCAL_LLM_ENDPOINT');
    const modelDefine = String.fromEnvironment('LOCAL_LLM_MODEL');

    final endpoint = _firstConfiguredValue(
      dartDefineValue: endpointDefine,
      envNames: const ['LOCAL_LLM_ENDPOINT', 'OLLAMA_ENDPOINT'],
      fallback: defaultEndpoint,
    );
    final model = _firstConfiguredValue(
      dartDefineValue: modelDefine,
      envNames: const ['LOCAL_LLM_MODEL', 'OLLAMA_MODEL'],
      fallback: defaultModel,
    );

    return LocalLlmConfig(endpoint: endpoint, model: model);
  }

  static String _firstConfiguredValue({
    required String dartDefineValue,
    required List<String> envNames,
    required String fallback,
  }) {
    final trimmedDefine = dartDefineValue.trim();
    if (trimmedDefine.isNotEmpty) {
      return trimmedDefine;
    }

    if (dotenv.isInitialized) {
      for (final envName in envNames) {
        final value = dotenv.env[envName]?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    return fallback;
  }
}

class LocalLlmRequest {
  const LocalLlmRequest({
    required this.systemPrompt,
    required this.prompt,
    this.temperature = 0.25,
    this.maxTokens = 900,
  });

  final String systemPrompt;
  final String prompt;
  final double temperature;
  final int maxTokens;
}

class LocalLlmResult {
  const LocalLlmResult({
    required this.text,
    required this.model,
    required this.provider,
  });

  final String text;
  final String model;
  final String provider;
}

abstract class LocalLlmClient {
  Future<LocalLlmResult> generate(LocalLlmRequest request);
}

class LocalLlmException implements Exception {
  const LocalLlmException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeminiThenOllamaLlmClient implements LocalLlmClient {
  GeminiThenOllamaLlmClient({
    LocalLlmClient? gemmaClient,
    String geminiModel = Constants.geminiTextModel,
  })  : _gemmaClient = gemmaClient ?? OllamaLocalLlmClient(),
        _geminiModel = geminiModel;

  final LocalLlmClient _gemmaClient;
  final String _geminiModel;

  @override
  Future<LocalLlmResult> generate(LocalLlmRequest request) async {
    Object? geminiError;
    if (ApiService.isConfigured) {
      try {
        final model = GenerativeModel(
          model: _geminiModel,
          apiKey: ApiService.apiKey,
          generationConfig: GenerationConfig(
            temperature: request.temperature,
            topP: 0.9,
            topK: 32,
            maxOutputTokens: request.maxTokens,
          ),
          systemInstruction: Content.system(request.systemPrompt),
        );
        final response = await model
            .generateContent([Content.text(request.prompt)]).timeout(
                const Duration(seconds: 45));
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          return LocalLlmResult(
            text: text,
            model: _geminiModel,
            provider: 'gemini',
          );
        }
        geminiError = const LocalLlmException(
          'Gemini returned an empty response.',
        );
      } catch (error) {
        geminiError = error;
      }
    } else {
      geminiError =
          const LocalLlmException('Gemini API key is not configured.');
    }

    try {
      return await _gemmaClient.generate(request);
    } catch (gemmaError) {
      throw LocalLlmException(
        'Gemini failed: $geminiError. Gemma failed: $gemmaError',
      );
    }
  }
}

class OllamaLocalLlmClient implements LocalLlmClient {
  OllamaLocalLlmClient({
    LocalLlmConfig? config,
    http.Client? httpClient,
  })  : config = config ?? LocalLlmConfig.fromEnvironment(),
        _httpClient = httpClient ?? http.Client();

  final LocalLlmConfig config;
  final http.Client _httpClient;

  @override
  Future<LocalLlmResult> generate(LocalLlmRequest request) async {
    final endpoint = Uri.parse(config.endpoint);
    final uri =
        endpoint.replace(path: _joinPath(endpoint.path, 'api/generate'));

    final response = await _httpClient
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.model,
            'system': request.systemPrompt,
            'prompt': request.prompt,
            'stream': false,
            'options': {
              'temperature': request.temperature,
              'num_predict': request.maxTokens,
              'num_ctx': 4096,
            },
          }),
        )
        .timeout(config.timeout);
    final body = response.body;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LocalLlmException(
        'Local model returned HTTP ${response.statusCode}: ${_shorten(body)}',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const LocalLlmException(
          'Local model returned an invalid response.');
    }

    final text = (decoded['response'] as String?)?.trim();
    if (text == null || text.isEmpty) {
      throw const LocalLlmException('Local model returned an empty response.');
    }

    return LocalLlmResult(
      text: text,
      model: (decoded['model'] as String?) ?? config.model,
      provider: 'ollama',
    );
  }

  String _joinPath(String basePath, String suffix) {
    final normalizedBase = basePath.trim();
    if (normalizedBase.isEmpty || normalizedBase == '/') {
      return '/$suffix';
    }
    return '${normalizedBase.replaceAll(RegExp(r'/+$'), '')}/$suffix';
  }

  String _shorten(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 160) {
      return normalized;
    }
    return '${normalized.substring(0, 160)}...';
  }
}
