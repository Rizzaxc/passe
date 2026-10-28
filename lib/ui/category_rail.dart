import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

class PCategoryItem {
  final IconData icon;
  final String label;

  /// An unread dot after the label (e.g. newly unlocked achievements).
  final bool dot;

  /// Attached to the chip so a coach-mark tour can point at it.
  final GlobalKey? anchorKey;

  const PCategoryItem({
    required this.icon,
    required this.label,
    this.dot = false,
    this.anchorKey,
  });
}

/// A horizontally scrolling row of labelled pill chips — the switcher for a
/// screen with more sections than an icon-only tab bar can carry legibly
/// (Discover's five). Exactly one chip is selected; the selected one scrolls
/// itself into view so a deep-linked index is never hidden off-screen.
class PCategoryRail extends StatefulWidget {
  final List<PCategoryItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const PCategoryRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<PCategoryRail> createState() => _PCategoryRailState();
}

class _PCategoryRailState extends State<PCategoryRail> {
  late List<GlobalKey> _keys = _makeKeys();

  List<GlobalKey> _makeKeys() => List.generate(
    widget.items.length,
    (i) => GlobalKey(debugLabel: 'rail.$i'),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _reveal(animate: false),
    );
  }

  @override
  void didUpdateWidget(PCategoryRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) _keys = _makeKeys();
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _reveal(animate: true),
      );
    }
  }

  void _reveal({required bool animate}) {
    if (!mounted) return;
    final ctx = _keys[widget.selectedIndex].currentContext;
    // The post-frame callback can land while the chip isn't laid out (the
    // route is offstage, or mid hot-restart) — ensureVisible asserts then.
    final box = ctx?.findRenderObject();
    if (ctx == null || box is! RenderBox || !box.hasSize) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: animate ? const Duration(milliseconds: 280) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (var i = 0; i < widget.items.length; i++)
              KeyedSubtree(
                key: widget.items[i].anchorKey ?? ValueKey(i),
                child: _RailChip(
                  key: _keys[i],
                  item: widget.items[i],
                  selected: i == widget.selectedIndex,
                  onPress: () => widget.onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailChip extends StatelessWidget {
  final PCategoryItem item;
  final bool selected;
  final VoidCallback onPress;

  const _RailChip({
    super.key,
    required this.item,
    required this.selected,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    // Brand red for the active chip — the same `primary` the bottom nav's
    // active tab and primary buttons use.
    final fg = selected ? colors.primaryForeground : colors.foreground;

    return Semantics(
      selected: selected,
      button: true,
      child: FTappable(
        onPress: onPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          // Explicit: a horizontal scroll view hands its children a loose
          // height, so without this the pill hugs the glyphs.
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(item.icon, size: 16, color: fg),
              Text(
                item.label,
                style: context.theme.typography.body.sm.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              if (item.dot)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    // On the red active chip the dot inverts to stay visible.
                    color: selected ? colors.primaryForeground : colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One page of a [PRailTabs]: its chip and its body. [build] is lazy — only
/// the active page is ever built, so a page that fires a feed RPC on build
/// costs nothing until it's opened.
class PRailTab {
  final IconData icon;
  final String label;
  final Widget Function() build;
  final bool dot;
  final GlobalKey? anchorKey;

  const PRailTab({
    required this.icon,
    required this.label,
    required this.build,
    this.dot = false,
    this.anchorKey,
  });
}

/// The app's sub-navigation: a [PCategoryRail] over the active page, with an
/// optional [header] between them (Discover puts its filter summary there).
/// Replaces `FTabs` everywhere — icon-only segmented tabs didn't say what
/// each page was, and only the active page is built.
class PRailTabs extends StatelessWidget {
  final List<PRailTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final Widget? header;

  const PRailTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final active = index.clamp(0, tabs.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PCategoryRail(
          items: [
            for (final t in tabs)
              PCategoryItem(
                icon: t.icon,
                label: t.label,
                dot: t.dot,
                anchorKey: t.anchorKey,
              ),
          ],
          selectedIndex: active,
          onSelected: onChanged,
        ),
        if (header != null) ...[const SizedBox(height: 10), header!],
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(active),
              child: tabs[active].build(),
            ),
          ),
        ),
      ],
    );
  }
}
