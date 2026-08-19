// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoreState)
final coreStateProvider = CoreStateProvider._();

final class CoreStateProvider
    extends $NotifierProvider<CoreState, RustCoreState> {
  CoreStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'coreStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$coreStateHash();

  @$internal
  @override
  CoreState create() => CoreState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RustCoreState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RustCoreState>(value),
    );
  }
}

String _$coreStateHash() => r'2a21926ad86879088cb49e04efbc32590a05746f';

abstract class _$CoreState extends $Notifier<RustCoreState> {
  RustCoreState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RustCoreState, RustCoreState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<RustCoreState, RustCoreState>,
        RustCoreState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
