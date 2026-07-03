enum OpportunitySubStage {
  qualifying('Qualifying'),
  quoteSent('Quote Sent'),
  negotiating('Negotiating');

  const OpportunitySubStage(this.label);
  final String label;

  OpportunitySubStage get next => switch (this) {
        OpportunitySubStage.qualifying => OpportunitySubStage.quoteSent,
        OpportunitySubStage.quoteSent => OpportunitySubStage.negotiating,
        OpportunitySubStage.negotiating => OpportunitySubStage.negotiating,
      };
}
