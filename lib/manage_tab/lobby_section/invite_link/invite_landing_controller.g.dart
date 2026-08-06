// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_landing_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inviteLinkPreview)
final inviteLinkPreviewProvider = InviteLinkPreviewFamily._();

final class InviteLinkPreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<InvitePreview>,
          InvitePreview,
          FutureOr<InvitePreview>
        >
    with $FutureModifier<InvitePreview>, $FutureProvider<InvitePreview> {
  InviteLinkPreviewProvider._({
    required InviteLinkPreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inviteLinkPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteLinkPreviewHash();

  @override
  String toString() {
    return r'inviteLinkPreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InvitePreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InvitePreview> create(Ref ref) {
    final argument = this.argument as String;
    return inviteLinkPreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InviteLinkPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteLinkPreviewHash() => r'8e7662203096000897882d605d2bc6ecedb16222';

final class InviteLinkPreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InvitePreview>, String> {
  InviteLinkPreviewFamily._()
    : super(
        retry: null,
        name: r'inviteLinkPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InviteLinkPreviewProvider call(String code) =>
      InviteLinkPreviewProvider._(argument: code, from: this);

  @override
  String toString() => r'inviteLinkPreviewProvider';
}
