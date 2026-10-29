import 'dart:async';
import 'package:blockatie/services/client_statement_service.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:flutter/material.dart';

/// The credential exists only in this screen's memory, never in a model/cache.
class HandoverCodeCard extends StatefulWidget {
  const HandoverCodeCard(
      {super.key, required this.statementId, required this.ar, this.service});
  final int statementId;
  final bool ar;
  final ClientStatementService? service;
  @override
  State<HandoverCodeCard> createState() => _HandoverCodeCardState();
}

class _HandoverCodeCardState extends State<HandoverCodeCard>
    with WidgetsBindingObserver {
  String? _code;
  bool _busy = false;
  bool _error = false;
  int _request = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UserSessionState.register(_hide);
  }

  void _hide() {
    _request++;
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _code = null;
        _busy = false;
        _error = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant HandoverCodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statementId != widget.statementId) _hide();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _hide();
  }

  @override
  void dispose() {
    _request++;
    _timer?.cancel();
    _code = null;
    UserSessionState.unregister(_hide);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _reveal() async {
    if (_busy) return;
    final request = ++_request;
    final generation = UserSessionState.generation;
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      final code = await (widget.service ?? ClientStatementService())
          .revealHandoverCode(widget.statementId);
      if (!mounted ||
          request != _request ||
          generation != UserSessionState.generation) return;
      setState(() {
        _code = code;
      });
      _timer = Timer(const Duration(seconds: 60), _hide);
    } catch (_) {
      if (mounted &&
          request == _request &&
          generation == UserSessionState.generation) {
        setState(() {
          _error = true;
        });
      }
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to route changes: a covered screen must forget the credential.
    if (ModalRoute.isCurrentOf(context) == false) {
      _request++;
      _timer?.cancel();
      _code = null;
      _busy = false;
      _error = false;
    }
    return Card(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(widget.ar
              ? 'لا تشارك الرمز إلا بعد استلام المبلغ النقدي المتبقي كاملًا.'
              : 'Share this code only after receiving the full remaining cash amount.'),
          if (_code != null)
            Text(_code!,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 28, letterSpacing: 8)),
          if (_error)
            Text(widget.ar
                ? 'تعذر عرض الرمز. حدّث الكشف وحاول مجددًا.'
                : 'Unable to reveal the code. Refresh the statement and retry.'),
          OutlinedButton.icon(
              onPressed: _busy ? null : (_code == null ? _reveal : _hide),
              icon: Icon(_code == null
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              label: Text(_code == null
                  ? (widget.ar ? 'عرض رمز التسليم' : 'Show Handover Code')
                  : (widget.ar ? 'إخفاء الرمز' : 'Hide code'))),
        ]),
      ));
  }
}
