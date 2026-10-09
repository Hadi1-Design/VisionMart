import os

target_dir = r'd:\FYP\vision_app\lib'
import_statement = "import 'package:vision_app/widgets/glass_widgets.dart';\n"

for root, _, files in os.walk(target_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Don't replace in glass_widgets.dart itself where the widget is defined!
            if 'GestureDetector(' in content and file != 'glass_widgets.dart':
                # Replace
                content = content.replace('GestureDetector(', 'AnimatedTouchable(')
                
                # Check for import
                if 'glass_widgets.dart' not in content:
                    # Find first import and insert after it
                    import_idx = content.find('import ')
                    if import_idx != -1:
                        end_of_line = content.find('\n', import_idx)
                        content = content[:end_of_line+1] + import_statement + content[end_of_line+1:]
                    else:
                        content = import_statement + content
                
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f'Updated {file}')
