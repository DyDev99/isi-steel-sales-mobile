import re
import os

files_to_fix = [
    'lib/features/order/data/models/quotation_api_models.dart',
    'lib/features/depots/data/models/depot_api_mapper.dart',
    'lib/features/depots/data/models/depot_model.dart',
    'lib/features/quotations/data/models/quotation_dto.dart',
    'lib/features/authentication/data/models/auth_profile_model.dart',
    'lib/shared/widgets/promotions/promo_view.dart',
    'lib/features/depots/data/models/business_partner_response_model.dart',
    'lib/features/depots/data/models/portal_depot_mapper.dart'
]

replacements = [
    (r"json\['depotCode'\]", "json['customerCode']"),
    (r"json\['depotGroup'\]", "json['customerGroup']"),
    (r"json\['depotId'\]", "json['customerId']"),
    (r"json\['depotName'\]", "json['customerName']"),
    (r"json\['depotReference'\]", "json['customerReference']"),
    (r"json\['depots'\]", "json['customers']"),
    (r"json\['depotNumber'\]", "json['customerNumber']"),
    (r"json\['depot_code'\]", "json['customer_code']"),
    (r"json\['depot_id'\]", "json['customer_id']"),
    (r"'depotCode'", "'customerCode'"),
    (r"'depotId'", "'customerId'"),
    (r"'depotNumber'", "'customerNumber'"),
]

for filepath in files_to_fix:
    if not os.path.exists(filepath):
        print(f"Skipping {filepath} (does not exist)")
        continue
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    original = content
    for pattern, repl in replacements:
        content = re.sub(pattern, repl, content)
        
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")
