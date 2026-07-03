/// Shared params for usecases that only need a lead id
/// ([GetLeadById], [DeleteLead], [FetchLeadActivity]).
class LeadIdParams {
  const LeadIdParams(this.leadId);
  final String leadId;
}
