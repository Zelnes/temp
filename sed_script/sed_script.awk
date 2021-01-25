# Awk script that handle the edition of file given as input for sed_script.sh

# The format follows these rules :
# The record separator is ;;
# Each record has 6 fields :
#  1 : The record name RCN
#  2 : LIST+="RCN "
#  3 : *_L the regex
#  4 : *_C the regex output color
#  5 : *_F the regex output format
#  6 : *_LF the regex sed's flag

# This function returns the right part of the "=" sign
function after_equal(line) {
  return substr(line, 1 + index(line, "="))
}

# This function loads the given file and fills the next associative array :
# ADD for which each key is a record name
# For each record there are 4 fields :
#  L  : the record regex
#  C  : the color
#  F  : the format
#  LF : the flags
# It also fills the list lADD with all the record names
function load_file(FN,  rs, fs, ladd, rn) {
  rs=RS; fs=FS
  RS=ARS
  FS="\n"
  delete ADD
  delete LADD
  while(( getline <FN) > 0 ) {
    rn = substr($1, 3)
    ADD[rn, "C"]  = after_equal($3)
    ADD[rn, "F"]  = after_equal($4)
    ADD[rn, "LF"] = after_equal($5)
    ladd=ladd rn SUBSEP
  }
  close(FN)
  # Split returns the number of elements found. As there's an extra SUBSEP, we
  # don't need to keep the last LADD element, so we delete it on the fly
  delete LADD[split(ladd, LADD, SUBSEP)]

  for(ladd in LADD)
  {
    rn = FN "." LADD[ladd]
    getline ADD[LADD[ladd], "L"] < rn
  }
  RS=rs; FS=fs
}

function print_record(rn,  line) {
  # gsub(/(^"|"$)/, "", ADD[rn, "L"])
  line=line sprintf("%s_L=\"%s\"\n",  rn, ADD[rn, "L"])
  line=line sprintf("%s_C=%s\n",  rn, ADD[rn, "C"])
  line=line sprintf("%s_F=%s\n",  rn, ADD[rn, "F"])
  line=line sprintf("%s_LF=%s\n", rn, ADD[rn, "LF"])
  return line
}

function print_all_record(  k) {
  for(k in LADD)
    print print_record(LADD[k])
}

function flush_to_file(FN,  k, a, line, e) {
  if(length(FN) == 0)
    FN = DAF

  "realpath " FN | getline FN

  for(k in LADD) {
    e = LADD[k]
    line=""
    line=line sprintf("# %s\n", e)
    line=line sprintf("LIST+=\"%s \"\n", e)
    line=line print_record(e)
    line=line sprintf("%s\n", ARS)
    printf(line) >>FN
  }
  close(FN)
  printf("Result written in %s !\n", FN)
}

function print_all_from(a,  k) {
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
       value=line " "
       if(type == "C")
        FMTS["Colors"] = FMTS["Colors"] " " value
      else if(type == "F")
        FMTS["Formats"] = FMTS["Formats"] " " value
      else
        printf("The following line is problematic : %s", oline);
     }
     else if(oline ~ "ADD_FILE") {
       DAF = after_equal(oline)
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
  print "\td <Record_Name> : deletes the given record"
  printf("\tcommit <file> : Commit all records to the file (default to '%s' if empty)", DAF)
  print ""
}

function register_new_element(rn, rg, sf, c, f) {
  ADD[rn, "L"]  = rg
  ADD[rn, "C"]  = c
  ADD[rn, "F"]  = f
  ADD[rn, "LF"] = sf
}

function get_from_uinput(what, rn, orig_val) {
  printf("%s for %s : ", what, rn)
  getline
  if(NF != 0)
    return $0
  else {
    if(length($0) > 0)
      return ""
    else
      return orig_val
  }
}

function menu_add(rn,  rg, sf, c, f, ae, is_ok, k) {
  if(length(rn) == 0) {
    printf("Please provide a name for the next record : ")
    getline rn
  }

  ae = 0
  for(k in LADD)
    if(LADD[k] ~ "\\<"rn"\\>") {
      ae = 1
      break;
    }

  if(ae == 1) {
    printf("Record '%s' already exists :\n", rn)
    print print_record(rn)
    print "Empty inputs will keep current values"
    print "Blank line resets the current value"
    rg = ADD[rn, "L"]
    c  = ADD[rn, "C"]
    f  = ADD[rn, "F"]
    sf = ADD[rn, "LF"]
  }
  else {
    printf("Regex can't be empty. Other fields will be considerate as default if omitted\n")
    LADD[length(LADD) + 1] = rn
  }

  is_ok = 0;
  do {
    printf("Regex for %s : ", rn); getline
    if(NF == 0) {
      is_ok = ae
    }
    else {
      rg = $0
      is_ok = 1
    }
  } while(!is_ok)

  sf = get_from_uinput("Sed Flags", rn, sf)
  print_all_from(FMTS)
  c = get_from_uinput("Color", rn, c)
  f = get_from_uinput("Format", rn, f)
  register_new_element(rn, rg, sf, c, f)
}

function menu_del(rn,  k) {
  if(length(rn) == 0) {
    printf("List of records deletable\n")
    print_all_from(LADD)
    printf("Please provide a name for the record to delete : ")
    getline rn
  }

  for(k = 1; k <= length(LADD); ++k) {
      if(LADD[k] == rn)
        break;
  }

  if(k > length(LADD)) {
    printf("The specified record doesn't exist!\n\n")
  }
  else {
    printf("Deleting record '%s'", rn)
    delete ADD[rn, "L"]
    delete ADD[rn, "C"]
    delete ADD[rn, "F"]
    delete ADD[rn, "LF"]
    delete LADD[k]
  }
}

function menu_list(action, rn,  k) {
  print "\n=================="
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
        print_all_record()
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
    if(getline == 0) exit;
    switch($1) {
      case "q":
        exit
      case "l":
        menu_list($2, $3)
        break
      case "a":
        menu_add($2)
        break
      case "d":
        menu_del($2)
        break
      case "commit":
        flush_to_file($2)
        break
    }
  }
}

BEGIN {
  # Additionnal Record Separator
  ARS=""
  # Default additionnal file
  DAF="regex_list.rgx"
  # DBG=1
  retrieve_available_fmts("format_list.sh")
  load_file(DAF)
  main()
}
END {
  flush_to_file(DAF ".bck")
  print "fin"
}
