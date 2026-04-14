# Shared AWK utility functions.
# Include with: awk -f /path/to/awk-utils.awk -f your-script.awk

function count_char(str, ch,    i, n) {
	n = 0
	for (i = 1; i <= length(str); i++) {
		if (substr(str, i, 1) == ch) {
			n += 1
		}
	}
	return n
}
