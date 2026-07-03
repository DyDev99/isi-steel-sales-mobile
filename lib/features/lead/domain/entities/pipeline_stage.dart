enum PipelineStage {
  leads('Leads'),
  opportunities('Opportunities'),
  won('Won');

  const PipelineStage(this.label);
  final String label;
}
