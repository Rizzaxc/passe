import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../router.dart';
import '../../../ui/main.dart';

/// Pulls an invite code out of whatever the user pasted: a full
/// `https://passe.vn/invite/CODE` link (with or without scheme, `www.`, a
/// trailing slash or query), or the bare code. Returns null when nothing
/// code-shaped is left.
///
/// This is the manual stand-in for a deferred deep link: someone who installs
/// from the store after tapping an invite lands on a fresh app with the link
/// lost, so they paste it here instead.
String? parseInviteCode(String input) {
  var raw = input.trim();
  if (raw.isEmpty) return null;

  final marker = raw.toLowerCase().indexOf('/invite/');
  if (marker >= 0) {
    raw = raw.substring(marker + '/invite/'.length);
  } else if (raw.contains(RegExp(r'[/.\s]'))) {
    // Some other URL, or a sentence — a bare code is one token.
    return null;
  }
  raw = raw.split(RegExp(r'[/?#\s]')).first;

  // Codes are URL-safe ids (nanoid alphabet); anything else is a typo or
  // a stray paste.
  if (!RegExp(r'^[A-Za-z0-9_-]{4,64}$').hasMatch(raw)) return null;
  return raw;
}

/// "Nhập mã mời" — paste an invite link or code, then hand off to the same
/// `/invite/:code` landing page a tapped link opens (preview + join).
Future<void> showRedeemInviteCodeSheet(BuildContext context) async {
  final code = await pickInviteCode(context);
  if (code == null || !context.mounted) return;
  // Push-only: InviteRoute sits outside the shell (see its doc comment).
  InviteRoute(code: code).push(context);
}

/// Just the sheet: resolves to a parsed code, or null if dismissed. For
/// callers that need to close something of their own before navigating.
Future<String?> pickInviteCode(BuildContext context) => showPSheet<String>(
  context: context,
  builder: (_) => const _RedeemInviteCodeSheet(),
);

class _RedeemInviteCodeSheet extends StatefulWidget {
  const _RedeemInviteCodeSheet();

  @override
  State<_RedeemInviteCodeSheet> createState() => _RedeemInviteCodeSheetState();
}

class _RedeemInviteCodeSheetState extends State<_RedeemInviteCodeSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = parseInviteCode(_controller.text);
    if (code == null) {
      setState(() => _error = 'lobby.inviteLink.redeemInvalid'.tr());
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: 'lobby.inviteLink.redeemTitle'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Text(
            'lobby.inviteLink.redeemBody'.tr(),
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          FTextField(
            hint: 'lobby.inviteLink.redeemHint'.tr(),
            autofocus: true,
            autocorrect: false,
            textInputAction: TextInputAction.go,
            onSubmit: (_) => _submit(),
            error: _error == null ? null : Text(_error!),
            control: FTextFieldControl.managed(
              controller: _controller,
              onChange: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ),
          FButton(
            onPress: _submit,
            child: Text('lobby.inviteLink.redeemContinue'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
