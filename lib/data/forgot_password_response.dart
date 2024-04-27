class ForgotPasswordResponse {
  final ErrorResponse error;
  final dynamic content;

  ForgotPasswordResponse({required this.error, this.content});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      error: ErrorResponse.fromJson(json['Error']),
      content: json['Content'],
    );
  }
}

class ErrorResponse {
  final String code;
  final String message;

  ErrorResponse({required this.code, required this.message});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      code: json['Code'],
      message: json['Message'],
    );
  }
}
