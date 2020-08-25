#!/usr/bin/env python3
# apply makefile portability adustments

import re
import sys
import os

if len(sys.argv) < 2:
	print(f"usage: {sys.argv[0]} Makefile)")
	sys.exit(0)

def wincopycat2cat(m):
	return '$(CAT) ' + ' '.join(m[1].split('+')) + ' > ' + m[2]

for file in sys.argv[1:]:
	if(not os.path.exists(file)):
		filetarget = os.path.basename(os.path.dirname(file)).lower()
		f = open(sys.argv[1], 'w')
		f.write(f"""ifdef COMSPEC
MKDIR=md
else
MKDIR=mkdir -p
CXXFLAGS := -DVDCDECL= -std=c++20
endif
CXXFLAGS += -Ih

OUT ?= ../../out/Release

SOURCE := $(wildcard source/*.cpp)

$(OUT)/{filetarget}:: $(OUT)

$(OUT)/{filetarget}:: $(SOURCE)
	$(CXX) $(CXXFLAGS) -o $@ $^

$(OUT):
	$(MKDIR) $@
""")
		f.close()
		continue


	f = open(file, 'r+')

	text = f.read()
	if 0 <= text.find('ifdef COMSPEC'):
		print('Makefile already adjusted')
		f.close()
		continue

	text = re.sub(r'\r\n', '\n', text)
	text = re.sub(r'\\(?=[^\n])', '/', text)
	text = re.sub(r'for %%x in \( *([^ ]+) *\) do (.*) %~fx', r'\2 \1', text)
	text = re.sub(r'for %x in \( *([^ ]+) *\) do (.*) "%~fx"', r'\2 \1', text)

	text = re.sub(r'\bwhere\b  *([^ ]+)  *(?:/q)  *', r'$(WHICH) \1 ', text)

	text = re.sub(r'  *1>nul\b', '', text)
	text = re.sub(r'  *2>nul\b', '', text)
	text = re.sub(r'copy /b  *(.*) ([^ ]+)', wincopycat2cat, text)

	text = re.sub(r'\bcopy\b(.*)  */y', r'$(CP)\1', text)
	text = re.sub(r'\bcopy\b', r'$(CP)', text)
	text = re.sub(r'\bdel\b', r'$(RM)', text)
	text = re.sub(r'\bmd\b', r'$(MKDIR)', text)
	text = re.sub(r'\bexit /b\b', r'$(EXIT)', text)

	text = re.sub(r'\bif exist\b  *([^ ]+)  *', r'$(IF_EXISTS) \1 $(THEN) ', text)
	text = re.sub(r'\bif not exist\b  *([^ ]+)  *', r'$(IF_NOT_EXISTS) \1 $(THEN) ', text)
	text = re.sub(r'\bmakefile\b', 'Makefile', text)
	text = re.sub(r'\becho\.', 'echo .', text)
	text = re.sub(r'(\$\$\S+)', r"'\1'", text)
	text = re.sub(r'\bnokernel(?=/)', 'NoKernel', text)
	text = re.sub(r'\bsuperkernel(?=/)', 'SuperKernel', text)
	text = re.sub(r'\bnocartridge(?=/)', 'NoCartridge', text)
	text = re.sub(r'\bnogame(?=/)', 'NoGame', text)
	text = re.sub(r'\bbootsector(?=[\./])\b', 'BootSector', text)
	text = re.sub(r'\bsource/shared\b', 'source/Shared', text)
	text = re.sub(r'\bsource/basic\b', 'source/BASIC', text)
	text = re.sub(r'\bsource/ultimate\b', 'source/Ultimate', text)
	text = re.sub(r'  *"\$\(ATCOMPILER\)"$', '', text, flags=re.M)
	text = re.sub(r'  *\$\(ATCOMPILER\)$', '', text, flags=re.M)
	text = re.sub(r'\.exe\b', '', text)
#	text = re.sub(r'(\$\(IF_NOT_EXISTS\) "\$\(ATCOMPILER\)" \$\(THEN\) )(.*)', r'\1 (($(WHICH) "$(ATCOMPILER)") || \2)', text, flags=re.M)

	f.seek(0)

	f.write("""ifdef COMSPEC
 RM ?= del
 CP ?= copy /y
 MKDIR ?= md
 CAT ?= type
 EXIT ?= exit /b
 WHICH ?= where /q
 IF_EXISTS = if exists
 IF_NOT_EXISTS = if not exist
 THEN =
else
 RM ?= rm -f
 CP ?= cp
 MKDIR ?= mkdir
 CAT ?= cat
 EXIT ?= exit
 WHICH ?= which
 IF_EXISTS = ! test -e
 IF_NOT_EXISTS = test -e
 THEN = ||
endif

INT ?= internal
OUT ?= ../../out/Release
MADS ?= mads
""")

	f.write(text)
	f.truncate()
	f.close()
