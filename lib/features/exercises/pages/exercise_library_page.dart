import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/exercises/models/catalog_exercise.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ExerciseLibraryPage extends StatefulWidget {
  const ExerciseLibraryPage({super.key, this.pickMode = false});

  final bool pickMode;

  @override
  State<ExerciseLibraryPage> createState() => _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends State<ExerciseLibraryPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = ExerciseCatalog.search(_query);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pickMode
              ? AppStrings.pickExercise
              : AppStrings.exerciseLibrary,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              key: const Key('field_exercise_search'),
              decoration: const InputDecoration(
                hintText: AppStrings.searchExerciseHint,
              ),
              onChanged: (String value) => setState(() => _query = value),
            ),
          ),
          if (widget.pickMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('btn_custom_exercise'),
                  onPressed: () => _custom(context),
                  child: const Text(AppStrings.customExercise),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (BuildContext context, int index) {
                final item = items[index];
                return _ExerciseTile(
                  exercise: item,
                  onTap: () {
                    if (widget.pickMode) {
                      Navigator.of(context).pop(item);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _custom(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppStrings.customExercise),
          content: TextField(
            key: const Key('field_exercise_name'),
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: AppStrings.exerciseNameHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text(AppStrings.confirm),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!context.mounted || name == null || name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      CatalogExercise(
        id: '',
        nameZh: name,
        pattern: MovementPattern.push,
        equipment: EquipmentKind.barbell,
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.onTap});

  final CatalogExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: BorderSide(color: colors.border),
    );
    return Material(
      color: colors.card,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Lottie.asset(
                  exercise.lottieAsset,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nameZh,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${exercise.pattern.labelZh} · ${exercise.equipment.labelZh}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
