# ASH SIS Automation

Automation plugins and scripts for ASH PowerSchool SIS.

## Overview

PowerSchool SIS generates reports on a schedule set in the Data Export Manager (*Functions > Importing & Exporting > Data Export Manager*). Reports are transmitted to an internal SSH host (see [internal documentation](https://drive.google.com/drive/folders/1JPArXP_7C58uMpqMbwHHK_5DDGpmmQw2)). 

Documents deposited on the SSH host are processed and forwarded on to the appropriate user groups with links to documentation and instructions particular to the document. All documents should only be mailed to google group addresses within the domain. Distribution lists are maintained exclusively through the google groups.


## Report setup

Report names need to be formatted as `destination_group-_-report_name.csv`. The `destination_group` must match a google group in the form of `destination_group_sis_reports@ash.nl`. The delimiter between the destination group and the report name must always be `-_-`. 
## Email setup

All outgoing emails will get `sis_textbody/default_body.txt` appended to the email.

Specific text will be added to outgoing email. 

## TO DO

- [ ] Set up sismailer user on SSH host
- [ ] Setup rrsync on SSH host
- [ ] Document SSH configuration
- [ ] Add automation scripts to sismailer
- [ ] Setup cron job for sis mailer
- [ ] Write standard, individual text for mailer
- [ ] Set up Google groups
- [ ] more robust parsing of the incoming report name delimiter using a regex

