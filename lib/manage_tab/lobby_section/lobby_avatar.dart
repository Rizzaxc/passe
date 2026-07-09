import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Square lobby avatar: shows the uploaded photo from the `lobby_avatar`
/// storage bucket (`<lobbyId>.jpg`) when [hasAvatar] is true, otherwise
/// falls back to a deterministic letter square in [backgroundColor] /
/// [foregroundColor]. Also falls back on a failed image load (e.g. a
/// stale [hasAvatar] flag racing an in-flight delete).
class LobbyAvatar extends StatefulWidget {
  final String? lobbyId;
  final String name;
  final bool hasAvatar;
  final double size;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color foregroundColor;

  const LobbyAvatar({
    super.key,
    required this.lobbyId,
    required this.name,
    required this.hasAvatar,
    required this.size,
    required this.borderRadius,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  State<LobbyAvatar> createState() => _LobbyAvatarState();
}

class _LobbyAvatarState extends State<LobbyAvatar> {
  bool _loadFailed = false;

  @override
  void didUpdateWidget(covariant LobbyAvatar old) {
    super.didUpdateWidget(old);
    if (old.lobbyId != widget.lobbyId || old.hasAvatar != widget.hasAvatar) {
      _loadFailed = false;
    }
  }

  Widget _fallback() {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: widget.size * 0.45,
          fontWeight: FontWeight.w700,
          color: widget.foregroundColor,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasAvatar || widget.lobbyId == null || _loadFailed) {
      return _fallback();
    }

    final url = Supabase.instance.client.storage
        .from('lobby_avatar')
        .getPublicUrl('${widget.lobbyId}.jpg');
    final cacheBusted = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Image.network(
        cacheBusted,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loadFailed) setState(() => _loadFailed = true);
          });
          return _fallback();
        },
      ),
    );
  }
}
