import 'package:ardrive/turbo/turbo.dart';
import 'package:ardrive/utils/file_size_units.dart';
import 'package:ardrive/utils/logger/logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'topup_estimation_event.dart';
part 'topup_estimation_state.dart';

final presetAmounts = [25, 50, 75, 100];
final supportedCurrencies = ['usd'];

class TurboTopUpEstimationBloc
    extends Bloc<TopupEstimationEvent, TopupEstimationState> {
  final Turbo turbo;

  FileSizeUnit _currentDataUnit = FileSizeUnit.gigabytes;
  String _currentCurrency = 'usd';

  // initialize with 0
  int _currentAmount = 0;

  String get currentCurrency => _currentCurrency;
  int get currentAmount => _currentAmount;
  FileSizeUnit get currentDataUnit => _currentDataUnit;
  late BigInt _balance;

  TurboTopUpEstimationBloc({
    required this.turbo,
  }) : super(EstimationInitial()) {
    on<TopupEstimationEvent>((event, emit) async {
      if (event is LoadInitialData) {
        try {
          logger.i('initializing the estimation view');
          logger.d('getting the balance');
          await _getBalance();

          logger.d('getting the price estimate');
          await _computeAndUpdatePriceEstimate(
            emit,
            currentAmount: 0,
            currentCurrency: currentCurrency,
            currentDataUnit: currentDataUnit,
          );
        } catch (e, s) {
          logger.e('error initializing the estimation view', e, s);

          emit(EstimationError());
        }
      } else if (event is FiatAmountSelected) {
        _currentAmount = event.amount;

        await _computeAndUpdatePriceEstimate(
          emit,
          currentAmount: _currentAmount,
          currentCurrency: currentCurrency,
          currentDataUnit: currentDataUnit,
        );
      } else if (event is CurrencyUnitChanged) {
        _currentCurrency = event.currencyUnit;

        await _computeAndUpdatePriceEstimate(
          emit,
          currentAmount: _currentAmount,
          currentCurrency: currentCurrency,
          currentDataUnit: currentDataUnit,
        );
      } else if (event is DataUnitChanged) {
        _currentDataUnit = event.dataUnit;

        await _computeAndUpdatePriceEstimate(
          emit,
          currentAmount: _currentAmount,
          currentCurrency: currentCurrency,
          currentDataUnit: currentDataUnit,
        );
      } else if (event is AddCreditsClicked) {
        // Handle add credits click here
      }
    });
  }

  Future<void> _computeAndUpdatePriceEstimate(
    Emitter emit, {
    required int currentAmount,
    required String currentCurrency,
    required FileSizeUnit currentDataUnit,
  }) async {
    final priceEstimate = await turbo.computePriceEstimateAndUpdate(
      currentAmount: currentAmount,
      currentCurrency: currentCurrency,
      currentDataUnit: currentDataUnit,
    );

    final estimatedStorageForBalance =
        await turbo.computeStorageEstimateForCredits(
      credits: _balance,
      outputDataUnit: currentDataUnit,
    );

    logger.i('selected amount: ${priceEstimate.priceInCurrency}');
    emit(
      EstimationLoaded(
        balance: _balance,
        estimatedStorageForBalance:
            estimatedStorageForBalance.toStringAsFixed(2),
        selectedAmount: priceEstimate.priceInCurrency,
        creditsForSelectedAmount: priceEstimate.credits,
        estimatedStorageForSelectedAmount:
            priceEstimate.estimatedStorage.toStringAsFixed(2),
        currencyUnit: currentCurrency,
        dataUnit: currentDataUnit,
      ),
    );
  }

  Future<void> _getBalance() async {
    try {
      _balance = await turbo.getBalance();
    } catch (e) {
      logger.e(e);
      _balance = BigInt.zero;
    }
  }
}
