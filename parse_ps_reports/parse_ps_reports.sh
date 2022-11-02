#!/bin/zsh
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin
host=$( hostname )
setopt null_glob
autoload is-at-least

# Determine directory where this script is running from
parent_dir=$( /usr/bin/dirname "$0" )

SCRIPT_PATH="${0}"
SCRIPT=$( basename "${SCRIPT_PATH}" )

today_marker=$( date +%C%y%m%d )
year_marker=$( date +%C%y )

#
# ------------------------------------------------------------------------------------------------------------------------
#
# Jasper Kalkman & Aaron Ciuffo
#
# First attempt to create a Powerschool batch report mailer to google groups
#
# ------------------------------------------------------------------------------------------------------------------------
#

current_user="sismailer"
home=$( eval echo ~$current_user )


# Default logging locations
#
logfolder="${home}/sis_log"
logfile="${logfolder}/${SCRIPT}.$today_marker.log"

# Default sftp location for Powerschool
#
sftp_location="${home}/sis_incoming"

# Default attachement
#
body_text_location="${home}/sis_textbody"

# Default text body allways used
#
default_body_text="${body_text_location}/default_body.txt"



#
# ------------------------------------------------------------------------------------------------------------------------
#


# Echo function
message_Log () 
{
	message="${@}"
    
    # Date and Time function for the log file
    fDateTime () { echo $(date +"%a %b %d %T"); }

    # Title for beginning of line in log file
    Title="SIS Reports"

    # Header string function
    fHeader () { echo $(fDateTime) - $Title; }
 	echo $(fHeader) "$message" >> "$logfile"
 	echo $(fHeader) "$message" 
}


# ----------------------------------------------------------------------------------------------
#
function Create_Dummy()
{
	for csv_file in "${CSV_Check_list[@]}"; do
	
		ARRAY=("${(@s/:/)csv_file}")
		Test_file="$ARRAY[1]"
		email="$ARRAY[2]"
		message_Log "${test_msg} > ${test_location}/${Test_file}--Attachment_${Test_file}.csv"
		echo "${test_msg}" > "${test_location}/${Test_file}--Attachment_${Test_file}.csv"
	done
}


#
#
# ----------------------------------------------------------------------------------------------
#
function parse_ps_reports()
{	
	tmp_location=$( /usr/bin/mktemp -d $home/parse_ps_reports.XXXX )
	
	array_csv=( ${sftp_location}/*.csv )
	
	for csv_file in $array_csv
	do
		name=$( basename $csv_file .csv )
		base_address=$( echo "${name}" | cut -d "-" -f 1 )
		
		#
		# is formatted ....
		#
		email_address="${base_address}_SIS_Reports@ash.nl"
		
		#
		File_name=$( echo "${name}" | awk -F"-_-" '{print $2}' )
		
		# 
		email_Body="Body_${File_name}.txt"
		Attachment="Attachment_${File_name}.txt"
		Info_Body="Info_${File_name}.txt"
		
		message_Log "Create the email body"

		if [[ -e "${default_body_text}" ]]; 
		then
			message_Log "Append the default text text to this message"
			
			echo " " >>"${tmp_location}/${default_body_text}"
			
			cat "${default_body_text}" >>"${tmp_location}/${email_Body}"
			
			echo " " >>"${tmp_location}/${email_Body}"
		fi

		if [[ -e "${body_text_location}/${Info_Body}" ]]; 
		then
			message_Log "Append the info text to this message"
			
			echo " " >>"${tmp_location}/${email_Body}"
			
			cat "${default_body_location}/${Info_Body}" >>"${tmp_location}/${email_Body}"
			
			echo " " >>"${tmp_location}/${email_Body}"
		else
			
			echo " " >>"${tmp_location}/${email_Body}"
			
			echo "Please check the attached report ${File_name}" >"${tmp_location}/${email_Body}"
			
			echo " " >>"${tmp_location}/${email_Body}"
		fi
		
		message_Log "Create the attachment ${Attachment}"
		uuencode "${csv_file}"  "${tmp_location}/Attachment_${File_name}.csv" >"${tmp_location}/${Attachment}"
		
		message_Log "Append the attachment to this message"
		cat "${tmp_location}/${Attachment}" >>"${tmp_location}/${email_Body}"
		
		email_address="jkalkman@ash.nl"
		
		message_Log "Send message to ${email_address}"
		message_Log "${tmp_location}/${email_Body} | mail -s ${name} ${email_address}"
		
		cat "${tmp_location}/${email_Body}" | mail -s "${name}" "${email_address}"
	done
	
	rm -rfd "${tmp_location}"
}


#
# ----------------------------------------------------------------------------------------------
#

message_Log " "
message_Log "Make SIS support folders"

mkdir -p "${logfolder}"
mkdir -p "${sftp_location}"
mkdir -p "${body_text_location}"

#
# ----------------------------------------------------------------------------------------------
#

message_Log " "

message_Log "parse_ps_reports"

parse_ps_reports

message_Log " "

#
# ----------------------------------------------------------------------------------------------
#

exit 0
