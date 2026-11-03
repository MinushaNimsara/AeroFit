import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/app_update/domain/app_update_status.dart';
import 'package:aerofit/features/app_update/providers/app_update_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

/// Listens for sideload updates and overlays an update card when needed.
/// Uses an in-tree overlay (not [showDialog]) so it works from
/// [MaterialApp.builder] above the navigator.
class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate>
    with WidgetsBindingObserver {
  var _dismissedSoft = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Soft-check caches across process keep-alive; refresh when user returns.
      ref.read(appUpdateFailCountProvider.notifier).state = 0;
      ref.read(appUpdateFailCountProvider.notifier).state = 0;
      ref.read(appUpdateCheckNonceProvider.notifier).state++;
      ref.invalidate(appUpdateStatusProvider);
      if (mounted) setState(() => _dismissedSoft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return widget.child;
    }

    final async = ref.watch(appUpdateStatusProvider);
    final status = async.valueOrNull;
    final show = status != null &&
        status.needsUpdate &&
        status.config != null &&
        !(_dismissedSoft && status.kind == AppUpdateKind.soft);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (show)
          Positioned.fill(
            child: Material(
              color: Colors.black54,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _UpdateCard(
                      status: status,
                      forced: status.kind == AppUpdateKind.forced,
                      onLater: status.kind == AppUpdateKind.forced
                          ? null
                          : () async {
                              final code = status.config!.latestVersionCode;
                              await ref
                                  .read(appUpdatePrefsProvider)
                                  .setSkippedVersionCode(code);
                              if (mounted) {
                                setState(() => _dismissedSoft = true);
                              }
                            },
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UpdateCard extends ConsumerStatefulWidget {
  const _UpdateCard({
    required this.status,
    required this.forced,
    required this.onLater,
  });

  final AppUpdateStatus status;
  final bool forced;
  final Future<void> Function()? onLater;

  @override
  ConsumerState<_UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends ConsumerState<_UpdateCard> {
  var _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _startUpdate() async {
    final config = widget.status.config;
    if (config == null || _downloading) return;

    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final file = await ref.read(appUpdateRepositoryProvider).downloadApk(
            config: config,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );

      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        setState(() {
          _downloading = false;
          _error = result.message.isNotEmpty
              ? result.message
              : 'Could not open the installer. Allow installs from this app in system settings.';
        });
        return;
      }
      if (mounted) setState(() => _downloading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = 'Download failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.status.config!;
    final notes = config.releaseNotes;
    final title = widget.forced ? 'Update required' : 'Update available';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Material(
        color: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardBr,
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Version ${config.latestVersionName.isNotEmpty ? config.latestVersionName : config.latestVersionCode}'
                ' is ready (you have ${widget.status.localVersionName}+${widget.status.localVersionCode}).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  notes,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
              if (_downloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _progress <= 0 ? null : _progress.clamp(0.0, 1.0),
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceHighest,
                  borderRadius: AppRadii.pillBr,
                ),
                const SizedBox(height: 8),
                Text(
                  _progress <= 0
                      ? 'Starting download…'
                      : 'Downloading ${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!widget.forced && !_downloading)
                    TextButton(
                      onPressed: widget.onLater == null
                          ? null
                          : () async {
                              await widget.onLater!();
                            },
                      child: const Text('Later'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _downloading ? null : _startUpdate,
                    child: Text(_downloading ? 'Downloading…' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
