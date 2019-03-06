BEGIN {
	RS="(\n|)From -"
	FS="[<>]"
	lastRT = ""
	idx = 1
	SUBJECTLEN = length("Subject: ")
}

# By default
{
	header = "Unknown type"
	body = "Unknown reason"
	author = ""
	mark = ""
	repo = ""
	for (i = 1; i < NF; ++i) {
		if(!author && $i ~ /author-name/) {
			author=$(i + 1)
			# Deal with Raphael's name
			gsub(/=C3=AB/, "e", author)
		}
		else if(!repo && match($i, /Subject: [^ ]+ -/)) {
			repo = substr($i, RSTART + SUBJECTLEN, RLENGTH - SUBJECTLEN - 2)
			header = substr($i, RSTART + RLENGTH + 1)
			gsub(/[[:blank:]]*\nContent-Type.*/, "", header)
			gsub(/\n/, "", header)
			header = gensub(/#[0-9]+:/, repo ":", 1, header)
		}
		# printf("--%s\n", $i)
	}
}

# do_exit == 1 { exit }

# /exfat/ {
# 	do_exit = 1
# }

# Process mails that are about marking a PR
# It is supposed to deal with (dis)approval and needs work
/marked the pull request as/ {

	match($0, /((UN)?APPROVED|NEEDS WORK)/)
	mark = substr($0, RSTART, RLENGTH)

	body = sprintf("%s marked PR as %s", author, mark)

	# print author
	# print mark
	# print repo
	# print header
	# print body
	# exit
	notif()
	next
}

# Process mails that are about joining as reviewer
/joined as a reviewer/ {
	body = sprintf("%s is now reviewing", author)
	notif()
	next
}

# Process mails that are about leaving as reviewer
/is no longer a reviewer/ {
	body = sprintf("%s is not reviewing anymore", author)
	notif()
	next
}

function notif() {
	print header
	print body
	print "=============="
}

{
	notif()
}

END {
}



# # Save the 3 lasts mails
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
# END {
# 	flush()
# }