

BEGIN {
	RS="(\n|)From -"
	FS="[<>]"
	SUBJECTLEN = length("Subject: ")
	if(!subject) {
		print "Error : subject must be given!"
		exit 1
	}
	initVars()
	# lastRT = ""
	# idx = 1
}

function initVars() {
	treated = 0 # Is the current record already treated
	header = "Unknown type"
	body = "Unknown reason"
	author = ""
	mark = ""
	repo = ""
}

function notif() {
	printf("%s__sep__%s\n", header, body)
}

$0 !~ subject {
	next
}

# do_exit == 1 { exit }

# By default
{
	initVars()
	for (i = 1; i <= NF; ++i) {
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

# /exfat/ {
# 	do_exit = 1
# }

# Process mails that are about marking a PR
# It is supposed to deal with (dis)approval and needs work
treated != 1 && /marked the pull request as/ {
	treated = 1

	match($0, /((UN)?APPROVED|NEEDS WORK)/)
	mark = substr($0, RSTART, RLENGTH)

	body = sprintf("%s marked PR as %s", author, mark)
}

# Process mails that are about joining as reviewer
treated != 1 && /joined as a reviewer/ {
	treated = 1
	body = sprintf("%s is now reviewing", author)
}

# Process mails that are about leaving as reviewer
treated != 1 && /is no longer a reviewer/ {
	treated = 1
	body = sprintf("%s is not reviewing anymore", author)
}

treated != 1 && /added a comment/ {
	treated = 1
	lookAuthor = 0
	body = sprintf("%s added a comment", author)
	for(i = 1; i <= NF; ++i) {
		if($i ~ /In reply to/) {
			lookAuthor = 1
			continue
		}
		if(lookAuthor == 1 && $i ~ /author-name/)
			{
			body = sprintf("%s replied to %s", author, $(i + 1))
			break
		}
	}
}

treated != 1 && /commented on line/ {
	treated = 1
	match($0, /commented on line.*<\/strong>/)
	s = substr($0, RSTART, RLENGTH)
	gsub(/<[^>]+>/, "", s)
	body = sprintf("%s %s", author, s)
}

treated != 1 && /MERGED/ {
	treated = 1
	body = sprintf("%s merged the PR", author)
}

treated != 1 && /LIKED/ {
	treated = 1
	match($0, /<b>[^<]+/)
	body = sprintf("%s liked your comment", substr($0, RSTART + 3, RLENGTH - 3))
}

treated != 1 && /DECLINED/ {
	treated = 1
	body = sprintf("%s declined the PR", author)
}

treated != 1 && /added you as a reviewer/ {
	treated = 1
	body = sprintf("%s created a PR with you as a reviewer", author)
}

treated != 1 && /pushed changes to/ {
	treated = 1
	body = sprintf("%s updated the PR", author)
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