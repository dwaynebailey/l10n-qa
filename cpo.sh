#!/bin/bash
INSTALLDIR=${HOME}/seal/l10n-qa
TMPFILE=`mktemp`
TMPFILE2=`mktemp`

dekde()
{
sed '
s/^msgid "[A-Za-z][A-Za-z]*=\([^"]\)/msgid "\1/
s/^msgstr "[A-Za-z][A-Za-z]*=\([^"]\)/msgstr "\1/
s/[&~]\([^"]\)/\1/g
/^msgid "[A-Za-z]/s/[^a-zA-Z"]*"$/"/
/^msgstr "[A-Za-z]/s/[^a-zA-Z"]*"$/"/
/^msg/y/ABCDEFGHIJKLMNOPQRSTUVWXYZÁÉÍÓÚ/abcdefghijklmnopqrstuvwxyzáéíóú/
'
}

if [ $1 = "-q" ]
then
	QUIET="true"
	shift
else
	QUIET="false"
fi
for x in $@
do
	# Does it compile with PO tools?
	echo "${x} á sheiceáil le msgfmt..."
	if ! msgfmt -c -v -o /dev/null --statistics "${x}" 2>&1
	then
		echo "Á Thobscor..."
		exit 1
	fi
	if [ $QUIET = "false" ]
	then
		# Look for bad shortcut keys
		echo "Drochaicearraí á lorg..."
		LC_ALL=C egrep '^msgstr.*[~&][^a-zA-Z0-9]' "${x}"
		# Look for the same msgid translated multiple different ways
		echo "Aistriúcháin fhíorchosúla á lorg..."
		cat "${x}" | dekde > $TMPFILE
		msguniq --repeated $TMPFILE > $TMPFILE2
		msgattrib --only-fuzzy "$TMPFILE2"
		# look for use of deprecated terms
		echo "Téarmaí lochtacha á lorg..."
		msgcat -t utf-8 "${x}" | sed '1,/^$/d' > $TMPFILE
		perl ${INSTALLDIR}/deprec.pl "${TMPFILE}"
		# look for ambiguous English terms in source strings
		perl ${INSTALLDIR}/amb.pl "${TMPFILE}"
		cp -f ${HOME}/.neamhshuim ${HOME}/.neamhshuim.bak
		# look for untranslatables
		echo "Téarmaí gan aistriú á seiceáil..."
		copycheck.pl "${TMPFILE}"
		cat ${INSTALLDIR}/po-ok.txt | iconv -f utf8 -t iso-8859-1 > ${HOME}/.neamhshuim
		# don't want nbsp's usually (creep in with some keyboards)
		echo "nbsp's á lorg..."
		egrep ' ' "${TMPFILE}"
		# spelling and grammar check
		echo "An Gramadóir..."
		bash ${INSTALLDIR}/msgstrs.sh $TMPFILE | sed 's/^$/./' | perl -I ${HOME}/gaeilge/gramadoir/gr/ga/Lingua-GA-Gramadoir/lib ${HOME}/gaeilge/gramadoir/gr/ga/Lingua-GA-Gramadoir/scripts/gram-ga.pl --ionchod=utf8
		cp -f ${HOME}/.neamhshuim.bak ${HOME}/.neamhshuim
	fi
done
rm -f $TMPFILE $TMPFILE2
exit 0
