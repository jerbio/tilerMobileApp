part of 'preview_summary_bloc.dart';

sealed class PreviewSummaryState extends Equatable {
  const PreviewSummaryState();

  @override
  List<Object> get props => [];
}

final class PreviewSummaryInitial extends PreviewSummaryState {}

final class PreviewSummaryLoading extends PreviewSummaryState {
  final PreviewSummary? previewSummary;
  PreviewSummaryLoading(this.previewSummary);
}

final class PreviewSummaryLoaded extends PreviewSummaryState {
  final PreviewSummary previewSummary;
  PreviewSummaryLoaded(this.previewSummary);
}

final class PreviewSummaryFailed extends PreviewSummaryState {
  final PreviewSummary? previewSummary;
  PreviewSummaryFailed(this.previewSummary);
}
