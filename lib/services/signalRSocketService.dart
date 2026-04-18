import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/services/api/userApi.dart';
import 'dart:math';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/localizationService.dart';

class SignalRSocketService extends AppApi {
  WebSocketChannel? _channel;
  UserApi? _userApi;
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  Stream<String> get statusStream => _statusController.stream;

  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _shouldStayConnected = true;
  String? _currentUserId;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  String? _connectionToken;

  SignalRSocketService({Function? getContextCallBack})
      : super(getContextCallBack: getContextCallBack);


  Future<Map<String, dynamic>?> _negotiate() async {
    try {
      final negotiateUrl = 'https://${Constants.tilerDomain}/signalr/negotiate?clientProtocol=1.5&connectionData=%5B%7B%22name"%3A"vibeUpdateHub"%7D%5D';

      final response = await http.get(Uri.parse(negotiateUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }


  Future<void> createVibeConnection() async {
    if (!_shouldStayConnected) return;

    var isAuthenticated = await this.authentication.isUserAuthenticated();
    if (!isAuthenticated.item1) {
      throw TilerError(
          Message: LocalizationService.instance.translations.userIsNotAuthenticated);
    }

    await checkAndReplaceCredentialCache();

    try {
      final context = this.getContextCallBack?.call();
      if (context != null && context.mounted) {
        final deviceState = BlocProvider.of<DeviceSettingBloc>(context).state;
        if (deviceState is DeviceSettingLoaded) {
          _currentUserId = deviceState.sessionProfile?.userProfile?.id;
        }
      }

      if (_currentUserId == null || _currentUserId!.isEmpty) {
        _userApi ??= UserApi(getContextCallBack: this.getContextCallBack!);
        final userProfile = await _userApi!.getUserProfile();

        if (userProfile != null && userProfile.id != null &&
            userProfile.id!.isNotEmpty) {
          _currentUserId = userProfile.id;
        } else {
          return;
        }
      }

      final negotiateData = await _negotiate();
      if (negotiateData == null) {
        _attemptReconnect();
        return;
      }

      _connectionToken = negotiateData['ConnectionToken'];

      if (_connectionToken == null) {
        _attemptReconnect();
        return;
      }

      final encodedToken = Uri.encodeComponent(_connectionToken!);
      final connectionData = Uri.encodeComponent('[{"name":"vibeUpdateHub"}]');
      final wsUrl = 'wss://${Constants.tilerDomain}/signalr/connect?transport=webSockets&clientProtocol=1.5&connectionToken=$encodedToken&connectionData=$connectionData';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
            (message) => _handleMessage(message),
        onError: (error) {
          if (error is WebSocketChannelException && error.inner != null) {
            final inner = error.inner!;
            try {
              final msg = (inner as dynamic).message;
              Utility.debugPrint('WebSocket Error: $msg');
            } catch (e) {
              Utility.debugPrint('WebSocket Error: ${inner.runtimeType}');
            }
          } else {
            Utility.debugPrint('Error: $error');
          }
          _isConnected = false;
          _keepAliveTimer?.cancel();
          _attemptReconnect();
        },
        onDone: () {
          _isConnected = false;
          _keepAliveTimer?.cancel();
          _attemptReconnect();
        },
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _startKeepAliveTimer();

      await joinUserGroup(_currentUserId!);

    } catch (e) {
      String errorMsg;
      if (e is WebSocketChannelException && e.inner != null) {
        final inner = e.inner!;
        try {
          final msg = (inner as dynamic).message;
          errorMsg=msg;
        } catch (ex) {
          errorMsg=inner.runtimeType.toString();
        }
      } else {
        errorMsg=e.toString();
      }
      _isConnected = false;
      _attemptReconnect();
      throw TilerError(
          Message: '${LocalizationService.instance.translations.socketConnectionError}: $errorMsg'
      );

    }
  }

  void _attemptReconnect() {
    if (!_shouldStayConnected) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      throw TilerError(Message: LocalizationService.instance.translations.webSocketConnectionLostAfter5Attempts);
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    final delaySeconds = pow(2, _reconnectAttempts).toInt();

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      createVibeConnection();
    });
  }


  Future<void> joinUserGroup(String userId) async {
    if (_isConnected && _channel != null) {
      final message = jsonEncode({
        'H': 'vibeUpdateHub',
        'M': 'JoinUserGroup',
        'A': [userId],
        'I': 0
      });
      _channel!.sink.add(message);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      if (message == '{}') return;

      final data = jsonDecode(message);

      if (data is Map) {
        if (data['S'] == 1) {
          return;
        }

        if (data['I'] != null) {
          return;
        }

        if (data['M'] is List) {
          final mList = data['M'] as List;

          for (var item in mList) {
            if (item is Map && item['M'] == 'refreshDataFromSockets') {
              final args = item['A'];
              if (args is List && args.isNotEmpty) {
                dynamic payload = args[0];

                if (payload is String) {
                  try {
                    payload = jsonDecode(payload);
                  } catch (e) {
                    throw TilerError(
                        Message: '${LocalizationService.instance.translations.jsonParseError}: $e'
                    );
                  }
                }

                _processVibeUpdate(payload);
              }
            }
          }
        }
      }
    } catch (e) {
      throw TilerError(
          Message: '${LocalizationService.instance.translations.webSocketMessageHandlingError}: $e'
      );
    }
  }

  void _processVibeUpdate(dynamic data) {
    try {
      if (data is! Map) return;
      final vibe = data['data']?['vibe'];

      if (vibe is Map && vibe['status'] != null) {
        final status = vibe['status'] as String;
        _statusController.add(status);
      }
    } catch (e) {
      throw TilerError(
          Message: '${LocalizationService.instance.translations.processError}: $e'
      );
    }
  }

  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add('');
        } catch (e) {
          _isConnected = false;
          _attemptReconnect();
          throw TilerError(
              Message: '${LocalizationService.instance.translations.keepAliveFailed}: $e'
          );
        }
      }
    });
  }

  @override
  Future<void> dispose() async {
    _shouldStayConnected = false;
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    _isConnected = false;
    await _statusController.close();
    await _channel?.sink.close();
    super.dispose();
  }
}