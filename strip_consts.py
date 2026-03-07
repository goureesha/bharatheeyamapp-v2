import os
import re

for root, _, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Remove const from common widget classes that typically wrap our colors
            content = content.replace('const TextStyle', 'TextStyle')
            content = content.replace('const Icon', 'Icon')
            content = content.replace('const BoxDecoration', 'BoxDecoration')
            content = content.replace('const BorderSide', 'BorderSide')
            content = content.replace('const LinearGradient', 'LinearGradient')
            content = content.replace('const Divider', 'Divider')
            content = content.replace('const SectionTitle', 'SectionTitle')
            # Fix nested consts by removing const from parents as well
            content = content.replace('const Text', 'Text')
            content = content.replace('const Padding', 'Padding')
            content = content.replace('const Row', 'Row')
            content = content.replace('const Column', 'Column')
            content = content.replace('const Container', 'Container')
            content = content.replace('const Expanded', 'Expanded')
            content = content.replace('const Center', 'Center')

            with open(path, 'w', encoding='utf-8') as file:
                file.write(content)
print('Done stripping consts.')
