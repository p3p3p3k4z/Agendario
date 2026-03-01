import glob, re

def fix():
    files = glob.glob('lib/**/*.dart', recursive=True)
    for f in files:
        if "app_colors.dart" in f or "theme_provider.dart" in f:
            continue
            
        with open(f, 'r') as file:
            c = file.read()
            
        # Context theme fixes
        
        # 1. TextStyles
        c = re.sub(r'TextStyle\(([^)]*)color:\s*context\.theme\.bg0', r'TextStyle(\1color: context.theme.fg0', c)
        c = re.sub(r'TextStyle\(([^)]*)color:\s*context\.theme\.bg1', r'TextStyle(\1color: context.theme.fg1', c)
        
        # 2. Icons
        c = re.sub(r'Icon\(([^)]*)color:\s*context\.theme\.bg0', r'Icon(\1color: context.theme.fg0', c)
        c = re.sub(r'Icon\(([^)]*)color:\s*context\.theme\.bg1', r'Icon(\1color: context.theme.fg1', c)
        c = re.sub(r'IconThemeData\(color:\s*context\.theme\.bg0', r'IconThemeData(color: context.theme.fg0', c)
        
        # 3. Direct Markdown / Buttons Text coloring fixing missing context from the simple search
        c = c.replace("color: context.theme.bg0", "color: context.theme.fg0")
        
        # Fix back situations where bg0/bg1 were actually background colors (Scaffold, Containers)
        # We restore `backgroundColor: context.theme.fg0` to `backgroundColor: context.theme.bg0`
        c = c.replace("backgroundColor: context.theme.fg0", "backgroundColor: context.theme.bg0")
        c = c.replace("scaffoldBackgroundColor: context.theme.fg0", "scaffoldBackgroundColor: context.theme.bg0")
        
        with open(f, 'w') as file:
            file.write(c)

fix()
