import re

with open(r'D:\govardhan_thal\react_admin\src\components\OrdersManager.js', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start = 197 # OrderDetailsPanel
end = 560

inside_panel = lines[start:end]

open_divs = 0
close_divs = 0

with open(r'D:\govardhan_thal\react_admin\src\components\div_count.txt', 'w') as out:
    for i, line in enumerate(inside_panel):
        line_num = start + i + 1
        open_count = len(re.findall(r'<div', line))
        close_count = len(re.findall(r'</div', line))
        open_divs += open_count
        close_divs += close_count
        if open_count != 0 or close_count != 0:
            out.write(f"Line {line_num}: +{open_count} -{close_count} | Open: {open_divs} Close: {close_divs} | Diff: {open_divs - close_divs}\n")
    
    out.write(f"\nTotal open: {open_divs}, Total close: {close_divs}")
