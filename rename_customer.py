import os
import re

directories = ['lib', 'docs', 'test', 'integration_test']

replacements = [
    (re.compile(r'Non Customer'), 'Non-BP Depot'),
    (re.compile(r'Non-Customer'), 'Non-BP Depot'),
    (re.compile(r'non_customer'), 'non_bp_depot'),
    (re.compile(r'non-customer'), 'non-bp-depot'),
    (re.compile(r'NonCustomer'), 'NonBpDepot'),
    (re.compile(r'nonCustomer'), 'nonBpDepot'),
    
    (re.compile(r'Customers'), 'Depots'),
    (re.compile(r'customers'), 'depots'),
    (re.compile(r'CUSTOMERS'), 'DEPOTS'),
    
    (re.compile(r'Customer'), 'Depot'),
    (re.compile(r'customer'), 'depot'),
    (re.compile(r'CUSTOMER'), 'DEPOT'),
]

def rename_paths():
    for d in directories:
        if not os.path.exists(d): continue
        for root, dirs, files in os.walk(d, topdown=False):
            for filename in files:
                new_filename = filename
                for pattern, repl in replacements:
                    new_filename = pattern.sub(repl, new_filename)
                if new_filename != filename:
                    old_path = os.path.join(root, filename)
                    new_path = os.path.join(root, new_filename)
                    os.rename(old_path, new_path)
                    print(f"Renamed file: {old_path} -> {new_path}")
            
            for dirname in dirs:
                new_dirname = dirname
                for pattern, repl in replacements:
                    new_dirname = pattern.sub(repl, new_dirname)
                if new_dirname != dirname:
                    old_path = os.path.join(root, dirname)
                    new_path = os.path.join(root, new_dirname)
                    os.rename(old_path, new_path)
                    print(f"Renamed dir: {old_path} -> {new_path}")

def replace_content():
    exts = ['.dart', '.md', '.yaml', '.json', '.txt', '.arb']
    for d in directories:
        if not os.path.exists(d): continue
        for root, dirs, files in os.walk(d):
            for filename in files:
                if any(filename.endswith(ext) for ext in exts):
                    filepath = os.path.join(root, filename)
                    with open(filepath, 'r', encoding='utf-8') as f:
                        try:
                            content = f.read()
                        except UnicodeDecodeError:
                            continue
                    
                    new_content = content
                    for pattern, repl in replacements:
                        new_content = pattern.sub(repl, new_content)
                    
                    if new_content != content:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        print(f"Updated content in: {filepath}")

rename_paths()
replace_content()
