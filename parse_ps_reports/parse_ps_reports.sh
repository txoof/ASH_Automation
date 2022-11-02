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
logfile="/var/log/${SCRIPT}.$year_marker.log"

#
# ------------------------------------------------------------------------------------------------------------------------
#
# Jasper Kalkman & Aaron Ciuffo
#
# First attempt to create a Powerschool batch report mailer to google groups
#
# ------------------------------------------------------------------------------------------------------------------------
#


current_user=$( stat -f '%Su' /dev/console )
home=$( eval echo ~$current_user )

test_location="${home}/Desktop/csv_dummies"

sftp_location="${home}/Desktop/csv_dummies"

default_body_location="${home}/Desktop/default_body_location"

tmp_location="/private/tmp"

test_msg="The quick brown fox jumps over the lazy dog"

CSV_Check_list=(
	"yellow:YES"
	"green:YES"
	"brown:YES"
	"black:YES"
	"red:YES"
	"orange:YES"
)


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
 #	echo $(fHeader) "$message" >> "$logfile"
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
	array_csv=( ${sftp_location}/*.csv )
	
	for csv_file in $array_csv
	do
		name=$( basename $csv_file .csv )
		base_address=$( echo "${name}" | cut -d "-" -f 1 )
		email_address="${base_address}_SIS_Reports@ash.nl"
		File_name=$( echo "${name}" | cut -d "-" -f 3 )
		email_Body="Body_${File_name}.txt"
		Attachment="Attachment_${File_name}.txt"
		Info_Body="Info_${File_name}.txt"
		
		message_Log "Create the email body"

		if [[ -d "${default_body_location}/${Info_Body}" ]]; 
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
}


#
# ----------------------------------------------------------------------------------------------
#
message_Log " "

message_Log "Create ${test_location}"

mkdir -p "${test_location}"

message_Log " "

message_Log "Create test files"

Create_Dummy

message_Log " "

message_Log "parse_ps_reports"

parse_ps_reports

message_Log " "


exit 0
