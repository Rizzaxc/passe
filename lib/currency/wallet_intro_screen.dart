import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'da_icon.dart';
import 'wallet_shared.dart';

class WalletIntroScreen extends StatelessWidget {
  const WalletIntroScreen({super.key});

  static const _crimson = Color(0xFFDC143C);
  static const _green = Color(0xFF959D54);
  static const _blue = Color(0xFF3090F2);

  static final _uses = <_UseCase>[
    _UseCase(
      icon: FLucideIcons.check,
      color: _crimson,
      tintBuilder: (c) => c.crimsonTint,
      title: 'Xác nhận buổi chơi',
      copy:
          'Đặt cọc 10 Đá khi nhận lời mời. Đến chơi xác nhận thì được hoàn lại — bùng kèo thì mất cọc.',
      cost: '10 Đá / cọc',
    ),
    _UseCase(
      icon: FLucideIcons.mapPin,
      color: _blue,
      tintBuilder: (c) => c.blueTint,
      title: 'Đặt sân venue',
      copy:
          'Đặt slot ở các sân partner mà không phải lo chuyển khoản trước cho chủ sân.',
      cost: '50–200 Đá / giờ',
    ),
    _UseCase(
      icon: FLucideIcons.userPlus,
      color: _crimson,
      tintBuilder: (c) => c.crimsonTint,
      title: 'Đặt lịch HLV & Trọng Tài',
      copy:
          'Trả trước cho buổi học hoặc trận có trọng tài. Huỷ trước 24h được hoàn 100%.',
      cost: '50–300 Đá / buổi',
    ),
    _UseCase(
      icon: FLucideIcons.split,
      color: _green,
      tintBuilder: (c) => c.greenTint,
      title: 'Split bill nội bộ',
      copy:
          'Chia tiền sân, tiền cầu, tiền nước trong lobby. Đội trưởng tạo lệnh, mọi người cùng góp.',
      cost: 'Tuỳ lobby',
    ),
  ];

  static const _faqs = <_Faq>[
    _Faq(
      q: 'Đá có hết hạn?',
      a: 'Không. Đá trong tài khoản giữ vô thời hạn.',
    ),
    _Faq(
      q: 'Có rút Đá thành tiền không?',
      a: 'Không — Đá chỉ tiêu trong Passe, không quy đổi ngược ra tiền mặt.',
    ),
    _Faq(
      q: 'Mua Đá có khuyến mãi không?',
      a: 'Có. Gói 500 Đá trở lên được tặng thêm 5–15% Đá thưởng.',
    ),
    _Faq(
      q: 'Đá thưởng có gì khác?',
      a: 'Tiêu giống Đá thường, nhưng không hoàn lại nếu huỷ giao dịch.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FScaffold(
      childPad: false,
      header: const WalletStackHeader(title: 'Đá là gì?'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _Hero(),
          const SizedBox(height: 16),
          const WalletSectionLabel('Bạn dùng Đá để làm gì'),
          const SizedBox(height: 10),
          for (final use in _uses) ...[
            _UseCard(use: use),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          const WalletSectionLabel('Quy định'),
          const SizedBox(height: 10),
          WalletCard(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  _FaqRow(faq: _faqs[i]),
                  if (i < _faqs.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Container(height: 1, color: colors.border),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return WalletCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const DaIcon(size: 84),
          const SizedBox(height: 14),
          Text(
            'Đá là điểm nội bộ của Passe',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Bitter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.4,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Dùng để giữ chỗ, đặt sân, thuê HLV và chia bill — không qua chuyển khoản từng lần.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _rateChunk(context, 'Tỉ giá', colors.mutedForeground),
                const SizedBox(width: 6),
                _rateChunk(context, '1.000đ', colors.secondaryForeground),
                const SizedBox(width: 6),
                _rateChunk(context, '=', colors.mutedForeground),
                const SizedBox(width: 6),
                _rateChunk(context, '1 Đá', colors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateChunk(BuildContext context, String text, Color color) => Text(
    text,
    style: TextStyle(
      fontFamily: 'Bitter',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1,
      color: color,
    ),
  );
}

class _UseCase {
  final IconData icon;
  final Color color;
  final Color Function(FColors) tintBuilder;
  final String title;
  final String copy;
  final String cost;

  const _UseCase({
    required this.icon,
    required this.color,
    required this.tintBuilder,
    required this.title,
    required this.copy,
    required this.cost,
  });
}

class _UseCard extends StatelessWidget {
  final _UseCase use;

  const _UseCard({required this.use});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return WalletCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: use.tintBuilder(colors),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(use.icon, size: 20, color: use.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        use.title,
                        style: TextStyle(
                          fontFamily: 'Bitter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: use.tintBuilder(colors),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        use.cost,
                        style: TextStyle(
                          fontFamily: 'Bitter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: use.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  use.copy,
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;

  const _Faq({required this.q, required this.a});
}

class _FaqRow extends StatelessWidget {
  final _Faq faq;

  const _FaqRow({required this.faq});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            faq.q,
            style: TextStyle(
              fontFamily: 'Bitter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            faq.a,
            style: TextStyle(
              fontFamily: 'Bitter',
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
