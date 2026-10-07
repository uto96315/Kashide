import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics のイベント名・パラメータを一元管理する。
class AppAnalytics {
  AppAnalytics({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  static const postComposeOpen = 'post_compose_open';
  static const postSubmitAttempt = 'post_submit_attempt';
  static const postSubmitSuccess = 'post_submit_success';
  static const postSubmitFailure = 'post_submit_failure';
  static const postSubmitValidationFailed = 'post_submit_validation_failed';

  Future<void> logPostComposeOpen({required String source}) async {
    await _log(postComposeOpen, {'source': _clip(source)});
  }

  Future<void> logPostSubmitAttempt({required String source}) async {
    await _log(postSubmitAttempt, {'source': _clip(source)});
  }

  Future<void> logPostSubmitSuccess({required String source}) async {
    await _log(postSubmitSuccess, {'source': _clip(source)});
  }

  Future<void> logPostSubmitFailure({required String source, String? reason}) async {
    await _log(postSubmitFailure, {
      'source': _clip(source),
      if (reason != null && reason.isNotEmpty) 'reason': _clip(reason, max: 100),
    });
  }

  Future<void> logPostSubmitValidationFailed({required String source}) async {
    await _log(postSubmitValidationFailed, {'source': _clip(source)});
  }

  Future<void> _log(String name, Map<String, Object> params) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e, st) {
      debugPrint('Analytics logEvent failed ($name): $e\n$st');
    }
  }

  String _clip(String value, {int max = 40}) {
    if (value.length <= max) return value;
    return value.substring(0, max);
  }
}
