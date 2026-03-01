import os, re
import glob

def refactor():
    files = glob.glob('lib/**/*.dart', recursive=True)
    for f in files:
        with open(f, 'r') as file:
            content = file.read()
            
        orig = content
        # Fix imports
        content = content.replace("import '../config/theme.dart';", "import '../providers/theme_provider.dart';")
        content = content.replace("import '../../config/theme.dart';", "import '../../providers/theme_provider.dart';")
        content = content.replace("import 'config/theme.dart';", "import 'providers/theme_provider.dart';")
        
        # Replace colors
        content = content.replace("GruvboxColors.bg_soft", "context.theme.bgSoft")
        content = re.sub(r'GruvboxColors\.([a-zA-Z0-9_]+)', r'context.theme.\1', content)
        
        # Remove const from all widget instantiations so that context.theme doesn't break due to invalid const contexts.
        # We will let `dart fix --apply` reconstruct the valid consts later.
        content = re.sub(r'\bconst\s+([A-Z][a-zA-Z0-9_]*\s*\()', r'\1', content)
        
        if orig != content:
            with open(f, 'w') as file:
                file.write(content)
            print(f"Refactored: {f}")

refactor()
