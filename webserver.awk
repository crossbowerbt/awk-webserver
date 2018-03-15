@load "filefuncs"

BEGIN {

	#
	# HTTP separates lines by "\r\n"
	#

	RS = "\r\n"
	ORS = "\r\n"

	#
	# Finite machine statuses
	#

	status_request    = 1
	status_headers    = 2
	status_file_check = 3
	status_success    = 4

	current_status = status_request

	#
	# Response codes
	#

	code_ok = "200 Ok"
	code_bad_request = "400 Bad Request"
	code_file_not_found = "404 File Not Found"

	response_code = code_bad_request

	#
	# Global variables
	#

	request_method = ""
	request_filename = ""
	request_http_version = ""
	
	# request_headers[]
	# response_headers[]

	response_body = ""
	
}

current_status == status_request &&
/GET [^ ]+ HTTP/ {

	#
	# Read request line
	#

	request_method = $1
	
	request_filename = "./" $2 # prepend ./ for local file

	gsub(/\/\//, "/", request_filename) # replace double slashes
	gsub(/\/\.\./, "/", request_filename) # avoid directory trasversal

	request_http_version = $3	

	current_status = status_headers

	next

}

current_status == status_request &&
$0 !~ /GET [^ ]+ HTTP/ {

	#
	# Invalid request
	#

	response_code = code_bad_request
	response_body = response_code
	
	exit 1

}

current_status == status_headers &&
/[^:]+: .+/ {

	#
	# Read a single header
	#

	split($0, header, ": ")

	request_headers[header[1]] = header[2]

	next

}

current_status == status_headers &&
/^$/ {

	#
	# End of headers
	#

	current_status = status_file_check
	
}

current_status == status_headers {

	#
	# Invalid request header
	#

	response_code = code_bad_request
	response_body = response_code
	
	exit 1

}

current_status == status_file_check {

	#
	# Get info about requested file and
	# generate directory listing or file content
	#

	ret = stat(request_filename, stat_info)

	if (ret < 0) {
		response_code = code_file_not_found
		response_body = response_code
		exit 1
	}

	if (stat_info["type"] == "directory") {
		
		# Directory listing

		response_body = "<pre>"
		
		response_body = response_body "<strong>Index of " request_filename "</strong>\n"

		cmd = "ls -plh " request_filename

		prev_RS = RS		
		RS = "\n"

		while ( ( cmd | getline line ) > 0 ) {

			split(line, fields)
			
			response_body = response_body fields[5] "\t<a href=\""  fields[9] "\">" fields[9] "</a>\n"
		}
		
		close(cmd)

		RS = prev_RS

		response_body = response_body "</pre>"

		response_headers["Content-Length"] = length(response_body) ""
		
	}

	else if (stat_info["type"] == "file") {

		# File content

		response_headers["Content-Length"] = stat_info["size"] ""

		prev_RS = RS
		RS = "^$"
		
		cmd = "cat " request_filename
		
		cmd | getline response_body
		
		close(cmd)

		RS = prev_RS

	}

	else {
		respose_code = code_file_not_found
		response_body = response_code
		exit 1
	}

	current_status = status_success
	response_code = code_ok
	
	exit 0

}

END {

	#
	# Send back response
	#

	print "HTTP/1.1 " response_code

	for (header_name in response_headers) {
		print header_name ": " request_headers[header_name]
	}
		
	print

	# Response Body

	ORS=""

	print response_body
	
}
