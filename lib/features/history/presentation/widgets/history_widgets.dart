import 'dart:io';

import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/cards/app_card.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/presentation/widgets/risk_widgets.dart';
import 'package:flutter/material.dart';

/// Single history row with image thumb + metrics.
class HistoryRecordTile extends StatelessWidget {
  /// Record.
  final HistoryRecord record;

  /// Selected for multi-delete.
  final bool selected;

  /// Tap.
  final VoidCallback? onTap;

  /// Long-press selection.
  final VoidCallback? onLongPress;

  /// Delete action.
  final VoidCallback? onDelete;

  /// Creates [HistoryRecordTile].
  const HistoryRecordTile({
    required this.record,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = riskLevelColor(record.riskLevel);

    return AppCard(
      onTap: onTap,
      borderColor: selected ? accent : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        onLongPress: onLongPress,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(record: record, accent: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RiskLevelChip(level: record.riskLevel),
                      const Spacer(),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  Text(
                    _formatTime(record.timestamp),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Flood ${record.floodPercent.toStringAsFixed(1)}%  ·  '
                    'Score ${record.riskScore.toStringAsFixed(0)}  ·  '
                    '${record.speedKmh.toStringAsFixed(0)} km/h',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (record.hasGps) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${record.latitude!.toStringAsFixed(5)}, '
                      '${record.longitude!.toStringAsFixed(5)}'
                      '${record.accuracyMeters != null ? '  ±${record.accuracyMeters!.toStringAsFixed(0)} m' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: accent)
            else
              Icon(Icons.circle_outlined, color: scheme.outlineVariant),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.record, required this.accent});

  final HistoryRecord record;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final path = record.imagePath;
    final file = path != null ? File(path) : null;
    final hasFile = file != null && file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 72,
        height: 72,
        child: hasFile
            ? Image.file(file, fit: BoxFit.cover)
            : ColoredBox(
                color: accent.withValues(alpha: 0.15),
                child: Icon(Icons.image_not_supported_outlined, color: accent),
              ),
      ),
    );
  }
}

/// Search field for history.
class HistorySearchBar extends StatefulWidget {
  /// Current query from bloc.
  final String query;

  /// On change.
  final ValueChanged<String> onChanged;

  /// Creates [HistorySearchBar].
  const HistorySearchBar({
    required this.query,
    required this.onChanged,
    super.key,
  });

  @override
  State<HistorySearchBar> createState() => _HistorySearchBarState();
}

class _HistorySearchBarState extends State<HistorySearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant HistorySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
      _controller.selection =
          TextSelection.collapsed(offset: widget.query.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Search risk, flood %, coords, notes…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        isDense: true,
      ),
    );
  }
}

/// Risk / flood / image filter chips.
class HistoryFilterBar extends StatelessWidget {
  /// Filter.
  final HistoryFilter filter;

  /// Toggle risk.
  final ValueChanged<RiskLevel> onRiskToggle;

  /// Images only.
  final VoidCallback onImagesOnlyToggle;

  /// Flood threshold presets.
  final ValueChanged<double?> onMinFloodChanged;

  /// Clear filters.
  final VoidCallback onClear;

  /// Creates [HistoryFilterBar].
  const HistoryFilterBar({
    required this.filter,
    required this.onRiskToggle,
    required this.onImagesOnlyToggle,
    required this.onMinFloodChanged,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final level in RiskLevel.values)
          FilterChip(
            label: Text(level.label),
            selected: filter.riskLevels.contains(level),
            onSelected: (_) => onRiskToggle(level),
            selectedColor: riskLevelColor(level).withValues(alpha: 0.25),
          ),
        FilterChip(
          label: const Text('With image'),
          selected: filter.hasImageOnly == true,
          onSelected: (_) => onImagesOnlyToggle(),
        ),
        FilterChip(
          label: const Text('Flood ≥ 8%'),
          selected: filter.minFloodPercent == 8,
          onSelected: (selected) => onMinFloodChanged(selected ? 8 : null),
        ),
        FilterChip(
          label: const Text('Flood ≥ 20%'),
          selected: filter.minFloodPercent == 20,
          onSelected: (selected) => onMinFloodChanged(selected ? 20 : null),
        ),
        if (filter.isActive)
          ActionChip(
            avatar: const Icon(Icons.clear, size: 16),
            label: const Text('Clear filters'),
            onPressed: onClear,
          ),
      ],
    );
  }
}
