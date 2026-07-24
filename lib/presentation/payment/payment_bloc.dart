import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

// --- EVENTS ---
abstract class PaymentEvent {}

class FetchTiersRequested extends PaymentEvent {}

class CreateOrderRequested extends PaymentEvent {
  final String tierId;
  CreateOrderRequested({required this.tierId});
}

class StartOrderStatusPolling extends PaymentEvent {
  final String orderId;
  StartOrderStatusPolling({required this.orderId});
}

class PollStatusTicked extends PaymentEvent {}

class StopOrderStatusPolling extends PaymentEvent {}

class FetchHistoryRequested extends PaymentEvent {
  final int page;
  final int size;
  FetchHistoryRequested({this.page = 0, this.size = 10});
}

class CancelOrderRequested extends PaymentEvent {
  final String orderId;
  CancelOrderRequested({required this.orderId});
}

// --- STATE ---
class PaymentState {
  final List<Tier> tiers;
  final bool isTiersLoading;
  
  final CreateOrderResponse? activeOrder;
  final bool isOrdering;
  
  final OrderStatusResponse? polledStatus;
  final List<OrderHistoryItem> orderHistory;
  final bool isHistoryLoading;
  final String? error;

  PaymentState({
    this.tiers = const [],
    this.isTiersLoading = false,
    this.activeOrder,
    this.isOrdering = false,
    this.polledStatus,
    this.orderHistory = const [],
    this.isHistoryLoading = false,
    this.error,
  });

  PaymentState copyWith({
    List<Tier>? tiers,
    bool? isTiersLoading,
    CreateOrderResponse? activeOrder,
    bool? isOrdering,
    OrderStatusResponse? polledStatus,
    List<OrderHistoryItem>? orderHistory,
    bool? isHistoryLoading,
    String? error,
  }) {
    return PaymentState(
      tiers: tiers ?? this.tiers,
      isTiersLoading: isTiersLoading ?? this.isTiersLoading,
      activeOrder: activeOrder ?? this.activeOrder, // Allow clearing activeOrder by setting it to null
      isOrdering: isOrdering ?? this.isOrdering,
      polledStatus: polledStatus ?? this.polledStatus,
      orderHistory: orderHistory ?? this.orderHistory,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      error: error,
    );
  }
}

// --- BLOC ---
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;
  Timer? _pollingTimer;
  String? _currentPollingOrderId;

  PaymentBloc({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository,
        super(PaymentState()) {
    on<FetchTiersRequested>(_onFetchTiersRequested);
    on<CreateOrderRequested>(_onCreateOrderRequested);
    on<StartOrderStatusPolling>(_onStartOrderStatusPolling);
    on<PollStatusTicked>(_onPollStatusTicked);
    on<StopOrderStatusPolling>(_onStopOrderStatusPolling);
    on<FetchHistoryRequested>(_onFetchHistoryRequested);
    on<CancelOrderRequested>(_onCancelOrderRequested);
  }

  Future<void> _onFetchTiersRequested(
      FetchTiersRequested event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(isTiersLoading: true));
    try {
      final tiers = await _paymentRepository.getTiers();
      emit(state.copyWith(tiers: tiers, isTiersLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isTiersLoading: false));
    }
  }

  Future<void> _onCreateOrderRequested(
      CreateOrderRequested event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(isOrdering: true, error: null));
    try {
      final orderResponse = await _paymentRepository.createOrder(event.tierId);
      emit(state.copyWith(activeOrder: orderResponse, isOrdering: false));

      // Try launching the checkout URL in an external browser
      final uri = Uri.parse(orderResponse.checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // Automatically start polling for this order
      add(StartOrderStatusPolling(orderId: orderResponse.orderId));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isOrdering: false));
    }
  }

  void _onStartOrderStatusPolling(
      StartOrderStatusPolling event, Emitter<PaymentState> emit) {
    _pollingTimer?.cancel();
    _currentPollingOrderId = event.orderId;
    
    // Poll every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      add(PollStatusTicked());
    });
  }

  Future<void> _onPollStatusTicked(
      PollStatusTicked event, Emitter<PaymentState> emit) async {
    if (_currentPollingOrderId == null) {
      _pollingTimer?.cancel();
      return;
    }

    try {
      final status = await _paymentRepository.getOrderStatus(_currentPollingOrderId!);
      emit(state.copyWith(polledStatus: status));

      // Stop polling if the status is no longer pending
      if (status.status != OrderStatus.pending) {
        _pollingTimer?.cancel();
        _currentPollingOrderId = null;
        emit(state.copyWith(activeOrder: null)); // Clear active order checkout display
      }
    } catch (e) {
      // In case of error, continue polling, but maybe store error logs
    }
  }

  void _onStopOrderStatusPolling(
      StopOrderStatusPolling event, Emitter<PaymentState> emit) {
    _pollingTimer?.cancel();
    _currentPollingOrderId = null;
    emit(state.copyWith(polledStatus: null, activeOrder: null));
  }

  Future<void> _onFetchHistoryRequested(
      FetchHistoryRequested event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(isHistoryLoading: true));
    try {
      final history = await _paymentRepository.getMyOrders(page: event.page, size: event.size);
      emit(state.copyWith(orderHistory: history, isHistoryLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isHistoryLoading: false));
    }
  }

  Future<void> _onCancelOrderRequested(
      CancelOrderRequested event, Emitter<PaymentState> emit) async {
    try {
      await _paymentRepository.cancelOrder(event.orderId);
      _pollingTimer?.cancel();
      _currentPollingOrderId = null;
      emit(state.copyWith(activeOrder: null, polledStatus: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
