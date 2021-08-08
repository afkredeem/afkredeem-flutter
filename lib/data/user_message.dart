enum UserMessage {
  connectionFailed,
  parseError,
  verificationFailed,
  missingUserId,
  cantBeEmpty,
  copiedToClipboard,
}

typedef UserErrorHandler = Function(UserMessage error);
