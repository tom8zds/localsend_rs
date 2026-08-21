import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../common/spacing.dart';
import '../../i18n/strings.g.dart';

/// Full-screen QR scanner for relay invites. Pops with the scanned
/// payload text (a deep link or a bare `addr|secret` line); the
/// caller runs it through `RelayInvite.parse`.
class RelayScanPage extends StatefulWidget {
  const RelayScanPage({super.key});

  @override
  State<RelayScanPage> createState() => _RelayScanPageState();
}

class _RelayScanPageState extends State<RelayScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _done = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.setting.relay.scanTitle)),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        // Permission-denied and other camera failures surface as a
        // readable line instead of the default bare error icon.
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x24),
            child: Text(
              error.errorDetails?.message ?? context.t.setting.relay.scanError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
