import 'package:ardrive/pst/contract_oracle.dart';
import 'package:ardrive/pst/pst_contract_data.dart';
import 'package:equatable/equatable.dart';
import 'package:retry/retry.dart';

const _maxReadContractAttempts = 3;

class ArDriveContractOracle implements ContractOracle {
  final List<ContractOracle> _contractOracles;

  ArDriveContractOracle(List<ContractOracle> contractOracles)
      : _contractOracles = contractOracles {
    if (contractOracles.isEmpty) {
      throw const EmptyContractOracles();
    }
  }

  @override
  Future<CommunityContractData> getCommunityContract() async {
    CommunityContractData? data = await _getContractFromOracles();

    if (data == null) {
      throw const CouldNotReadContractState(
        reason: 'Max retry attempts reached',
      );
    }

    return data;
  }

  /// iterates over all contract readers attempting to read the contract
  Future<CommunityContractData?> _getContractFromOracles() async {
    for (ContractOracle contractOracle in _contractOracles) {
      final data = await _getContractWithRetries(contractOracle);
      if (data != null) {
        return data;
      }
    }
    return null;
  }

  /// attempts multiple retries to read the given contract oracle
  Future<CommunityContractData?> _getContractWithRetries(
    ContractOracle contractOracle, {
    int maxAttempts = _maxReadContractAttempts,
  }) async {
    try {
      final data = await retry(
        contractOracle.getCommunityContract,
        maxAttempts: maxAttempts,
      );
      return data;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CommunityTipPercentage> getTipPercentageFromContract() async {
    final contractState = await getCommunityContract();
    return contractState.settings.fee / 100;
  }
}

class EmptyContractOracles extends Equatable implements Exception {
  const EmptyContractOracles();

  @override
  String toString() {
    return 'Expected at least one contract reader';
  }

  @override
  List<Object?> get props => [];
}

class CouldNotReadContractState extends Equatable implements Exception {
  final String _errMessage = 'Could not read contract state';
  final String? _reason;

  const CouldNotReadContractState({String? reason}) : _reason = reason;

  @override
  String toString() {
    return _reason != null ? '$_errMessage. $_reason' : _errMessage;
  }

  @override
  List<Object?> get props => [_reason];
}
