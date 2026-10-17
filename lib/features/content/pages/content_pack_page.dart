import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/content/content_copy.dart';
import 'package:curvefree/features/content/content_pack_session.dart';
import 'package:curvefree/features/content/content_pack_updater.dart';
import 'package:curvefree/features/content/content_providers.dart';
import 'package:curvefree/features/nutrition/nutrition_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentPackEntry extends StatelessWidget {
  const ContentPackEntry({
    super.key,
    required this.subtitle,
    required this.onTap,
  });

  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        key: const Key('content_pack_entry'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: curveSurfaceDecoration(colors),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      ContentCopy.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      key: const Key('content_pack_entry_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class ContentPackPage extends ConsumerStatefulWidget {
  const ContentPackPage({super.key});

  @override
  ConsumerState<ContentPackPage> createState() => _ContentPackPageState();
}

class _ContentPackPageState extends ConsumerState<ContentPackPage> {
  bool _busy = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ContentSnapshot> snapshot = ref.watch(
      contentSnapshotProvider,
    );
    return Scaffold(
      key: const Key('content_pack_page'),
      appBar: AppBar(title: const Text(ContentCopy.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: <Widget>[
          Text(
            snapshot.maybeWhen(
              data: _versionLine,
              orElse: () => ContentCopy.subtitle,
            ),
            key: const Key('content_pack_version'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('content_pack_check'),
            onPressed: _busy ? null : _check,
            child: const Text(ContentCopy.checkUpdate),
          ),
          if (_status.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _status,
              key: const Key('content_pack_status'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('content_pack_attribution'),
              onPressed: () {
                final ContentSnapshot? data = snapshot.asData?.value;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ContentAttributionPage(snapshot: data),
                  ),
                );
              },
              child: const Text(ContentCopy.attribution),
            ),
          ),
        ],
      ),
    );
  }

  String _versionLine(ContentSnapshot snapshot) {
    final String where = snapshot.installed
        ? ContentCopy.installed
        : ContentCopy.bundled;
    return '$where ${snapshot.manifest.version}';
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    final ContentUpdateOutcome outcome = await checkContentPackUpdate(
      ref.read(contentPackUpdaterProvider),
    );
    if (outcome == ContentUpdateOutcome.updated) {
      try {
        await ContentPackSession.reload();
      } on Object {
        ContentPackSession.invalidate();
      }
      ref.invalidate(contentSnapshotProvider);
      ref.invalidate(foodCatalogProvider);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _status = _message(outcome);
    });
  }

  String _message(ContentUpdateOutcome outcome) {
    switch (outcome) {
      case ContentUpdateOutcome.updated:
        return ContentCopy.updated;
      case ContentUpdateOutcome.alreadyCurrent:
        return ContentCopy.already;
      case ContentUpdateOutcome.offline:
        return ContentCopy.offline;
      case ContentUpdateOutcome.rejected:
        return ContentCopy.rejected;
      case ContentUpdateOutcome.unavailable:
        return ContentCopy.unavailable;
      case ContentUpdateOutcome.noRelease:
        return ContentCopy.noRelease;
      case ContentUpdateOutcome.failed:
        return ContentCopy.failed;
    }
  }
}

class ContentAttributionPage extends StatelessWidget {
  const ContentAttributionPage({super.key, required this.snapshot});

  final ContentSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final ContentSnapshot? data = snapshot;
    return Scaffold(
      key: const Key('content_attribution_page'),
      appBar: AppBar(title: const Text(ContentCopy.attribution)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: <Widget>[
          if (data == null)
            const Text(ContentCopy.attributionMissing)
          else ...<Widget>[
            Text(
              ContentCopy.exercisePack,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(data.manifest.exercises.license),
            Text(data.manifest.exercises.sourceUrl),
            const SizedBox(height: AppSpacing.md),
            Text(
              ContentCopy.foodPack,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(data.manifest.foods.license),
            Text(data.manifest.foods.sourceUrl),
            const SizedBox(height: AppSpacing.md),
            SelectableText(data.attribution),
          ],
        ],
      ),
    );
  }
}
