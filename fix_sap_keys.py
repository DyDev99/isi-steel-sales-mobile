import re
import os

files_to_fix = [
    'lib/features/depots/data/models/business_partner_request_model.dart',
    'lib/features/depots/data/models/business_partner_response_model.dart'
]

replacements = [
    (r"s\('DepotNumber'\)", "s('CustomerNumber')"),
    (r"s\('DepotGroup'\)", "s('CustomerGroup')"),
    (r"'DepotNumber':", "'CustomerNumber':"),
    (r"'DepotGroup':", "'CustomerGroup':"),
    (r"json\['depotNumber'\]", "json['customerNumber']"),
    (r"json\['depotCode'\]", "json['customerCode']"),
    (r"json\['depotId'\]", "json['customerId']"),
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
