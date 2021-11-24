enum UserMessage {
  connectionFailed,
  parseError,
  verificationFailed,
  missingUserId,
  cantBeEmpty,
  copiedToClipboard,
  redeemFrequencyError,
}

typedef UserErrorHandler = Function(UserMessage error);
