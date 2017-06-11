// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import '../webkit_inspection_protocol.dart';

class WipRuntime extends WipDomain {
  WipRuntime(WipConnection connection) : super(connection);

  Future enable() => sendCommand('Runtime.enable');
  Future disable() => sendCommand('Runtime.disable');

  Stream<ConsoleAPIEvent> get onConsoleAPICalled => eventStream(
      'Runtime.consoleAPICalled',
      (WipEvent event) => new ConsoleAPIEvent(event));

  Stream<ExceptionThrownEvent> get onExceptionThrown => eventStream(
      'Runtime.exceptionThrown',
      (WipEvent event) => new ExceptionThrownEvent(event));
}

class ConsoleAPIEvent extends WrappedWipEvent {
  ConsoleAPIEvent(WipEvent event) : super(event);

  /// Type of the call. Allowed values: log, debug, info, error, warning, dir,
  /// dirxml, table, trace, clear, startGroup, startGroupCollapsed, endGroup,
  /// assert, profile, profileEnd.
  String get type => params['type'];

  /// Call arguments.
  List<RemoteObject> get args =>
      (params['args'] as List).map((m) => new RemoteObject(m)).toList();

  // TODO: stackTrace, StackTrace, Stack trace captured when the call was made.
}

class ExceptionThrownEvent extends WrappedWipEvent {
  ExceptionThrownEvent(WipEvent event) : super(event);

  /// Timestamp of the exception.
  int get timestamp => params['timestamp'];

  ExceptionDetails get exceptionDetails =>
      new ExceptionDetails(params['exceptionDetails']);
}

class ExceptionDetails {
  final Map<String, dynamic> _map;

  ExceptionDetails(this._map);

  /// Exception id.
  int get exceptionId => _map['exceptionId'];

  /// Exception text, which should be used together with exception object when
  /// available.
  String get text => _map['text'];

  /// Line number of the exception location (0-based).
  int get lineNumber => _map['lineNumber'];

  /// Column number of the exception location (0-based).
  int get columnNumber => _map['columnNumber'];

  /// URL of the exception location, to be used when the script was not
  /// reported.
  @optional
  String get url => _map['url'];

  /// Script ID of the exception location.
  @optional
  String get scriptId => _map['scriptId'];

  /// JavaScript stack trace if available.
  @optional
  StackTrace get stackTrace =>
      _map['stackTrace'] == null ? null : new StackTrace(_map['stackTrace']);

  /// Exception object if available.
  @optional
  RemoteObject get exception =>
      _map['exception'] == null ? null : new RemoteObject(_map['exception']);

  String toString() => text;
}

class StackTrace {
  final Map<String, dynamic> _map;

  StackTrace(this._map);

  /// String label of this stack trace. For async traces this may be a name of
  /// the function that initiated the async call.
  @optional
  String get description => _map['description'];

  List<CallFrame> get callFrames =>
      (_map['callFrames'] as List).map((m) => new CallFrame(m)).toList();

  // TODO: parent, StackTrace, Asynchronous JavaScript stack trace that preceded
  // this stack, if available.

  List<String> printFrames() {
    List<CallFrame> frames = callFrames;

    int width = frames.fold(0, (int val, CallFrame frame) {
      return max(val, frame.functionName.length);
    });

    return frames.map((CallFrame frame) {
      return '${frame.functionName}()'.padRight(width + 2) +
          ' ${frame.url} ${frame.lineNumber}:${frame.columnNumber}';
    }).toList();
  }

  String toString() => callFrames.map((f) => '  $f').join('\n');
}

class CallFrame {
  final Map<String, dynamic> _map;

  CallFrame(this._map);

  /// JavaScript function name.
  String get functionName => _map['functionName'];

  /// JavaScript script id.
  String get scriptId => _map['scriptId'];

  /// JavaScript script name or url.
  String get url => _map['url'];

  /// JavaScript script line number (0-based).
  int get lineNumber => _map['lineNumber'];

  /// JavaScript script column number (0-based).
  int get columnNumber => _map['columnNumber'];

  String toString() => '$functionName() ($url $lineNumber:$columnNumber)';
}

class RemoteObject {
  final Map<String, dynamic> _map;

  RemoteObject(this._map);

  String get type => _map['type'];
  String get value => _map['value'];

  String toString() => '$type $value';
}
