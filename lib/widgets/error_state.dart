import 'package:flutter/material.dart';

/// Friendly replacement for showing a raw exception to the user (#57).
///
/// Shows [message] (e.g. "Couldn't load your birds") with an optional Retry.
/// The underlying [error] is logged and kept behind a "Details" toggle so it
/// can still be copied into a support email without being the first thing
/// people see.
///
/// Use [ErrorState.compact] inline (inside forms, sheets, dropdown slots)
/// where a centred block would be too big.
class ErrorState extends StatefulWidget {
  final String message;
  final Object? error;
  final VoidCallback? onRetry;
  final bool compact;

  const ErrorState({
    super.key,
    required this.message,
    this.error,
    this.onRetry,
  }) : compact = false;

  const ErrorState.compact({
    super.key,
    required this.message,
    this.error,
    this.onRetry,
  }) : compact = true;

  @override
  State<ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends State<ErrorState> {
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _log();
  }

  @override
  void didUpdateWidget(ErrorState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.error?.toString() != widget.error?.toString()) _log();
  }

  void _log() {
    if (widget.error != null) {
      debugPrint('${widget.message}: ${widget.error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact ? _buildCompact(context) : _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.error_outline, size: 20, color: scheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        if (widget.onRetry != null)
          TextButton(onPressed: widget.onRetry, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildFull(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = widget.error?.toString();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.onRetry != null
                  ? 'Please try again. If it keeps happening, let us know.'
                  : 'If it keeps happening, let us know.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: widget.onRetry,
                child: const Text('Retry'),
              ),
            ],
            if (details != null && details.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _showDetails = !_showDetails),
                child: Text(_showDetails ? 'Hide details' : 'Details'),
              ),
              if (_showDetails)
                SelectableText(
                  details,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
