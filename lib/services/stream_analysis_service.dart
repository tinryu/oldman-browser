// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service connecting to the external Node.js stream analyzer.
class StreamAnalysisService {
  static const String _analyzerEndpoint = 'http://127.0.0.1:3001/analyze';
  static Process? _analyzerProcess;
  static bool _isStarting = false;

  /// Ensures the analyzer server is running before attempting to call it.
  static Future<void> _ensureServerRunning() async {
    if (_isStarting) {
      // Wait a bit if it's currently starting
      await Future.delayed(const Duration(seconds: 2));
      return;
    }

    try {
      // Quick check if the server is already alive
      final pingResponse = await http
          .get(Uri.parse('http://127.0.0.1:3001'))
          .timeout(const Duration(milliseconds: 500));
      if (pingResponse.statusCode == 404 || pingResponse.statusCode == 200) {
        return; // It's up (the root endpoint might return 404, but that means the server responded)
      }
    } catch (_) {
      // Expected if not running
    }

    _isStarting = true;
    try {
      const String binaryName = 'analyzer-win-v3.exe';

      // 1. Check for "sidecar" binary (next to the .exe in build/release)
      final executablePath = Platform.resolvedExecutable;
      final appDir = File(executablePath).parent;
      final sidecarPath = p.join(appDir.path, binaryName);
      final sidecarFile = File(sidecarPath);
      
      print('Probing for analyzer at: $sidecarPath');
      
      File exeFile;
      if (await sidecarFile.exists()) {
        print('SUCCESS: Found sidecar analyzer at: ${sidecarFile.path}');
        exeFile = sidecarFile;
      } else {
        print('INFO: Sidecar analyzer NOT found. Falling back to temporary extraction.');
        // 2. Fallback: Extract from assets to temp directory (debug/dev mode)
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = p.join(tempDir.path, binaryName);
        exeFile = File(tempFilePath);
        
        print('Probing for cached analyzer at: $tempFilePath');

        if (!await exeFile.exists()) {
          try {
            print('Extracting analyzer from assets to: $tempFilePath');
            final byteData = await rootBundle.load('assets/bin/$binaryName');
            await exeFile.writeAsBytes(
              byteData.buffer.asUint8List(),
              flush: true,
            );
          } catch (loadError) {
            print('Error loading analyzer asset: $loadError');
            rethrow;
          }
        }
      }

      // Start the hidden process
      print('Starting analyzer process: ${exeFile.path}');
      _analyzerProcess = await Process.start(
        exeFile.path,
        [],
        mode: ProcessStartMode.detached,
      );

      // Give the Node server a moment to start listening
      await Future.delayed(const Duration(seconds: 4));
      
      // Check if it's still alive/responding
      final isUp = await pingServer();
      if (!isUp) {
        print('WARNING: Analyzer started but not responding to ping after 4s.');
      } else {
        print('SUCCESS: Analyzer is up and responding.');
      }
    } catch (e) {
      print('CRITICAL: Failed to start analyzer background process: $e');
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  /// Calls the external Node.js server to perform stream analysis on [url]
  static Future<Map<String, dynamic>> analyzeUrl(String url) async {
    await _ensureServerRunning();

    try {
      final response = await http
          .post(
            Uri.parse(_analyzerEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(
            const Duration(seconds: 40),
          ); // Give it enough time to run Puppeteer

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return Map<String, dynamic>.from(decoded);
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Connectivity error to analyzer: $e');
      throw Exception(
        'Failed to connect to the internal stream analyzer. [Type: ${e.runtimeType}]\nError: $e',
      );
    }
  }

  /// Checks if the analyzer server is currently responding.
  static Future<bool> pingServer() async {
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:3001'))
          .timeout(const Duration(milliseconds: 800));
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  /// Optional: Stop the analyzer if needed (usually detaches and dies with app if not truly detached)
  static void killAnalyzer() {
    _analyzerProcess?.kill();
    _analyzerProcess = null;
  }
}
