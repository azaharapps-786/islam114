import 'package:equatable/equatable.dart';

abstract class QiblaEvent extends Equatable {
  const QiblaEvent();

  @override
  List<Object?> get props => [];
}

class QiblaDirectionRequested extends QiblaEvent {
  const QiblaDirectionRequested();
}