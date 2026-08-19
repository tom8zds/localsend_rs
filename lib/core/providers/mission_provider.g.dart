// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoreMission)
final coreMissionProvider = CoreMissionProvider._();

final class CoreMissionProvider
    extends $NotifierProvider<CoreMission, MissionInfo?> {
  CoreMissionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'coreMissionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$coreMissionHash();

  @$internal
  @override
  CoreMission create() => CoreMission();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MissionInfo? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MissionInfo?>(value),
    );
  }
}

String _$coreMissionHash() => r'11026c14485ff442423627f646ecc515cb310c43';

abstract class _$CoreMission extends $Notifier<MissionInfo?> {
  MissionInfo? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MissionInfo?, MissionInfo?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<MissionInfo?, MissionInfo?>,
        MissionInfo?,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
