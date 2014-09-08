#!/bin/sh

#==========================================================
# ooxml2xml.sh
# Extract document.xml from Office Open XML file
#==========================================================

# set variables
PATH="$PATH:/usr/local/bin:$HOME/bin:." ; export PATH
progname="ooxml2xml.sh"

# check arguments
if [ $# -lt 1 ]
then
  printf '%s: usage: %s infile [outfile]\n' "$progname" "$progname" 1>&2
  exit 1
fi
infile="$1"
outfile="$2"
if [ -n "$ESTORIGFILE" ] && [ -f "$ESTORIGFILE" ]
then
  infile="$ESTORIGFILE"
fi

# check the input
if [ "!" -f "$infile" ]
then
  printf '%s: %s: no such file\n' "$progname" "$infile" 1>&2
  exit 1
fi

# initialize the output file
if [ -n "$outfile" ]
then
  rm -f "$outfile"
fi

# function to output
output(){
  if [ -n "$outfile" ]
  then
    cat >> "$outfile"
  else
    cat
  fi
# | /usr/bin/nkf -W -w8
}

# limit the resource
ulimit -v 262144 -t 10 2> "/dev/null"

# output the result
case "$infile" in
*.docx)
  /usr/bin/unzip -caq "$infile" \*/document.xml | output
  ;;
*.xlsx)
  /usr/bin/unzip -caq "$infile" \*/sharedStrings.xml | output
  ;;
*.pptx)
  /usr/bin/unzip -caq "$infile" \*/slide[0-9]*.xml | output
  ;;
*)
  printf '<div>!!! UNKNOWN FORMAT !!!</div>\n' | output
  ;;
esac

# exit normally
exit 0

# END OF FILE