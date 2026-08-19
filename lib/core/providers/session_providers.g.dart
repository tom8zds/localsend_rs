// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Low-frequency full snapshot of all transfer sessions (both
/// directions). Widgets must watch this instead of touching the Rust
/// stream directly.

@ProviderFor(sessionIndex)
final sessionIndexProvider = SessionIndexProvider._();

/// Low-frequency full snapshot of all transfer sessions (both
/// directions). Widgets must watch this instead of touching the Rust
/// stream directly.

final class SessionIndexProvider extends $FunctionalProvider<
        AsyncValue<List<SessionSummary>>,
        List<SessionSummary>,
        Stream<List<SessionSummary>>>
    with
        $FutureModifier<List<SessionSummary>>,
        $StreamProvider<List<SessionSummary>> {
  /// Low-frequency full snapshot of all transfer sessions (both
  /// directions). Widgets must watch this instead of touching the Rust
  /// stream directly.
  SessionIndexProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sessionIndexProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sessionIndexHash();

  @$internal
  @override
  $StreamProviderElement<List<SessionSummary>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<SessionSummary>> create(Ref ref) {
    return sessionIndex(ref);
  }
}

String _$sessionIndexHash() => r'bbdd6d7c62782c11e1d4c115ecfaa9f9c296da72';

/// Per-session event stream (state changes, per-file states, byte
/// progress, failures).

@ProviderFor(sessionEvent)
final sessionEventProvider = SessionEventFamily._();

/// Per-session event stream (state changes, per-file states, byte
/// progress, failures).

final class SessionEventProvider extends $FunctionalProvider<
        AsyncValue<SessionEvent>, SessionEvent, Stream<SessionEvent>>
    with $FutureModifier<SessionEvent>, $StreamProvider<SessionEvent> {
  /// Per-session event stream (state changes, per-file states, byte
  /// progress, failures).
  SessionEventProvider._(
      {required SessionEventFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'sessionEventProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sessionEventHash();

  @override
  String toString() {
    return r'sessionEventProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SessionEvent> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<SessionEvent> create(Ref ref) {
    final argument = this.argument as String;
    return sessionEvent(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionEventProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionEventHash() => r'fb57ffae385d230edf61d4db237f0e50f64404e4';

/// Per-session event stream (state changes, per-file states, byte
/// progress, failures).

final class SessionEventFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SessionEvent>, String> {
  SessionEventFamily._()
      : super(
          retry: null,
          name: r'sessionEventProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Per-session event stream (state changes, per-file states, byte
  /// progress, failures).

  SessionEventProvider call(
    String sessionId,
  ) =>
      SessionEventProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionEventProvider';
}

/// Receive sessions waiting for the user's decision.

@ProviderFor(pendingReceiveSessions)
final pendingReceiveSessionsProvider = PendingReceiveSessionsProvider._();

/// Receive sessions waiting for the user's decision.

final class PendingReceiveSessionsProvider extends $FunctionalProvider<
    List<SessionSummary>,
    List<SessionSummary>,
    List<SessionSummary>> with $Provider<List<SessionSummary>> {
  /// Receive sessions waiting for the user's decision.
  PendingReceiveSessionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pendingReceiveSessionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pendingReceiveSessionsHash();

  @$internal
  @override
  $ProviderElement<List<SessionSummary>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<SessionSummary> create(Ref ref) {
    return pendingReceiveSessions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SessionSummary> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SessionSummary>>(value),
    );
  }
}

String _$pendingReceiveSessionsHash() =>
    r'4ee9879561cc2954cb0795389b889a7e8ff42e35';

/// Accumulates [`SessionExtras`] from the per-session event stream.

@ProviderFor(SessionExtrasNotifier)
final sessionExtrasProvider = SessionExtrasNotifierFamily._();

/// Accumulates [`SessionExtras`] from the per-session event stream.
final class SessionExtrasNotifierProvider
    extends $NotifierProvider<SessionExtrasNotifier, SessionExtras> {
  /// Accumulates [`SessionExtras`] from the per-session event stream.
  SessionExtrasNotifierProvider._(
      {required SessionExtrasNotifierFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'sessionExtrasProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sessionExtrasNotifierHash();

  @override
  String toString() {
    return r'sessionExtrasProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionExtrasNotifier create() => SessionExtrasNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionExtras value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionExtras>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionExtrasNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionExtrasNotifierHash() =>
    r'dd4600a8d1df8787cbbebf8d7a98f8753d59fd78';

/// Accumulates [`SessionExtras`] from the per-session event stream.

final class SessionExtrasNotifierFamily extends $Family
    with
        $ClassFamilyOverride<SessionExtrasNotifier, SessionExtras,
            SessionExtras, SessionExtras, String> {
  SessionExtrasNotifierFamily._()
      : super(
          retry: null,
          name: r'sessionExtrasProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Accumulates [`SessionExtras`] from the per-session event stream.

  SessionExtrasNotifierProvider call(
    String sessionId,
  ) =>
      SessionExtrasNotifierProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionExtrasProvider';
}

/// Accumulates [`SessionExtras`] from the per-session event stream.

abstract class _$SessionExtrasNotifier extends $Notifier<SessionExtras> {
  late final _$args = ref.$arg as String;
  String get sessionId => _$args;

  SessionExtras build(
    String sessionId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SessionExtras, SessionExtras>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SessionExtras, SessionExtras>,
        SessionExtras,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

/// Persisted quick-save toggle: accept incoming sessions without
/// confirmation.

@ProviderFor(QuickSave)
final quickSaveProvider = QuickSaveProvider._();

/// Persisted quick-save toggle: accept incoming sessions without
/// confirmation.
final class QuickSaveProvider extends $NotifierProvider<QuickSave, bool> {
  /// Persisted quick-save toggle: accept incoming sessions without
  /// confirmation.
  QuickSaveProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'quickSaveProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$quickSaveHash();

  @$internal
  @override
  QuickSave create() => QuickSave();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$quickSaveHash() => r'b253b15c49a975b773bc7d26014f69cf47822a60';

/// Persisted quick-save toggle: accept incoming sessions without
/// confirmation.

abstract class _$QuickSave extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

/// Accepts pending receive sessions automatically while quick save is
/// enabled. Watched once by the app frame; the state is the set of
/// session ids already acted on.

@ProviderFor(AutoAccept)
final autoAcceptProvider = AutoAcceptProvider._();

/// Accepts pending receive sessions automatically while quick save is
/// enabled. Watched once by the app frame; the state is the set of
/// session ids already acted on.
final class AutoAcceptProvider
    extends $NotifierProvider<AutoAccept, Set<String>> {
  /// Accepts pending receive sessions automatically while quick save is
  /// enabled. Watched once by the app frame; the state is the set of
  /// session ids already acted on.
  AutoAcceptProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'autoAcceptProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$autoAcceptHash();

  @$internal
  @override
  AutoAccept create() => AutoAccept();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$autoAcceptHash() => r'ac28b0ef3b449d469685157a9c9d851977b24cdf';

/// Accepts pending receive sessions automatically while quick save is
/// enabled. Watched once by the app frame; the state is the set of
/// session ids already acted on.

abstract class _$AutoAccept extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<Set<String>, Set<String>>, Set<String>, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
