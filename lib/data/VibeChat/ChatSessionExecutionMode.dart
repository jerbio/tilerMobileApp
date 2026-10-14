enum ChatSessionExecutionMode {
  confirmFirst('ConfirmFirst'),
  autoAct('AutoAct');

  final String wireValue;
  const ChatSessionExecutionMode(this.wireValue);
}
