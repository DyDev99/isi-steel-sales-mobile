import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';

class StageBadge extends StatelessWidget {
  const StageBadge({super.key, required this.stage});
  final PipelineStage stage;

  Color get _color => switch (stage) {
        PipelineStage.leads => Vibe.violet,
        PipelineStage.opportunities => Vibe.amber,
        PipelineStage.won => Vibe.success,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        stage.label,
        style:
            TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
