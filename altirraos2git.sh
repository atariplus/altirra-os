#!/bin/sh
# assemble AltirraOS repo from Altirra archives.

IN=$HOME/altirra-archives/
OUT=/tmp/altirra-os/
script_dir="$(cd $(dirname $0); pwd)"

[ -n "$OUT" ] || exit 1

mkdir -p "$OUT"
for file in "$IN"/Altirra-*.* ; do
	echo "$file"
	[ -d "$OUT"/.git ] || ( cd "$OUT"; git init . )
	( rm -rf "$OUT"/* ; cd "$OUT" ; git rm -rf . )
	( cd "$OUT"; 7z x $file || unzip -o $file; \
	 chmod a+r,a+X,u+w -R .; \
	 dos2unix -k Copying  src/Altirra/res/changes.txt; \
	 python3 $script_dir/altirra_trim_changes.py < src/Altirra/res/changes.txt > changes.txt; \
	 touch -r src/Altirra/res/changes.txt changes.txt; \
	 mv src/atbasic/* src/ATBasic/; \
	 mv src/ATBasic/makefile src/ATBasic/Makefile; \
	 mv src/Kernel/source/shared/* src/Kernel/shared/; \
	 mkdir -p src1; \
	 mv src/Kernel src/ATCompiler src/ATBasic src1; \
	 rm -rf {README.txt,README.html,testdata,assets,dist,release.py,scripts,localconfig,out,release.cmd,src}; \
	 mv src1 src; \
	 dos2unix -k `find . -name '*.txt' -o -name '*.inc' -o -name '*.s' -o -name Makefile -o -name '*.xasm'`; \
	 $script_dir/sed-p `find . -name '*.txt' -o -name '*.inc' -o -name '*.s' -o -name Makefile -o -name '*.xasm'`; \
	pwd ; \
	 sed 's:\\\([^\]\):/\1:g' < src/Kernel/Makefile > m ; touch -r src/Kernel/Makefile m; mv m src/Kernel/Makefile ; \
	 sed 's:\\\([^\]\):/\1:g' < src/ATBasic/Makefile > m ; touch -r src/ATBasic/Makefile m; mv m src/ATBasic/Makefile ; \
	 osversion="$(cat "$(find . -name version.inc)" | grep 'dta.*"' | sed 's:^[^"]*"::g' | sed 's:".*::g')"; \
	 fileversion=`basename $file | sed 's:^[^-]*-::g' | sed 's:-[^-]*$::g'`; \
	 comment="Altirra/AltirraOS release $fileversion"; \
	 comment2="$(cat changes.txt | sed -n "/Version $fileversion/,/Version/p"  | grep -v '^Version' | sed 's:^  *::g' | grep '[^ ]')"; \
	 [ -z "$osversion" ] || comment="AltirraOS release $osversion ( Altirra $fileversion )"; \
	 git add .; date=`find . -type f -printf '%TY-%Tm-%TdT%TT %p\n' |sort | grep -v ' \./\.git/' | tail -1 | cut -d' ' -f 1 | sed 's:T: :g'`;  GIT_COMMITTER_EMAIL=@ GIT_COMMITTER_NAME="Avery Lee" GIT_COMMITTER_DATE="$date" git commit --author 'Avery Lee <@>' -a --date "$date" -m "$comment" -m "$comment2") ; done
