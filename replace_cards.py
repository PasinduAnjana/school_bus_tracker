import os

files_to_update = {
    'lib/screens/admin/drivers_tab.dart': "../../widgets/frosted_card.dart",
    'lib/screens/admin/payments_tab.dart': "../../widgets/frosted_card.dart",
    'lib/screens/admin/route_detail_screen.dart': None,
    'lib/screens/admin/routes_tab.dart': "../../widgets/frosted_card.dart",
    'lib/screens/admin/users_tab.dart': "../../widgets/frosted_card.dart",
    'lib/screens/driver/driver_stops_page.dart': None,
    'lib/screens/parent/parent_halts_page.dart': None,
    'lib/screens/profile_screen.dart': "../widgets/frosted_card.dart",
    'lib/widgets/live_map_view.dart': None,
}

for filepath, import_path in files_to_update.items():
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace Card( with FrostedCard(
    content = content.replace(" Card(", " FrostedCard(")
    content = content.replace("Card(", "FrostedCard(")
    content = content.replace("const FrostedCard(", "FrostedCard(")

    # Add import if needed
    if import_path and "frosted_card.dart" not in content:
        # Find the last import and insert after it
        lines = content.split('\n')
        last_import_idx = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                last_import_idx = i
        
        lines.insert(last_import_idx + 1, f"import '{import_path}';")
        content = '\n'.join(lines)

    with open(filepath, 'w') as f:
        f.write(content)

print("Done")
