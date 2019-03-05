BEGIN {
	RS="(\n|)From -"
	lastRT = ""
	idx = 1
}

match($0, "marked the pull request as") != 0 {
	found = RSTART + RLENGTH
	match(substr($0, found), /[[:alnum:]]+/)
	print "Review on PR " substr($0, found - 1 + RSTART, RLENGTH)
}

END {
}



# Save the 3 lasts mails
# lastRT != "" {
# 	save[idx++] = lastRT $0
# 	if(idx == 4) {
# 		idx = 1
# 	}
# }
# {
# 	lastRT = RT
# }
# function flush() {
# 	for(i = 1; i <= 3; ++i)
# 		print save[i]
# }