import 'package:equatable/equatable.dart';

abstract class QiblaState extends Equatable {
  const QiblaState();

  @override
  List<Object?> get props => [];
}

class QiblaInitial extends QiblaState {
  const QiblaInitial();
}

class QiblaLoading extends QiblaState {
  const QiblaLoading();
}

class QiblaLocationPermissionDenied extends QiblaState {
  final String message;

  const QiblaLocationPermissionDenied(this.message);

  @override
  List<Object?> get props => [message];
}

class QiblaLocationServiceDisabled extends QiblaState {
  final String message;

  const QiblaLocationServiceDisabled(this.message);

  @override
  List<Object?> get props => [message];
}

class QiblaSensorError extends QiblaState {
  final String message;

  const QiblaSensorError(this.message);

  @override
  List<Object?> get props => [message];
}

class QiblaLoadSuccess extends QiblaState {
  final double relativeQiblaDirection;
  final double currentHeading;
  final double distanceToKaaba;
  final String accuracyStatus;

  const QiblaLoadSuccess({
    required this.relativeQiblaDirection,
    required this.currentHeading,
    required this.distanceToKaaba,
    required this.accuracyStatus,
  });

  @override
  List<Object?> get props => [relativeQiblaDirection, currentHeading, distanceToKaaba, accuracyStatus];
}