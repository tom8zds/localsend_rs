// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Files staged for sending, shared between the home page quick-send,
/// the device list tap-to-send shortcut and the send page.

@ProviderFor(SelectedFiles)
final selectedFilesProvider = SelectedFilesProvider._();

/// Files staged for sending, shared between the home page quick-send,
/// the device list tap-to-send shortcut and the send page.
final class SelectedFilesProvider
    extends $NotifierProvider<SelectedFiles, List<String>> {
  /// Files staged for sending, shared between the home page quick-send,
  /// the device list tap-to-send shortcut and the send page.
  SelectedFilesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedFilesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedFilesHash();

  @$internal
  @override
  SelectedFiles create() => SelectedFiles();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$selectedFilesHash() => r'304d3bdafa90b5b82219e34cc165a3136c9ed82f';

/// Files staged for sending, shared between the home page quick-send,
/// the device list tap-to-send shortcut and the send page.

abstract class _$SelectedFiles extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<String>, List<String>>,
        List<String>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
