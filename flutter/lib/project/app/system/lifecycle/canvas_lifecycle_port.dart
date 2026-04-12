import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Callback signature for inbound message handlers.
typedef MessageHandler = void Function(Map<String, dynamic> data);

/// Transport-agnostic communication port between Flutter and the host page.
///
/// In iframe mode: uses `postMessage` / `addEventListener('message')`.
/// In hostElement mode: uses direct JS interop via `@JS` annotations.
///
/// MyGame registers handlers via [on] and sends outbound messages via [send].
/// The transport implementation is hidden — MyGame never changes when switching
/// from iframe to hostElement embedding.
class CanvasLifecyclePort {
  final Map<String, List<MessageHandler>> _handlers = {};
  JSFunction? _jsListener;

  /// Whether to use direct JS interop instead of postMessage.
  /// Set to `true` after iframe elimination (Batch 2).
  final bool useDirectInterop;

  CanvasLifecyclePort({this.useDirectInterop = false});

  /// Register a handler for a message [type].
  void on(String type, MessageHandler handler) {
    _handlers.putIfAbsent(type, () => []).add(handler);
  }

  /// Start listening for inbound messages.
  void listen() {
    if (!kIsWeb) return;

    if (useDirectInterop) {
      _listenDirectInterop();
    } else {
      _listenPostMessage();
    }
  }

  /// Send an outbound message to the host page.
  void send(Map<String, dynamic> message) {
    if (!kIsWeb) return;

    if (useDirectInterop) {
      _sendDirectInterop(message);
    } else {
      _sendPostMessage(message);
    }
  }

  /// Clean up listener.
  void dispose() {
    if (_jsListener != null && kIsWeb) {
      web.window.removeEventListener('message', _jsListener!);
      _jsListener = null;
    }
  }

  // ── postMessage transport (iframe mode) ──────────────────────

  void _listenPostMessage() {
    _jsListener = (web.Event event) {
      final msgEvent = event as web.MessageEvent;
      final data = msgEvent.data;
      if (data == null) return;

      final dartData = data.dartify();
      if (dartData is Map) {
        final type = dartData['type'] as String?;
        if (type != null && _handlers.containsKey(type)) {
          final map = Map<String, dynamic>.from(dartData);
          for (final handler in _handlers[type]!) {
            handler(map);
          }
        }
      }
    }.toJS;

    web.window.addEventListener('message', _jsListener!);
  }

  void _sendPostMessage(Map<String, dynamic> message) {
    try {
      final jsMsg = message.jsify();
      // Use globalContext['parent'] instead of web.window.parent because the
      // web package returns null for window.parent in some dart2js builds.
      final parent = globalContext['parent'];
      if (parent != null) {
        (parent as JSObject).callMethod('postMessage'.toJS, jsMsg, '*'.toJS);
      }
    } catch (e) {
      debugPrint('[CanvasLifecyclePort] postMessage error: $e');
    }
  }

  // ── Direct JS interop transport (hostElement mode) ───────────

  void _listenDirectInterop() {
    // In hostElement mode, React sets up window._flutterBridge.onMessage
    // which calls into Dart directly. We register a global callback.
    _registerDartCallback((String type, String payloadJson) {
      if (_handlers.containsKey(type)) {
        // Parse JSON payload if present, otherwise pass empty map
        Map<String, dynamic> data = {'type': type};
        if (payloadJson.isNotEmpty) {
          try {
            // ignore: unnecessary_import
            // Use dart:convert for JSON parsing
            data = {'type': type, ...Uri.splitQueryString(payloadJson)};
          } catch (_) {
            // Fallback: just pass the type
          }
        }
        for (final handler in _handlers[type]!) {
          handler(data);
        }
      }
    });
  }

  void _sendDirectInterop(Map<String, dynamic> message) {
    try {
      final type = message['type'] as String;
      _callReactCallback(type, message.jsify());
    } catch (e) {
      debugPrint('[CanvasLifecyclePort] JS interop error: $e');
    }
  }
}

// ── JS interop bindings for hostElement mode ─────────────────

/// Register a Dart callback that React can invoke directly.
@JS('_registerFlutterCallback')
external set _registerFlutterCallback(JSFunction fn);

void _registerDartCallback(void Function(String type, String payload) handler) {
  _registerFlutterCallback = ((JSString type, JSString payload) {
    handler(type.toDart, payload.toDart);
  }).toJS;
}

/// Call a React callback from Dart.
@JS('_flutterToReact')
external void _jsFlutterToReact(JSString type, JSAny? payload);

void _callReactCallback(String type, JSAny? payload) {
  try {
    _jsFlutterToReact(type.toJS, payload);
  } catch (e) {
    debugPrint('[CanvasLifecyclePort] _flutterToReact not available: $e');
  }
}
