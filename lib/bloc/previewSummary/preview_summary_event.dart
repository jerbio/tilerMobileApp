part of 'preview_summary_bloc.dart';

sealed class PreviewSummaryEvent extends Equatable {
  const PreviewSummaryEvent();

  @override
  List<Object> get props => [];
}

class GetPreviewSummaryEvent extends Equatable {
  final Timeline timeline;
  const GetPreviewSummaryEvent({required this.timeline});

  @override
  List<Object> get props => [timeline];
}

class PreviewSummaryLoadingEvent extends Equatable {
  final PreviewSummary? previewSummary;
  const PreviewSummaryLoadingEvent({required this.previewSummary});

  @override
  List<Object> get props => [previewSummary ?? PreviewSummary.fromJson({})];
}

class PreviewSummaryLoadedEvent extends Equatable {
  final PreviewSummary? previewSummary;
  const PreviewSummaryLoadedEvent({required this.previewSummary});

  @override
  List<Object> get props => [previewSummary ?? PreviewSummary.fromJson({})];
}
