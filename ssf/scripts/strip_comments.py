import os
import re
import tokenize
import io
import sys

def strip_python_comments(source):
    io_obj = io.BytesIO(source.encode('utf-8'))
    out = ""
    try:
        from tokenize import untokenize
        tokens = [t for t in tokenize.tokenize(io_obj.readline) if t.type != tokenize.COMMENT]
        return untokenize(tokens)
    except:
        return source

def strip_c_style_comments(source):
    pattern = r"(\".*?(?<!\\)\"|'.*?(?<!\\)')|(/\*.*?\*/|//[^\r\n]*$)"
    regex = re.compile(pattern, re.MULTILINE | re.DOTALL)
    
    def replacer(match):
        if match.group(1):
            return match.group(1)
        return ""
        
    return regex.sub(replacer, source)

def strip_html_comments(source):
    return re.sub(r"<!--[\s\S]*?-->", "", source)

def strip_shell_comments(source):
    lines = source.splitlines()
    out_lines = []
    for line in lines:
        if line.strip().startswith("#"):
            if line.startswith("#!"): 
                out_lines.append(line)
            continue
        out_lines.append(line) 
    return "\n".join(out_lines) + "\n"

def process_file(filepath):
    ext = os.path.splitext(filepath)[1].lower()
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except UnicodeDecodeError:
        return 
        
    new_content = None
    
    if ext == '.py':
        new_content = strip_python_comments(content)
    elif ext in ['.js', '.css', '.ts', '.jsx', '.tsx', '.c', '.cpp', '.h', '.java']:
        new_content = strip_c_style_comments(content)
    elif ext in ['.html', '.xml']:
        new_content = strip_html_comments(content)
    elif ext in ['.sh', '.bash', '.yml', '.yaml'] or filepath.endswith('Dockerfile'):
        new_content = strip_shell_comments(content)
        
    if new_content is not None and new_content != content:
        print(f"Stripped comments from {filepath}")
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)

def main():
    root_dir = "."
    if len(sys.argv) > 1:
        root_dir = sys.argv[1]
        
    ignore_dirs = {'.git', '.venv', 'node_modules', '__pycache__', 'dist', 'build'}
    
    for root, dirs, files in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in ignore_dirs]
        for file in files:
            process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
