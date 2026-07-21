import 'dart:math';

import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_contact_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// Seed data standing in for the SAP customer master until the real
/// integration lands. Every record already carries a `sapCustomerId`, same
/// as a genuine sync payload would — there is no "draft"/unapproved state
/// represented here, matching the entry rule enforced by the repository.
///
/// Two tiers:
///  * [_curated] — six hand-written accounts covering every [CustomerStatus]
///    and a spread of provinces. These keep stable ids/codes so screenshots,
///    demos and any test referencing `cust-001` continue to work.
///  * [_generated] — bulk volume so filtering, grouping, search, pagination
///    and list animation are exercised against a realistic row count rather
///    than six rows that all fit on one screen.
///
/// Generation is seeded, so the dataset is identical on every run. A mock that
/// reshuffles itself would make pagination and grouping bugs unreproducible.
class MockCustomerData {
  MockCustomerData._();

  /// SAP sales organisations. Codes, not display names — SAP filters on codes
  /// and `CustomerDao.browse` compares them with equality.
  static const List<String> salesOrgs = ['PRD', 'ISI', 'STEEL', 'DIST'];

  /// SAP divisions (product lines).
  static const List<String> divisions = [
    'STEEL',
    'ROOF',
    'PIPE',
    'HARDWARE',
    'CONSTRUCTION',
  ];

  static const List<String> _distributionChannels = ['10', '20', '30'];
  static const List<String> _customerGroups = ['01', '02', '03', '04'];
  static const List<String> _priceGroups = ['P1', 'P2', 'P3'];

  static const List<String> _familyNames = [
    'Sok',
    'Chea',
    'Heng',
    'Prak',
    'Ros',
    'Kim',
    'Ly',
    'Chan',
    'Meas',
    'Nhem',
    'Pich',
    'Sam',
    'Tep',
    'Vann',
    'Yim',
    'Khiev',
    'Mao',
    'Ouk',
    'Seng',
    'Tith',
  ];

  static const List<String> _givenNames = [
    'Vithou',
    'Sopheak',
    'Bunthorn',
    'Sovann',
    'Chanthy',
    'Sotheara',
    'Dara',
    'Sreymom',
    'Malis',
    'Rithy',
    'Kosal',
    'Bopha',
    'Vichea',
    'Sreyneath',
    'Panha',
    'Chenda',
    'Samnang',
    'Theary',
    'Veasna',
    'Sokha',
  ];

  static const List<String> _shopPrefixes = [
    'Angkor',
    'Mekong',
    'Golden',
    'Bayon',
    'Sunrise',
    'Royal',
    'Phnom',
    'Silver',
    'Diamond',
    'Lotus',
    'Naga',
    'Apsara',
    'Tonle',
    'Preah',
  ];

  static const List<String> _shopSuffixes = [
    'Hardware',
    'Steel Trading',
    'Depot',
    'Construction Supply',
    'Iron Works',
    'Building Materials',
    'Roofing Center',
    'Pipe & Fittings',
  ];

  /// (province, district, lat, lng) — real Cambodian provincial centres so map
  /// pins and distance sorting land in plausible places.
  static const List<(String, String, double, double)> _locations = [
    ('Phnom Penh', 'Chamkar Mon', 11.5480, 104.9160),
    ('Phnom Penh', 'Mean Chey', 11.5266, 104.9282),
    ('Phnom Penh', 'Toul Kork', 11.5760, 104.8900),
    ('Siem Reap', 'Puok', 13.4125, 103.7089),
    ('Battambang', 'Battambang', 13.0957, 103.2022),
    ('Kampong Cham', 'Kampong Cham', 11.9934, 105.4635),
    ('Kampot', 'Kampot', 10.6104, 104.1817),
    ('Sihanoukville', 'Sihanoukville', 10.6270, 103.5220),
    ('Takeo', 'Doun Kaev', 10.9908, 104.7850),
    ('Kandal', 'Ta Khmau', 11.4830, 104.9470),
    ('Pursat', 'Pursat', 12.5388, 103.9192),
    ('Kampong Thom', 'Stung Sen', 12.7110, 104.8887),
  ];

  static const List<String> _products = [
    'Rebar',
    'Wire Mesh',
    'Steel Sections',
    'Sheet Metal',
    'Roofing Sheet',
    'PVC Pipe',
  ];

  static const List<(String, String)> _reps = [
    ('rep-01', 'Dara Chan'),
    ('rep-02', 'Sreymom Pich'),
    ('rep-03', 'Vichea Sok'),
  ];

  /// Full dataset: curated accounts first, then generated volume.
  static List<CustomerModel> generate({int bulkCount = 120}) {
    final now = DateTime.now();
    return [
      ..._curated(now),
      ..._generated(now, bulkCount),
    ];
  }

  // ── Curated ──────────────────────────────────────────────────────────

  static List<CustomerModel> _curated(DateTime now) => [
        CustomerModel(
          id: 'cust-001',
          sapCustomerId: 'SAP-100234',
          customerCode: 'CUS-0234',
          shopName: 'Vithou Hardware & Steel',
          enName: 'Vithou Hardware and Steel Co., Ltd',
          khName: 'វិធូ ដែក និងគ្រឿងសំណង់',
          ownerName: 'Sok Vithou',
          phone: '012 555 231',
          whatsapp: '012 555 231',
          email: 'vithou.hardware@gmail.com',
          address: 'St. 271, Sangkat Boeng Tumpun',
          province: 'Phnom Penh',
          district: 'Mean Chey',
          territory: 'Phnom Penh',
          latitude: 11.5266,
          longitude: 104.9282,
          creditLimit: 25000,
          creditBalance: 8400,
          currency: 'USD',
          taxNumber: 'K001-901234567',
          salesOrg: 'PRD',
          division: 'STEEL',
          distributionChannel: '10',
          customerGroup: '01',
          priceGroup: 'P1',
          status: CustomerStatus.active,
          assignedRepId: 'rep-01',
          assignedRepName: 'Dara Chan',
          createdAt: DateTime(2023, 4, 12),
          updatedAt: now.subtract(const Duration(days: 2)),
          originLeadId: 'lead-014',
          productsPurchased: const ['Rebar', 'Wire Mesh'],
          contacts: const [
            CustomerContactModel(
                id: 'c-001a',
                name: 'Sok Vithou',
                role: 'Owner',
                phone: '012 555 231'),
            CustomerContactModel(
                id: 'c-001b',
                name: 'Ly Dara',
                role: 'Buyer',
                phone: '098 442 110'),
          ],
          lastOrderDate: now.subtract(const Duration(days: 6)),
          lastVisitDate: now.subtract(const Duration(days: 13)),
          lifetimeValue: 84500,
          totalOrders: 37,
          openOpportunityCount: 1,
        ),
        CustomerModel(
          id: 'cust-002',
          sapCustomerId: 'SAP-100511',
          customerCode: 'CUS-0511',
          shopName: 'Angkor Construction Supply',
          enName: 'Angkor Construction Supply Co., Ltd',
          khName: 'អង្គរ ផ្គត់ផ្គង់សំណង់',
          ownerName: 'Chea Sopheak',
          phone: '017 320 998',
          email: 'sopheak.angkor@yahoo.com',
          address: 'National Road 6, Puok',
          province: 'Siem Reap',
          district: 'Puok',
          territory: 'Siem Reap',
          latitude: 13.4125,
          longitude: 103.7089,
          creditLimit: 40000,
          creditBalance: 12750,
          currency: 'USD',
          taxNumber: 'K002-880112233',
          salesOrg: 'ISI',
          division: 'CONSTRUCTION',
          distributionChannel: '20',
          customerGroup: '03',
          priceGroup: 'P2',
          status: CustomerStatus.active,
          assignedRepId: 'rep-01',
          assignedRepName: 'Dara Chan',
          createdAt: DateTime(2022, 11, 3),
          updatedAt: now.subtract(const Duration(days: 1)),
          productsPurchased: const ['Steel Sections', 'Sheet Metal'],
          contacts: const [
            CustomerContactModel(
                id: 'c-002a',
                name: 'Chea Sopheak',
                role: 'Owner',
                phone: '017 320 998'),
          ],
          lastOrderDate: now.subtract(const Duration(days: 1)),
          lastVisitDate: now.subtract(const Duration(days: 20)),
          lifetimeValue: 152300,
          totalOrders: 61,
          openOpportunityCount: 0,
        ),
        CustomerModel(
          id: 'cust-003',
          sapCustomerId: 'SAP-100078',
          customerCode: 'CUS-0078',
          shopName: 'Mekong Depot Wholesale',
          enName: 'Mekong Depot Wholesale Ltd',
          khName: 'ឃ្លាំងលក់ដុំ មេគង្គ',
          ownerName: 'Heng Bunthorn',
          phone: '011 774 220',
          address: 'St. 3, Kampong Cham Market',
          province: 'Kampong Cham',
          district: 'Kampong Cham',
          territory: 'Kampong Cham',
          latitude: 11.9934,
          longitude: 105.4635,
          creditLimit: 60000,
          // Deliberately over-extended — this is the Credit Hold account, so
          // availableCredit must clamp to zero rather than show a negative.
          creditBalance: 61500,
          currency: 'USD',
          taxNumber: 'K003-771002244',
          salesOrg: 'DIST',
          division: 'STEEL',
          distributionChannel: '20',
          customerGroup: '01',
          priceGroup: 'P1',
          status: CustomerStatus.creditHold,
          assignedRepId: 'rep-02',
          assignedRepName: 'Sreymom Pich',
          createdAt: DateTime(2021, 6, 28),
          updatedAt: now.subtract(const Duration(days: 4)),
          productsPurchased: const ['Rebar', 'Steel Sections', 'Wire Mesh'],
          contacts: const [
            CustomerContactModel(
                id: 'c-003a',
                name: 'Heng Bunthorn',
                role: 'Owner',
                phone: '011 774 220'),
            CustomerContactModel(
                id: 'c-003b',
                name: 'Chan Sreyneath',
                role: 'Accountant',
                phone: '070 118 552'),
          ],
          lastOrderDate: now.subtract(const Duration(days: 45)),
          lastVisitDate: now.subtract(const Duration(days: 30)),
          lifetimeValue: 231000,
          totalOrders: 94,
          openOpportunityCount: 0,
        ),
        CustomerModel(
          id: 'cust-004',
          sapCustomerId: 'SAP-100892',
          customerCode: 'CUS-0892',
          shopName: 'Battambang Iron Trading',
          enName: 'Battambang Iron Trading Co., Ltd',
          khName: 'ក្រុមហ៊ុន ជួញដូរដែក បាត់ដំបង',
          ownerName: 'Prak Sovann',
          phone: '015 660 043',
          whatsapp: '015 660 043',
          address: 'St. 3, Battambang City',
          province: 'Battambang',
          district: 'Battambang',
          territory: 'Battambang',
          latitude: 13.0957,
          longitude: 103.2022,
          creditLimit: 18000,
          creditBalance: 0,
          currency: 'USD',
          taxNumber: 'K004-660553311',
          salesOrg: 'STEEL',
          division: 'ROOF',
          distributionChannel: '30',
          customerGroup: '02',
          priceGroup: 'P3',
          status: CustomerStatus.dormant,
          assignedRepId: 'rep-02',
          assignedRepName: 'Sreymom Pich',
          createdAt: DateTime(2020, 2, 17),
          updatedAt: now.subtract(const Duration(days: 10)),
          productsPurchased: const ['Sheet Metal'],
          contacts: const [
            CustomerContactModel(
                id: 'c-004a',
                name: 'Prak Sovann',
                role: 'Owner',
                phone: '015 660 043'),
          ],
          lastOrderDate: now.subtract(const Duration(days: 96)),
          lastVisitDate: now.subtract(const Duration(days: 60)),
          lifetimeValue: 41200,
          totalOrders: 18,
          openOpportunityCount: 0,
        ),
        CustomerModel(
          id: 'cust-005',
          sapCustomerId: 'SAP-100455',
          customerCode: 'CUS-0455',
          shopName: 'Golden Sky Depot',
          enName: 'Golden Sky Depot Co., Ltd',
          khName: 'ឃ្លាំង មាសមេឃ',
          ownerName: 'Ros Chanthy',
          phone: '096 210 774',
          email: 'goldensky.depot@gmail.com',
          address: 'St. 217, Sangkat Toul Tumpung',
          province: 'Phnom Penh',
          district: 'Chamkar Mon',
          territory: 'Phnom Penh',
          latitude: 11.5480,
          longitude: 104.9160,
          creditLimit: 32000,
          creditBalance: 5100,
          currency: 'USD',
          taxNumber: 'K005-550664422',
          salesOrg: 'PRD',
          division: 'HARDWARE',
          distributionChannel: '10',
          customerGroup: '02',
          priceGroup: 'P2',
          status: CustomerStatus.active,
          assignedRepId: 'rep-01',
          assignedRepName: 'Dara Chan',
          createdAt: DateTime(2023, 9, 1),
          updatedAt: now.subtract(const Duration(hours: 6)),
          productsPurchased: const ['Rebar', 'Steel Sections'],
          contacts: const [
            CustomerContactModel(
                id: 'c-005a',
                name: 'Ros Chanthy',
                role: 'Owner',
                phone: '096 210 774'),
            CustomerContactModel(
                id: 'c-005b',
                name: 'Kim Sotheara',
                role: 'Storekeeper',
                phone: '087 663 210'),
          ],
          lastOrderDate: now.subtract(const Duration(hours: 20)),
          lastVisitDate: now.subtract(const Duration(days: 5)),
          lifetimeValue: 118750,
          totalOrders: 52,
          openOpportunityCount: 2,
        ),
        CustomerModel(
          id: 'cust-006',
          sapCustomerId: 'SAP-100120',
          customerCode: 'CUS-0120',
          shopName: 'Kampot Hardware Center',
          enName: 'Kampot Hardware Center',
          khName: 'មជ្ឈមណ្ឌល គ្រឿងដែក កំពត',
          ownerName: 'Sok Malis',
          phone: '077 445 219',
          address: 'St. 7, Kampot Town',
          province: 'Kampot',
          district: 'Kampot',
          territory: 'Kampot',
          latitude: 10.6104,
          longitude: 104.1817,
          creditLimit: 15000,
          creditBalance: 2300,
          currency: 'USD',
          taxNumber: 'K006-440775533',
          salesOrg: 'ISI',
          division: 'PIPE',
          distributionChannel: '30',
          customerGroup: '02',
          priceGroup: 'P3',
          status: CustomerStatus.active,
          assignedRepId: 'rep-02',
          assignedRepName: 'Sreymom Pich',
          createdAt: DateTime(2024, 1, 22),
          updatedAt: now.subtract(const Duration(days: 3)),
          productsPurchased: const ['Wire Mesh'],
          contacts: const [
            CustomerContactModel(
                id: 'c-006a',
                name: 'Sok Malis',
                role: 'Owner',
                phone: '077 445 219'),
          ],
          lastOrderDate: now.subtract(const Duration(days: 9)),
          lastVisitDate: now.subtract(const Duration(days: 9)),
          lifetimeValue: 27600,
          totalOrders: 11,
          openOpportunityCount: 0,
        ),
      ];

  // ── Generated volume ─────────────────────────────────────────────────

  /// Deterministic bulk records. Fixed seed keeps pagination boundaries and
  /// group counts identical run-to-run, so a failure is reproducible.
  static List<CustomerModel> _generated(DateTime now, int count) {
    final rng = Random(20260721);

    return List<CustomerModel>.generate(count, (i) {
      final n = i + 7; // curated occupies 1..6
      final family = _familyNames[rng.nextInt(_familyNames.length)];
      final given = _givenNames[rng.nextInt(_givenNames.length)];
      final owner = '$family $given';

      final shop = '${_shopPrefixes[rng.nextInt(_shopPrefixes.length)]} '
          '${_shopSuffixes[rng.nextInt(_shopSuffixes.length)]}';
      final (province, district, lat, lng) =
          _locations[rng.nextInt(_locations.length)];
      final (repId, repName) = _reps[rng.nextInt(_reps.length)];

      // Status mix skewed toward active — a directory that is 1/3 credit-hold
      // would not resemble a real book of business.
      final statusRoll = rng.nextInt(10);
      final status = switch (statusRoll) {
        0 => CustomerStatus.creditHold,
        1 || 2 => CustomerStatus.dormant,
        _ => CustomerStatus.active,
      };

      final creditLimit = (rng.nextInt(18) + 3) * 5000.0;
      final creditBalance = creditLimit * (rng.nextInt(90) / 100);
      final totalOrders = rng.nextInt(120);

      return CustomerModel(
        id: 'cust-${n.toString().padLeft(3, '0')}',
        sapCustomerId: 'SAP-2${n.toString().padLeft(5, '0')}',
        customerCode: 'CUS-${(1000 + n * 7).toString().padLeft(4, '0')}',
        shopName: shop,
        enName: '$shop Co., Ltd',
        ownerName: owner,
        phone: '0${rng.nextInt(3) + 1}${rng.nextInt(9)} '
            '${(rng.nextInt(900) + 100)} ${(rng.nextInt(900) + 100)}',
        address: 'St. ${rng.nextInt(400) + 1}, $district',
        province: province,
        district: district,
        territory: province,
        latitude: lat + (rng.nextDouble() - 0.5) * 0.05,
        longitude: lng + (rng.nextDouble() - 0.5) * 0.05,
        creditLimit: creditLimit,
        creditBalance: double.parse(creditBalance.toStringAsFixed(2)),
        currency: 'USD',
        taxNumber: 'K${n.toString().padLeft(3, '0')}-'
            '${rng.nextInt(900000000) + 100000000}',
        salesOrg: salesOrgs[i % salesOrgs.length],
        division: divisions[i % divisions.length],
        distributionChannel:
            _distributionChannels[i % _distributionChannels.length],
        customerGroup: _customerGroups[i % _customerGroups.length],
        priceGroup: _priceGroups[i % _priceGroups.length],
        status: status,
        assignedRepId: repId,
        assignedRepName: repName,
        createdAt: DateTime(
            2020 + rng.nextInt(6), rng.nextInt(12) + 1, rng.nextInt(28) + 1),
        updatedAt: now.subtract(Duration(hours: rng.nextInt(24 * 60))),
        // Set literal de-duplicates the random draws so a customer can't be
        // listed as buying "Rebar" twice.
        productsPurchased: <String>{
          for (var p = 0; p < rng.nextInt(3) + 1; p++)
            _products[rng.nextInt(_products.length)],
        }.toList(),
        contacts: [
          CustomerContactModel(
            id: 'c-${n.toString().padLeft(3, '0')}a',
            name: owner,
            role: 'Owner',
            phone: '0${rng.nextInt(9)}${rng.nextInt(9)} '
                '${rng.nextInt(900) + 100} ${rng.nextInt(900) + 100}',
          ),
        ],
        lastOrderDate: status == CustomerStatus.dormant
            ? now.subtract(Duration(days: 90 + rng.nextInt(180)))
            : now.subtract(Duration(days: rng.nextInt(30))),
        lastVisitDate: now.subtract(Duration(days: rng.nextInt(90))),
        lifetimeValue: (totalOrders * (rng.nextInt(2000) + 500)).toDouble(),
        totalOrders: totalOrders,
        openOpportunityCount: rng.nextInt(3),
      );
    });
  }
}
