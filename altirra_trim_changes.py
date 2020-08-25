import sys
import re
text = ''
while(None is not (line := sys.stdin.readline()) and line != ''):
	if(None is not re.search(r'hange..og', line)): continue
	if(None is re.match(r'^ *(.*AltirraOS|.*ATBasic|[^ \*])', line)): continue
	text += line

text = re.sub(r'\r\n', '\n', text)

text = re.sub(r'( *)(\[breaking changes\]|\[features added\]|\[changes\]|\[bugs fixed\]|\[bug fixes\])\s*(?=[^\*\s])', r'\1', text, flags=(re.S | re.M))
text = re.sub(r'Version[^\n]*\s*(?=V)', '', text, flags=re.S | re.M)
text = re.sub(r'Version[^\n]*\s*$', '', text, flags=re.S)
print(text.strip().rstrip())
