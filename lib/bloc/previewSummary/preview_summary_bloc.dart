import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/previewApi.dart';

part 'preview_summary_event.dart';
part 'preview_summary_state.dart';

class PreviewSummaryBloc
    extends Bloc<PreviewSummaryEvent, PreviewSummaryState> {
  late final PreviewApi previewApi;
  Function getContextCallBack;
  PreviewSummaryBloc({required Function this.getContextCallBack})
      : super(PreviewSummaryInitial()) {
    on<GetPreviewSummaryEvent>(_onGetPreviewSummary);
    previewApi = PreviewApi(getContextCallBack: getContextCallBack);
  }

  Future _onGetPreviewSummary(
      GetPreviewSummaryEvent event, Emitter<PreviewSummaryState> emit) async {
    if (state is PreviewSummaryLoaded) {
      emit(PreviewSummaryLoading(
          (state as PreviewSummaryLoaded).previewSummary));
    } else if (state is PreviewSummaryLoading) {
      emit(PreviewSummaryLoading(
          (state as PreviewSummaryLoading).previewSummary));
    } else {
      emit(PreviewSummaryLoading(null));
    }

    previewApi.getSummary(event.timeline).then((value) {
      emit(PreviewSummaryLoaded(value));
    }).catchError((onError) {
      if (state is PreviewSummaryLoaded) {
        emit(PreviewSummaryFailed(
            (state as PreviewSummaryLoaded).previewSummary));
      } else if (state is PreviewSummaryLoading) {
        emit(PreviewSummaryFailed(
            (state as PreviewSummaryLoading).previewSummary));
      } else {
        emit(PreviewSummaryFailed(null));
      }
    });
  }
}
