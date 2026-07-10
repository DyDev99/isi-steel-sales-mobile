import 'dart:math';

import 'package:isi_steel_sales_mobile/features/lead/domain/entities/activity_log_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/budget_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/contact.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/credit_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_source.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_sub_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/shop_type.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';

/// Deterministic (fixed seed) generator for realistic Cambodian steel-trade
/// demo data. Regenerating always produces the same 40-60 companies so the
/// board looks the same across app restarts within a build.
class MockLeadData {
  MockLeadData._();

  static const _companyNamesSeed = [
    'Angkor Steel Depot',
    'Mekong Steel Trading',
    'Phnom Penh Iron Supply',
    'Golden Metal Depot',
    'Kampot Steel Center',
    'Battambang Construction Supply',
    'Kandal Hardware',
    'Tonle Steel',
    'New Bridge Steel',
    'Victory Depot',
  ];

  static const _namePrefixes = [
    'Angkor',
    'Mekong',
    'Tonle',
    'Bayon',
    'Naga',
    'Golden',
    'Royal',
    'Victory',
    'Chenla',
    'Independence',
    'Friendship',
    'Kampuchea',
    'Sunrise',
    'Diamond',
    'Union',
    'Prosperity',
    'Rithisen',
    'Mekong Delta',
    'Riverside',
    'Highland',
  ];

  static const _nameSuffixes = [
    'Steel Depot',
    'Steel Trading',
    'Iron Supply',
    'Metal Depot',
    'Steel Center',
    'Construction Supply',
    'Hardware',
    'Steel Co.',
    'Steel Group',
    'Building Materials',
    'Metal Works',
    'Steel Warehouse',
  ];

  static const _ownerNames = [
    'Sokha',
    'Dara',
    'Sopheak',
    'Chan',
    'Vanna',
    'Rithy',
    'Sophea',
    'Bopha',
    'Chenda',
    'Pisey',
    'Vuthy',
    'Kunthea',
    'Sovannaroth',
    'Rathanak',
    'Malis',
    'Sreymom',
    'Pheakdey',
    'Sarun',
    'Kolab',
    'Panha',
  ];

  static const _salesReps = [
    'Mr. Sarath Chea',
    'Ms. Sreyneang Ly',
    'Mr. Vibol Heng',
    'Ms. Channary Sok',
    'Mr. Piseth Nou',
    'Ms. Davy Meas',
  ];

  static const _industries = [
    'Steel Distribution',
    'Hardware Retail',
    'Construction Supply',
    'Metal Fabrication',
    'Building Materials',
  ];

  static const _products = [
    'Rebar',
    'Steel Coil',
    'Wire Mesh',
    'Galvanized Sheet',
    'Steel Pipe',
    'Angle Bar',
    'H-Beam',
    'Roofing Sheet',
    'Steel Nails',
    'Binding Wire',
  ];

  // province -> (district list, approx center lat/lng)
  static const _provinces = <String, (List<String>, double, double)>{
    'Phnom Penh': (
      ['Chamkarmon', 'Toul Kork', 'Meanchey', 'Sen Sok', 'Daun Penh'],
      11.5564,
      104.9282
    ),
    'Kandal': (['Ta Khmau', 'Kien Svay', 'Sa\'ang'], 11.4780, 104.9450),
    'Kampot': (['Kampot Town', 'Chum Kiri', 'Angkor Chey'], 10.6104, 104.1817),
    'Battambang': (['Battambang Town', 'Bavel', 'Sangkae'], 13.0957, 103.2022),
    'Siem Reap': (['Siem Reap Town', 'Angkor Thom', 'Puok'], 13.3671, 103.8448),
    'Preah Sihanouk': (['Sihanoukville', 'Prey Nob'], 10.6104, 103.5299),
    'Kampong Cham': (['Kampong Cham Town', 'Cheung Prey'], 12.0000, 105.4630),
    'Kampong Speu': (['Chbar Mon', 'Samraong Tong'], 11.4585, 104.5225),
    'Takeo': (['Doun Kaev', 'Bati'], 10.9908, 104.7852),
    'Prey Veng': (['Prey Veng Town', 'Kamchay Mear'], 11.4860, 105.3251),
  };

  static List<Lead> generate({int count = 50, int seed = 42}) {
    final rand = Random(seed);
    final leads = <Lead>[];

    for (var i = 0; i < count; i++) {
      leads.add(_buildLead(rand, i));
    }
    return leads;
  }

  static Lead _buildLead(Random rand, int index) {
    final id = 'LEAD-${(1000 + index)}';
    final companyName = index < _companyNamesSeed.length
        ? _companyNamesSeed[index]
        : '${_pick(rand, _namePrefixes)} ${_pick(rand, _nameSuffixes)}';

    final ownerName = 'Mr./Ms. ${_pick(rand, _ownerNames)}'.replaceFirst(
      'Mr./Ms.',
      rand.nextBool() ? 'Mr.' : 'Ms.',
    );

    final provinceEntry =
        _provinces.entries.elementAt(rand.nextInt(_provinces.length));
    final province = provinceEntry.key;
    final (districts, baseLat, baseLng) = provinceEntry.value;
    final district = _pick(rand, districts);
    final latitude = baseLat + (rand.nextDouble() - 0.5) * 0.15;
    final longitude = baseLng + (rand.nextDouble() - 0.5) * 0.15;

    // Weighted stage distribution: ~55% leads, ~30% opportunities, ~15% won.
    final stageRoll = rand.nextDouble();
    final stage = stageRoll < 0.55
        ? PipelineStage.leads
        : stageRoll < 0.85
            ? PipelineStage.opportunities
            : PipelineStage.won;

    final priorityRoll = rand.nextDouble();
    final priority = priorityRoll < 0.3
        ? Priority.high
        : priorityRoll < 0.7
            ? Priority.medium
            : Priority.low;

    final createdDate =
        DateTime.now().subtract(Duration(days: 5 + rand.nextInt(365)));
    final expectedRevenue = (5000 + rand.nextInt(95000)).toDouble();
    final currentRevenue = stage == PipelineStage.won
        ? expectedRevenue * (0.7 + rand.nextDouble() * 0.5)
        : 0.0;
    final creditLimit = stage == PipelineStage.leads
        ? 0.0
        : (10000 + rand.nextInt(90000)).toDouble();

    final creditStatus = switch (stage) {
      PipelineStage.leads => CreditStatus.notApplicable,
      PipelineStage.opportunities =>
        rand.nextBool() ? CreditStatus.pending : CreditStatus.notApplicable,
      PipelineStage.won => CreditStatus.approved,
    };

    final assignedRep = _pick(rand, _salesReps);
    final leadSource =
        LeadSource.values[rand.nextInt(LeadSource.values.length)];
    final industry = _pick(rand, _industries);

    final contacts = [
      Contact(
        name: ownerName,
        role: 'Owner',
        phone: _phone(rand),
        email: '${_slug(companyName)}@gmail.com',
        isPrimary: true,
      ),
      if (rand.nextBool())
        Contact(
          name:
              '${rand.nextBool() ? 'Mr.' : 'Ms.'} ${_pick(rand, _ownerNames)}',
          role: 'Purchasing Manager',
          phone: _phone(rand),
        ),
    ];

    final documents = _buildDocuments(rand, id, stage, createdDate);
    final notes = _buildNotes(rand, companyName);
    final interestedProducts =
        List.generate(1 + rand.nextInt(2), (_) => _pick(rand, _products))
            .toSet()
            .toList();

    final opportunityInfo = stage == PipelineStage.leads
        ? null
        : OpportunityInfo(
            estimatedValue: expectedRevenue,
            subStage: stage == PipelineStage.won
                ? OpportunitySubStage.negotiating
                : OpportunitySubStage
                    .values[rand.nextInt(OpportunitySubStage.values.length)],
            expectedClosingDate:
                createdDate.add(Duration(days: 20 + rand.nextInt(60))),
            tonnage: rand.nextBool() ? (5 + rand.nextInt(60)).toDouble() : null,
            productGrade: rand.nextBool()
                ? 'Grade ${_pick(rand, [
                        '40',
                        '60',
                      ])}'
                : null,
            budgetStatus: rand.nextBool()
                ? BudgetStatus.values[rand.nextInt(BudgetStatus.values.length)]
                : null,
            hasDecisionMakerAccess: rand.nextBool() ? rand.nextBool() : null,
            productsInterested: List.generate(
                    1 + rand.nextInt(3), (_) => _pick(rand, _products))
                .toSet()
                .toList(),
            lastContact:
                DateTime.now().subtract(Duration(days: rand.nextInt(14))),
          );

    final wonInfo = stage != PipelineStage.won
        ? null
        : WonInfo(
            finalValue: currentRevenue,
            deliveryTimeline:
                _pick(rand, ['This month', 'Next month', 'This quarter']),
            onboardingStatus: OnboardingStatus
                .values[rand.nextInt(OnboardingStatus.values.length)],
            shopType: ShopType.values[rand.nextInt(ShopType.values.length)],
            customerCode: 'CUS-${(20000 + index)}',
            sapCustomerId: 'SAP${(100000 + index * 7)}',
            approvedCreditLimit: creditLimit,
            approvalDate:
                createdDate.add(Duration(days: 30 + rand.nextInt(30))),
            contractDate:
                createdDate.add(Duration(days: 35 + rand.nextInt(30))),
            annualRevenue: currentRevenue,
            productsPurchased: List.generate(
                    2 + rand.nextInt(3), (_) => _pick(rand, _products))
                .toSet()
                .toList(),
            firstOrderDate:
                createdDate.add(Duration(days: 40 + rand.nextInt(40))),
            accountManager: assignedRep,
          );

    return Lead(
      id: id,
      companyName: companyName,
      ownerName: ownerName,
      phone: _phone(rand),
      email: '${_slug(companyName)}@gmail.com',
      address: '#${1 + rand.nextInt(200)}, $district, $province',
      province: province,
      district: district,
      latitude: latitude,
      longitude: longitude,
      storefrontImageUrl:
          'https://images.unsplash.com/photo-1581093458791-9d09c1b1c1b1?auto=format&fit=crop&w=800&q=60',
      businessRegistrationNumber: 'BRN-${(400000 + index * 13)}',
      taxId: 'TAX-${(700000 + index * 17)}',
      leadSource: leadSource,
      createdDate: createdDate,
      expectedRevenue: expectedRevenue,
      currentRevenue: currentRevenue,
      assignedRepName: assignedRep,
      creditLimit: creditLimit,
      creditStatus: creditStatus,
      stage: stage,
      priority: priority,
      industry: industry,
      territory: province,
      interestedProducts: interestedProducts,
      notes: notes,
      contacts: contacts,
      documents: documents,
      opportunityInfo: opportunityInfo,
      wonInfo: wonInfo,
    );
  }

  static List<LeadDocument> _buildDocuments(
    Random rand,
    String leadId,
    PipelineStage stage,
    DateTime createdDate,
  ) {
    final docs = <LeadDocument>[
      LeadDocument(
        id: '$leadId-DOC-1',
        name: 'Storefront Photo.jpg',
        type: DocumentType.storefrontPhoto,
        url:
            'https://images.unsplash.com/photo-1519643381401-22c77e60520e?auto=format&fit=crop&w=800&q=60',
        uploadedDate: createdDate.add(const Duration(days: 1)),
      ),
    ];
    if (stage != PipelineStage.leads) {
      docs.addAll([
        LeadDocument(
          id: '$leadId-DOC-2',
          name: 'Business License.pdf',
          type: DocumentType.businessLicense,
          url: 'mock://documents/business_license.pdf',
          uploadedDate: createdDate.add(const Duration(days: 4)),
        ),
        LeadDocument(
          id: '$leadId-DOC-3',
          name: 'Tax Registration.pdf',
          type: DocumentType.taxRegistration,
          url: 'mock://documents/tax_registration.pdf',
          uploadedDate: createdDate.add(const Duration(days: 5)),
        ),
      ]);
    }
    if (stage == PipelineStage.won) {
      docs.addAll([
        LeadDocument(
          id: '$leadId-DOC-4',
          name: 'Owner ID.pdf',
          type: DocumentType.ownerId,
          url: 'mock://documents/owner_id.pdf',
          uploadedDate: createdDate.add(const Duration(days: 6)),
        ),
        LeadDocument(
          id: '$leadId-DOC-5',
          name: 'Warehouse Photo.jpg',
          type: DocumentType.warehousePhoto,
          url:
              'https://images.unsplash.com/photo-1553413077-190dd305871c?auto=format&fit=crop&w=800&q=60',
          uploadedDate: createdDate.add(const Duration(days: 7)),
        ),
      ]);
    }
    return docs;
  }

  static List<String> _buildNotes(Random rand, String companyName) {
    const pool = [
      'Owner prefers WhatsApp for follow-ups.',
      'Interested in bulk rebar pricing for Q3 restock.',
      'Store is expanding a second branch nearby.',
      'Requested a site visit before signing.',
      'Currently buying from a competitor, price-sensitive.',
    ];
    final count = rand.nextInt(3);
    return List.generate(count, (_) => _pick(rand, pool));
  }

  static List<ActivityLogItem> buildActivity(Lead lead) {
    final items = <ActivityLogItem>[
      ActivityLogItem(
        id: '${lead.id}-ACT-1',
        kind: ActivityLogKind.leadCreated,
        title: 'Lead Created',
        description: '${lead.companyName} added via ${lead.leadSource.label}.',
        timestamp: lead.createdDate,
        actor: lead.assignedRepName,
      ),
      ActivityLogItem(
        id: '${lead.id}-ACT-2',
        kind: ActivityLogKind.siteVisit,
        title: 'Visited Customer',
        description: 'Field visit at ${lead.address}.',
        timestamp: lead.createdDate.add(const Duration(days: 1)),
        actor: lead.assignedRepName,
      ),
      ActivityLogItem(
        id: '${lead.id}-ACT-3',
        kind: ActivityLogKind.gpsCaptured,
        title: 'Captured GPS',
        description:
            'Location pinned at ${lead.latitude.toStringAsFixed(4)}, ${lead.longitude.toStringAsFixed(4)}.',
        timestamp: lead.createdDate.add(const Duration(days: 1)),
        actor: lead.assignedRepName,
      ),
      ActivityLogItem(
        id: '${lead.id}-ACT-4',
        kind: ActivityLogKind.photoUploaded,
        title: 'Uploaded Store Photo',
        description: 'Storefront photo attached.',
        timestamp: lead.createdDate.add(const Duration(days: 1)),
        actor: lead.assignedRepName,
      ),
    ];

    if (lead.stage != PipelineStage.leads) {
      items.addAll([
        ActivityLogItem(
          id: '${lead.id}-ACT-5',
          kind: ActivityLogKind.stageChanged,
          title: 'Converted to Opportunity',
          description: '${lead.companyName} moved from Leads to Opportunities.',
          timestamp: lead.createdDate.add(const Duration(days: 4)),
          actor: lead.assignedRepName,
        ),
        ActivityLogItem(
          id: '${lead.id}-ACT-6',
          kind: ActivityLogKind.documentCollected,
          title: 'Collected Business License',
          description: 'Business License.pdf received.',
          timestamp: lead.createdDate.add(const Duration(days: 4)),
          actor: lead.assignedRepName,
        ),
        ActivityLogItem(
          id: '${lead.id}-ACT-7',
          kind: ActivityLogKind.documentCollected,
          title: 'Collected Tax ID',
          description: 'Tax Registration.pdf received.',
          timestamp: lead.createdDate.add(const Duration(days: 5)),
          actor: lead.assignedRepName,
        ),
        ActivityLogItem(
          id: '${lead.id}-ACT-8',
          kind: ActivityLogKind.creditSubmitted,
          title: 'Submitted Credit Application',
          description: 'Credit application sent to Finance for review.',
          timestamp: lead.createdDate.add(const Duration(days: 6)),
          actor: lead.assignedRepName,
        ),
      ]);
    }

    if (lead.stage == PipelineStage.won) {
      items.addAll([
        ActivityLogItem(
          id: '${lead.id}-ACT-9',
          kind: ActivityLogKind.creditApproved,
          title: 'Finance Approved',
          description:
              'Credit limit of \$${lead.creditLimit.toStringAsFixed(0)} approved.',
          timestamp: lead.createdDate.add(const Duration(days: 30)),
          actor: 'Finance Team',
        ),
        ActivityLogItem(
          id: '${lead.id}-ACT-10',
          kind: ActivityLogKind.customerCreated,
          title: 'Customer Created in SAP',
          description:
              'Customer record ${lead.wonInfo?.sapCustomerId} created.',
          timestamp: lead.createdDate.add(const Duration(days: 31)),
          actor: 'System',
        ),
        ActivityLogItem(
          id: '${lead.id}-ACT-11',
          kind: ActivityLogKind.stageChanged,
          title: 'Opportunity Won',
          description: '${lead.companyName} approved as a customer.',
          timestamp: lead.createdDate.add(const Duration(days: 32)),
          actor: lead.assignedRepName,
        ),
        ActivityLogItem(
          id: '${lead.id}-ACT-12',
          kind: ActivityLogKind.orderReceived,
          title: 'First Order Received',
          description: 'Initial purchase order confirmed.',
          timestamp: lead.createdDate.add(const Duration(days: 40)),
          actor: lead.assignedRepName,
        ),
      ]);
    }

    for (final note in lead.notes) {
      items.add(
        ActivityLogItem(
          id: '${lead.id}-NOTE-${items.length}',
          kind: ActivityLogKind.note,
          title: 'Note added',
          description: note,
          timestamp: lead.createdDate.add(Duration(days: 2 + items.length)),
          actor: lead.assignedRepName,
        ),
      );
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  static List<NotificationItem> buildNotifications(List<Lead> leads) {
    final rand = Random(7);
    final items = <NotificationItem>[];
    final won = leads.where((l) => l.stage == PipelineStage.won).take(3);
    for (final lead in won) {
      items.add(NotificationItem(
        id: 'NTF-${items.length}',
        kind: NotificationKind.creditApproved,
        title: 'Finance approved customer',
        body: '${lead.companyName}\'s credit application was approved.',
        timestamp: DateTime.now().subtract(Duration(hours: rand.nextInt(48))),
      ));
    }
    final leadsOnly =
        leads.where((l) => l.stage == PipelineStage.leads).take(3);
    for (final lead in leadsOnly) {
      items.add(NotificationItem(
        id: 'NTF-${items.length}',
        kind: NotificationKind.leadAssigned,
        title: 'Lead assigned',
        body: '${lead.companyName} was assigned to ${lead.assignedRepName}.',
        timestamp: DateTime.now().subtract(Duration(hours: rand.nextInt(72))),
      ));
    }
    final opps =
        leads.where((l) => l.stage == PipelineStage.opportunities).take(3);
    for (final lead in opps) {
      items.add(NotificationItem(
        id: 'NTF-${items.length}',
        kind: NotificationKind.opportunityMoved,
        title: 'Opportunity moved',
        body: '${lead.companyName} advanced to Opportunities.',
        timestamp: DateTime.now().subtract(Duration(hours: rand.nextInt(96))),
      ));
      items.add(NotificationItem(
        id: 'NTF-${items.length}',
        kind: NotificationKind.creditPending,
        title: 'Credit application pending',
        body: '${lead.companyName}\'s credit application is awaiting review.',
        timestamp: DateTime.now().subtract(Duration(hours: rand.nextInt(96))),
      ));
    }
    if (leads.isNotEmpty) {
      items.add(NotificationItem(
        id: 'NTF-${items.length}',
        kind: NotificationKind.followUpDue,
        title: 'Follow-up due tomorrow',
        body:
            '${leads.first.companyName} has a follow-up scheduled for tomorrow.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ));
    }
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  static String _pick(Random rand, List<String> list) =>
      list[rand.nextInt(list.length)];

  static String _phone(Random rand) => '0${[
        6,
        7,
        8,
        9,
      ][rand.nextInt(4)]}${List.generate(7, (_) => rand.nextInt(10)).join()}';

  static String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
      .replaceAll(RegExp(r'^\.|\.$'), '');
}
