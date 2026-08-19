import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_provider.dart';
import '../../core/providers/selection_providers.dart';
import '../../core/rust/actor/model.dart';
import '../../core/rust/bridge.dart';
import '../../i18n/strings.g.dart';
import '../widget/device_widget.dart';

/// File size that never throws (unreadable file, or a preview running
/// without dart:io).
int safeFileSize(String path) {
  try {
    return File(path).lengthSync();
  } catch (_) {
    return 0;
  }
}

/// Send page: review the staged files, pick any number of discovered
/// devices and/or add manual `ip[:port]` targets, then dispatch one
/// send session per target.
class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});

  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage> {
  final Set<String> _selectedTargets = {};
  final List<NodeDevice> _manualTargets = [];
  final TextEditingController _manualController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  String _targetKey(NodeDevice device) => device.fingerprint.isNotEmpty
      ? device.fingerprint
      : '${device.address}:${device.port}';

  Future<void> _addManualTarget() async {
    final input = _manualController.text.trim();
    if (input.isEmpty) {
      return;
    }
    final device = await manualDevice(addr: input);
    if (!mounted) {
      return;
    }
    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.send.invalidAddress)),
      );
      return;
    }
    setState(() {
      if (_manualTargets.every((d) => _targetKey(d) != _targetKey(device))) {
        _manualTargets.add(device);
        _selectedTargets.add(_targetKey(device));
      }
      _manualController.clear();
    });
  }

  Future<void> _confirm(List<String> files, List<NodeDevice> devices) async {
    final targets = [
      for (final device in [...devices, ..._manualTargets])
        if (_selectedTargets.contains(_targetKey(device))) device,
    ];
    if (targets.isEmpty || files.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    final failures =
        await sendFilesToTargets(targets: targets, files: files);
    if (!mounted) {
      return;
    }
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    for (final entry in failures.entries) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t.send.sendFailed(
              alias: entry.key.alias,
              reason: '${entry.value}',
            ),
          ),
        ),
      );
    }
    final sent = targets.length - failures.length;
    if (sent > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t.send.sentToDevices(count: files.length, devices: sent),
          ),
        ),
      );
      ref.read(selectedFilesProvider.notifier).clear();
      Navigator.of(context).pop();
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(selectedFilesProvider);
    final devices =
        ref.watch(devicesProvider).value ?? const <NodeDevice>[];
    final t = context.t;

    return Scaffold(
      appBar: AppBar(title: Text(t.send.title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (files.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(t.send.noFiles)),
            )
          else
            for (final path in files)
              ListTile(
                dense: true,
                leading: const Icon(Icons.file_present),
                title: Text(
                  path.split(Platform.pathSeparator).last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  filesize(safeFileSize(path)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: t.send.removeFile,
                  onPressed: () => ref
                      .read(selectedFilesProvider.notifier)
                      .remove(path),
                ),
              ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              t.send.selectTargets,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final device in devices)
            DeviceWidget(
              device: device,
              selected: _selectedTargets.contains(_targetKey(device)),
              onTap: () {
                setState(() {
                  final key = _targetKey(device);
                  if (!_selectedTargets.add(key)) {
                    _selectedTargets.remove(key);
                  }
                });
              },
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualController,
                  decoration: InputDecoration(
                    labelText: t.send.manualTarget,
                    hintText: t.send.manualTargetHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.url,
                  onSubmitted: (_) => _addManualTarget(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addManualTarget,
                icon: const Icon(Icons.add),
                tooltip: t.send.addTarget,
              ),
            ],
          ),
          for (final device in _manualTargets)
            DeviceWidget(
              device: device,
              selected: _selectedTargets.contains(_targetKey(device)),
              onTap: () {
                setState(() {
                  final key = _targetKey(device);
                  if (!_selectedTargets.add(key)) {
                    _selectedTargets.remove(key);
                  }
                });
              },
              onRemove: () {
                setState(() {
                  _selectedTargets.remove(_targetKey(device));
                  _manualTargets
                      .removeWhere((d) => _targetKey(d) == _targetKey(device));
                });
              },
            ),
          const SizedBox(height: 80),
        ],
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: files.isEmpty || _selectedTargets.isEmpty || _sending
                ? null
                : () => _confirm(files, devices),
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(t.send.confirm(count: _selectedTargets.length)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}
