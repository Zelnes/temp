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
		}
		# printf("--%s\n", $i)
	}
}

/marked the pull request as/ {

	match($0, /((UN)?APPROVED|NEEDS WORK)/)
	mark = substr($0, RSTART, RLENGTH)

	header = sprintf("Pull Request on %s", repo)
	body = sprintf("%s marked PR as %s", author, mark)

	# print author
	# print mark
	# print repo
	# print header
	# print body
	# exit
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