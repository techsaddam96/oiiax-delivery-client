import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:blockatie/services/order_services.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/chat/conversation_page.dart';
import 'package:flutter/material.dart';

/// Shared navigation only; authorization and get/create remain in the chat API.
class ShipmentChatNavigation extends UserScopedNotifier {
  ShipmentChatNavigation({
    ChatRepository? repository,
    Future<OrderDetailsResponse?> Function(int)? detailsLoader,
  })  : _repository = repository ?? ChatService(),
        _detailsLoader = detailsLoader ??
            ((id) => OrderServices.getOrderDetails(orderId: id));

  final ChatRepository _repository;
  final Future<OrderDetailsResponse?> Function(int) _detailsLoader;
  int? _openingShipmentId;
  int _operation = 0;
  bool get isOpening => _openingShipmentId != null;
  int? get openingShipmentId => _openingShipmentId;

  @override
  void clearUserState() {
    _operation++;
    _openingShipmentId = null;
  }

  Future<void> open(
    BuildContext context, {
    required int shipmentId,
    OrderDetailsData? details,
    required bool Function() isCurrent,
  }) async {
    if (isOpening || shipmentId <= 0 || !isCurrent()) return;
    final epoch = stateGeneration;
    final operation = ++_operation;
    final route = ModalRoute.of(context);
    bool current() =>
        acceptsState(epoch) &&
        operation == _operation &&
        context.mounted &&
        isCurrent() &&
        (route == null || route.isCurrent);

    // Keep the guard active through navigation, not just the get/create request.
    _openingShipmentId = shipmentId;
    notifyListeners();
    try {
      var authoritativeDetails = details;
      if (authoritativeDetails == null) {
        final response = await _detailsLoader(shipmentId);
        if (!current()) return;
        if (response?.success != true) throw const FormatException();
        authoritativeDetails = response!.data;
      }
      if (authoritativeDetails.orderId != shipmentId) {
        throw const FormatException();
      }
      // Shipment ownership is verified server-side using the current API key.
      final result = await _repository.getOrCreateShipmentConversation(
        shipmentId: authoritativeDetails.orderId,
      );
      // Never navigate using a response from a previous account or shipment.
      if (!current()) return;
      final conversation = result.conversation;
      final currentDetails = authoritativeDetails;
      if (conversation.conversationId <= 0 ||
          conversation.shipmentId != authoritativeDetails.orderId ||
          conversation.conversationType != 'shipment_client') {
        throw const FormatException();
      }
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(MaterialPageRoute<void>(
        builder: (_) => ConversationPage(
          conversationId: conversation.conversationId,
          title: conversation.title.isNotEmpty
              ? conversation.title
              : AppTranslations.getText('chat_support_message'),
          shipmentId: currentDetails.orderId,
          policyNum:
              conversation.policyNum ?? currentDetails.details.policyNumber,
          repository: _repository,
        ),
      ));
    } catch (_) {
      if (context.mounted && current()) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppTranslations.getText('chat_open_shipment_failed')),
        ));
      }
    } finally {
      if (acceptsState(epoch) && operation == _operation) {
        _openingShipmentId = null;
        notifyListeners();
      }
    }
  }
}
