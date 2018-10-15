# Awk script that handle the edition of file given as input for sed_script.sh

# The format follows these rules :
# The record separator is ;;
# Each record has 6 fields :
#  1 : The record name RCN
#  2 : LIST+="RCN "
#  3 : *_L the regex list
#  4 : *_C the regex color
#  5 : *_F the regex format
#  6 : *_LF the regex sed's flag

# This function returns the right part of the "=" sign
function after_equal(line) {
  return substr(line, 1 + index(line, "="))
}

# This function loads the given file and fills the next associative array :
# ADD for which each key is a record name
# For each record there are 4 fiels :
#  L  : the record regex
#  C  : the color
#  F  : the format
#  LF : the flags
# It also fills the list lADD with all the record names
function load_file(FN,  rs, fs, ladd, rn) {
  rs=RS; fs=FS
  RS="^"ARS"$"
  FS="\n"
  delete ADD
  delete LADD
  while(( getline <FN) > 0 ) {
    rn = substr($1, 3)
    print rn
    ADD[rn, "L"]  = after_equal($3)
    ADD[rn, "C"]  = after_equal($4)
    ADD[rn, "F"]  = after_equal($5)
    ADD[rn, "LF"] = after_equal($6)
    ladd=ladd rn SUBSEP
  }
  close(FN)
  RS=rs; FS=fs
  # Split returns the number of elements found. As there's an extra SUBSEP, we
  # don't need to keep the last LADD element, so we delete it on the fly
  delete LADD[split(ladd, LADD, SUBSEP)]
  if(DBG == 1) {
    print_all_from(ADD)
    print_all_from(LADD)
  }
}

function print_record(rn,  line) {
  line=line sprintf("%s_L=%s\n",  rn, ADD[rn, "L"])
  line=line sprintf("%s_C=%s\n",  rn, ADD[rn, "C"])
  line=line sprintf("%s_F=%s\n",  rn, ADD[rn, "F"])
  line=line sprintf("%s_LF=%s\n", rn, ADD[rn, "LF"])
  return line
}

function flush_to_file(FN,  k, a, line, e) {
  printf("") >FN
  for(k in LADD) {
    e = LADD[k]
    line=""
    line=line sprintf("# %s\n", e)
    line=line sprintf("LIST+=\"%s \"\n", e)
    line=line print_record(e)
    line=line sprintf("%s\n", ARS)
    # printf(line) >>FN
    printf(line)
  }
}

function print_all_from(a, k) {
  for (k in a)
    printf("%s : %s\n", k, a[k])
}

# This function will parse the given file and fill the next associative array :
# FMTS with keys Colors and Formats
function retrieve_available_fmts(FN,  rs, a, type, line, oline) {
  rs=RS
  RS="\n"
  delete FMTS
  while(( getline oline<FN) > 0 ) {
     if(oline ~ "[CF]_")
     {
       line=oline
       gsub("(readonly|=.*| +)", "", line)
       type=substr(line, 1, 1)
       value=substr(line, 3) " "
       if(type == "C")
        FMTS["Colors"] = FMTS["Colors"] " " value
      else if(type == "F")
        FMTS["Formats"] = FMTS["Formats"] " " value
      else
        printf("The following line is problematic : %s", oline);
     }
  }
  close(FN)
  gsub("(^ +| +$)", "", FMTS["Colors"])
  gsub("(^ +| +$)", "", FMTS["Formats"])
  if(DBG == 1) print_all_from(FMTS)
  RS=rs
}

function print_menu() {
  print "Available commands are :"
  print "\tq : Quit"
  print "\tl (color|format|record) : list what is given (empty for all)"
  print "\ta <Record_Name> : adds or updates (if exists) the given record"
  print ""
}

function menu_add(rn) {

}

function menu_list(action, rn) {
  switch(action) {
    case "":
      print_all_from(FMTS)
      print_all_from(LADD)
      break;
    case "color":
      printf("Colors : %s", FMTS["Colors"])
      break;
    case "format":
      printf("Formats : %s", FMTS["Formats"])
      break;
    case "record":
      if(length(rn) == 0)
        print_all_from(LADD)
      else {
        print print_record(rn)
      }
      break;
    default:
      print "Action given can't be satisfied ("action")"
  }
}

function main() {
  while(1) {
    print_menu()
    getline
    print NF
    switch($1) {
      case "q":
        exit
      case "l":
        menu_list($2, $3)
        break
    }
  }
}

BEGIN {
  # Additionnal Record Separator
  ARS="# ;;"
  DBG=1
  retrieve_available_fmts("format_list.sh")
  load_file("additionnal")
  flush_to_file("additionnal2")
  main()
}
END {
  print "fin"
}
