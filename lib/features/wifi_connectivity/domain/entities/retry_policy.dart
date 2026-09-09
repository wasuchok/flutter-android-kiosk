enum RetryMode {
  untilConnected,
  maxDuration,
}

class RetryPolicy {
  final RetryMode mode;
  final Duration? maxDuration;

  const RetryPolicy.untilConnected()
      : mode = RetryMode.untilConnected,
        maxDuration = null;

  const RetryPolicy.maxDuration(Duration duration)
      : mode = RetryMode.maxDuration,
        maxDuration = duration;
}
