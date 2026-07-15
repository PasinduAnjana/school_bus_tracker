import re

with open('lib/screens/driver/driver_home_page.dart', 'r') as f:
    content = f.read()

# Add import
if "import '../../widgets/slide_to_end.dart';" not in content:
    content = content.replace("import '../../widgets/squishy_button.dart';", "import '../../widgets/squishy_button.dart';\nimport '../../widgets/slide_to_end.dart';")

# Replace all _SlideToEnd with SlideToEnd
content = re.sub(r'\b_SlideToEnd\b', 'SlideToEnd', content)

# Remove the widget definition from the file (everything after class SlideToEnd extends StatefulWidget)
import_idx = content.find("class SlideToEnd extends StatefulWidget {")
if import_idx != -1:
    content = content[:import_idx]

with open('lib/screens/driver/driver_home_page.dart', 'w') as f:
    f.write(content)

