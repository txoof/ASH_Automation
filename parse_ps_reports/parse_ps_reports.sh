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
#  Added dumy create  tool.
#
# configuration

# the `email_group_suffix` will be used whenever forwarding reports 
# see `Email Setup` in README.md
email_group_suffix="_sis_reports"


current_user="sismailer"
home=$( eval echo ~$current_user )
#home=$HOME


# Default logging locationtemporary files" s
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

report_archive="$home/old_reports"
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

#
# ----------------------------------------------------------------------------------------------

function fappend {
    echo "$2">>$1;
}

#
# ------------------------------------------------------------------------------------------------------------------------
#

CSV_Check_list=(
	"automation_testing-_-cities_2022.11.03:YES"
	"automation_testing-_-yellow_2022.11.03:YES"
	"automation_testing-_-green_2022.11.03:YES"
	"automation_testing-_-brown_2022.11.03:YES"
	"automation_testing-_-black_2022.11.03:YES"
	"automation_testing-_-red_2022.11.03:YES"
	"automation_testing-_-orange_2022.11.03:YES"
)

Dummy_Text="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

#
# ----------------------------------------------------------------------------------------------
#
function Create_Dummy()
{
	for csv_test in "${CSV_Check_list[@]}"; do
		ARRAY=("${(@s/:/)csv_test}")
		Test_csv_file="$ARRAY[1]"
		Check="$ARRAY[2]"
		message_Log "Creating ${Test_csv_file}.csv"
		# create csv filler
		for csv_file in "${CSV_Check_list[@]}"; do
			ARRAY=("${(@s/:/)csv_file}")
			Col1="$ARRAY[1]"
			Col2="$ARRAY[2]"
			echo "${Col1},${Col2}" >> "${sftp_location}/${Test_csv_file}.csv"
		done
	done
}


# ------------------------------------------------------------------------------------------------------------------------------------------------
#
function cmd_purge_reports()
{
	message_Log "Purging older reports"
	rm  ${report_archive}/*(Om[1,-25]) 2> /dev/null
}

#
#
# ----------------------------------------------------------------------------------------------
#
function parse_ps_reports()
{
	mk_tmp=$(which mktemp)
	#tmp_location=$( $mk_tmp -d $home/parse_ps_reports.XXXX )
	tmp_location=$( $mk_tmp -d )

	message_Log "Create temp directory: $tmp_location"

	array_csv=( ${sftp_location}/*.csv )

	for csv_file in $array_csv
	do
		name=$( basename $csv_file .csv )
		base_address=$( echo "${name}" | cut -d "-" -f 1 )

		#
		# is formatted ....
		#
		email_address="${base_address}${email_group_suffix}@ash.nl"

		#
		File_name=$( echo "${name}" | awk -F"-_-" '{print $2}' )

		#
		email_Body="Body_${File_name}.txt"
		Attachment="Attachment_${File_name}.csv"

		# append this text to every outgoing email that matches the base address
		Info_Body="${base_address}.txt"

		message_Log "Create the email body"

		if [[ -e "${default_body_text}" ]]; 
		then
			message_Log "Append the default text to this message"

			echo " " >>"${tmp_location}/${email_Body}"

			cat "${default_body_text}" >>"${tmp_location}/${email_Body}"

			echo " " >>"${tmp_location}/${email_Body}"
		fi

		message_Log "Checking for additional body text in $body_text_location/$Info_Body"
		if [[ -e "${body_text_location}/${Info_Body}" ]]; 
		then
			message_Log "Append the info text to this message"
			message_Log "$Info_Body"

			echo " " >>"${tmp_location}/${email_Body}"

                        cat "${body_text_location}/${Info_Body}" >>"${tmp_location}/${email_Body}"

			echo " " >>"${tmp_location}/${email_Body}"
		else
			message_Log "No additional body text found"

			echo " " >>"${tmp_location}/${email_Body}"

			echo "Please check the report ${File_name}" >>"${tmp_location}/${email_Body}"

			echo " " >>"${tmp_location}/${email_Body}"
		fi

		message_Log "uuencode and create the attachment ${Attachment}"

		uuencode  "${csv_file}"  "${tmp_location}/Attachment_${File_name}.csv" >>"${tmp_location}/${Attachment}"

		message_Log "Append the attachment to this message with header"

		cat "${tmp_location}/${Attachment}" >>"${tmp_location}/${email_Body}"

		#email_address="jkalkman@ash.nl"
		#email_address="aciuffo@ash.nl"

		message_Log "Send message to ${email_address}"
		message_Log "${tmp_location}/${email_Body} | mail -s ${name} ${email_address}"

		cat "${tmp_location}/${email_Body}" | mail -s "${name}" "${email_address}"

		# archive reports
		message_Log "Archiving report $csv_file in $report_archive"

		mv $csv_file $report_archive
	done

	message_Log "Cleaning up temporary files"
	rm -rfd "${tmp_location}"
}


#
#
# ----------------------------------------------------------------------------------------------
# Use the sendmail binary
#
function parse_ps_reports_sendmail()
{
	message_Log "--"
	mk_tmp=$(which mktemp)
	#tmp_location=$( $mk_tmp -d $home/parse_ps_reports.XXXX )
	tmp_location=$( $mk_tmp -d )

	array_csv=( ${sftp_location}/*.csv )

	for csv_file in $array_csv
	do
		message_Log "Check if the report has 2 or more lines"
		LineCount=$( awk '{c++};END{print c}' < "${csv_file}" )
		if [[ $LineCount -gt 1 ]] ; 
		then
			name=$( basename $csv_file .csv )
			base_address=$( echo "${name}" | cut -d "-" -f 1 )

			message_Log "SIS Mailer - ${name}"
			#
			# email is formatted as ....
			#
			email_address="${base_address}${email_group_suffix}@ash.nl"

			#
			File_name=$( echo "${name}" | awk -F"-_-" '{print $2}' )

			#
			email_Body="Body_${File_name}.txt"
			Attachment="Attachment_${File_name}.txt"
			Info_Body="${body_text_location}/${base_address}.txt"

			message_Log "Create the email body"

			message_Log  "First insert special instructions for this report."
			if [[ -e "${Info_Body}" ]];
			then
				message_Log "Append the info text to this message - ${Info_Body}"

				echo " " >>"${tmp_location}/${email_Body}"
                                echo "----------------------------------------------------------------------------------------------------------------" >>"${tmp_location}/${email_Body}"
                                echo " " >>"${tmp_location}/${email_Body}"

				cat "${default_body_location}/${Info_Body}" >>"${tmp_location}/${email_Body}"

				echo " " >>"${tmp_location}/${email_Body}"
			else
                                message_Log "No instructions found, missing text in  - ${Info_Body}"

				echo " " >>"${tmp_location}/${email_Body}"

				echo "Please check the attached report ${File_name}" >>"${tmp_location}/${email_Body}"

				echo " " >>"${tmp_location}/${email_Body}"
			fi

                        message_Log "Second insert defaul text into email body."
                        if [[ -e "${default_body_text}" ]];
                        then
                                message_Log "Append the default text text to this message  - ${default_body_text}"

                                echo " " >>"${tmp_location}/${email_Body}"
                                echo "----------------------------------------------------------------------------------------------------------------" >>"${tmp_location}/${email_Body}"
                                echo " " >>"${tmp_location}/${email_Body}"

                                cat "${default_body_text}" >>"${tmp_location}/${email_Body}"

                                echo " " >>"${tmp_location}/${email_Body}"
                        fi

                        echo "----------------------------------------------------------------------------------------------------------------" >>"${tmp_location}/${email_Body}"
                        echo " " >>"${tmp_location}/${email_Body}"

			message_Log "Building message to ${email_address}"

			# CHANGE THESE
			YYYYMMDD=$( date +%Y%m%d )
			TOEMAIL="${email_address}";
			FREMAIL="sismailer@ash.nl";
			SUBJECT="SIS Mailer - ${name} - $YYYYMMDD";

			message_Log "Add message body"
			MSGBODY=$( cat "${tmp_location}/${email_Body}" );

			ATTACHMENT="${csv_file}"

			# DON'T CHANGE ANYTHING BELOW
			TMP="${tmp_location}/${email_Body}"
			BOUNDARY=$( date +%s|md5sum )
			BOUNDARY=${BOUNDARY:0:32}
			FILENAME=$( echo "${name}" | awk -F"-_-" '{print $2}' )
			FILENAME="${FILENAME}.csv"

			message_Log "Build message attachment ${ATTACHMENT} with file name ${FILENAME}"
			TMPATTACH="${tmp_location}/ATTACH_${FILENAME}.csv"
			rm -rf "${TMPATTACH}";
			cat $ATTACHMENT | uuencode --base64 $FILENAME>"${TMPATTACH}";
			sed -i -e '1,1d' -e '$d' "${TMP}"; # removes first & last lines from "${TMP}"
			DATA=$( cat "${TMPATTACH}" )

			rm -rf "${TMP}";

			message_Log "Construct message mime"
			fappend "${TMP}" "From: $FREMAIL";
			fappend "${TMP}" "To: $TOEMAIL";
			fappend "${TMP}" "Reply-To: $FREMAIL";
			fappend "${TMP}" "Subject: $SUBJECT";
			fappend "${TMP}" "Content-Type: multipart/mixed; boundary=\""$BOUNDARY"\"";
			fappend "${TMP}" "";
			fappend "${TMP}" "This is a MIME formatted message.  If you see this text it means that your";
			fappend "${TMP}" "email software does not support MIME formatted messages.";
			fappend "${TMP}" "";
			fappend "${TMP}" "--$BOUNDARY";
			fappend "${TMP}" "Content-Type: text/plain; charset=ISO-8859-1; format=flowed";
			fappend "${TMP}" "Content-Transfer-Encoding: 7bit";
			fappend "${TMP}" "Content-Disposition: inline";
			fappend "${TMP}" "";
			fappend "${TMP}" "$MSGBODY";
			fappend "${TMP}" "";
			fappend "${TMP}" "";
			fappend "${TMP}" "--$BOUNDARY";
			fappend "${TMP}" "Content-Type: text/plain; name=\"$FILENAME\"";
			fappend "${TMP}" "Content-Transfer-Encoding: base64";
			fappend "${TMP}" "Content-Disposition: attachment; filename=\"$FILENAME\";";
			fappend "${TMP}" "";
			fappend "${TMP}" "$DATA";
			fappend "${TMP}" "";
			fappend "${TMP}" "";
			fappend "${TMP}" "--$BOUNDARY--";
			fappend "${TMP}" "";
			fappend "${TMP}" "";

			#cat "${TMP}">out.txt

			message_Log "Send message to ${email_address} using sendmail"
			cat "${TMP}" | sendmail -t;

			rm "${TMP}";

	                # archive reports
        	        message_Log "Archiving report $csv_file in $report_archive"

                	mv $csv_file $report_archive

			message_Log "--"
		else
			message_Log "Report ${csv_file} contains no content."
		fi
	done
	rm -rfd "${tmp_location}"
}


#
# ----------------------------------------------------------------------------------------------
#
sec_start=$( date +%s )

message_Log " "
message_Log "Make SIS support folders"

mkdir -p "${logfolder}"
mkdir -p "${sftp_location}"
mkdir -p "${body_text_location}"
mkdir -p "${report_archive}"

message_Log " "

message_Log "parse_ps_reports"

# uncomment this one for testing:
#Create_Dummy

# parse_ps_reports
parse_ps_reports_sendmail

message_Log " "

sec_end=$( date +%s )
sec_total=$(( sec_end  -  sec_start  ))
if [[ sec_total -gt 59 ]]; 
then
    	message_Log   "Finished processing reports in $(( (sec_end - sec_start + 30 ) / 60  )) Minutes"
else
	message_Log   "Finished processing reports in $(( sec_end - sec_start  )) Seconds"
fi

#
# ----------------------------------------------------------------------------------------------
#

exit 0
