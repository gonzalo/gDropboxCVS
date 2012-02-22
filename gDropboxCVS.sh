#!/bin/bash

# gDropboxCVS v0.1 
# distributed under GPL v3.0 http://www.gnu.org/copyleft/gpl.html 
# You are free to coppy, distribute, modify, bla, bla, bla...(you know all that stuff)
#
# gDropboxCVS it's a simple script to use in combination with a Dropbox account to have 
# a minimalistic control version system for anyone with a Gnome Desktop. gDropbox it's perfect
# for individual projects or shared with only few people.
# 
# Usage sample:
# Mike is a developer whom uses two computers and he would like to keep a project syncronized
# between both. He could use a dropbox folder directly but he doesn't want to upload each change,
# only when he is sure wants to push the changes to other computer. 
# 
# So, after working on his project, Mike launches gDropboxCVS and select "upload changes to dropbox"
# the software syncronizes development and dropbox folder (just modified files). Later, at home, Mike launches gDropboxCVS
# and selects "download changes".
#
# If Mike wants to restore some file he can just look for it in his dropbox folder and overwrite the modified.
# He some changes are pushed he could go to Dropbox webinterface and look up for the desired version 
# 


# INSTALL
# 0. gDropboxCVS needs zenity in order to work. 
#    To install zenity in ubuntu: $sudo apt-get install zenity
# 1. Be sure your Dropbox folder is correctly configured and active
# 2. Create a "cvs" folder under your Dropbox folder (you can choose other name).
# 3. (optional) Edit this file and specify your svn folder, local folder and project nome
#    so you won't need to specify them each run.

# Hint: Put this script under cvs folder and you can use the same config in all computers

# USAGE
# Just run gDropboxCVS clicking on it and follow the instructions


# CONFIG

DROPBOX_CVS_FOLDER='/home/user/Dropbox/cvs'
LOCAL_FOLDER='/home/user/Documents/my_project'
PROJECT_NAME='MyProject'
SECURE_MODE="off" #"on" generates a compressed backup under cvs/backups/[PROJECT_NAME].tgz

# CONFIGURATION SAMPLE
# Imagine that your project it's under '/home/user/Documents/workspace/my_project'
# and your CVS folder is under '/home/user/Dropbox/cvs' and you want to keep a backup copy
# then your config could be:
#
# DROPBOX_CVS_FOLDER='/home/user/Dropbox/cvs'
# LOCAL_FOLDER='/home/user/Documents/workspace/my_project'
# PROJECT_NAME='MyProject'
# SECURE_MODE="on"


# Advanced config

# Fix permissions
# If "on" adds www-data group write permissions to $LOCAL_FOLDER. You must insert sudo password.
# Usefull for local web developers
FIX_PERMISSIONS="off"


# END OF CONFIG


#beggining

#Ask the user what he want to do
operation=$(zenity --list \
                   --title="Menu" \
                   --text="Welcome to gDropboxCVS\n\nPlease, choose an operation"  \
                   --column="Option" "Upload project to Dropbox cvs folder" "Dowload project to local folder" \
                   --width 350 \
                   --height 200 \
           )

if [ "$operation" != "" ]; then
	#check if default parameters are correct
	option=$(zenity --question   \
                        --title="gDropboxCVS" \
                        --text="gDropboxCVS default parameters:\n\n[PROJECT_NAME] = $PROJECT_NAME\n[LOCAL_FOLDER] = $LOCAL_FOLDER\n[DROPBOX_CVS_FOLDER] = $DROPBOX_CVS_FOLDER\n\nDo you want to use this settings?" \
                        --width 600 \
                )


	#if user doesn't want to use default parameters then he has to input value manually
	if [ $? = 1 ]; then
	
		zenity --info --title="gDropboxCVS" --text="Then you have to input manually: \n[PROJECT_NAME]\n[LOCAL_FOLDER]\n[DROPBOX_CVS_FOLDER]"


		#PROJECT NAME
		PROJECT_NAME=$(zenity --entry   \
                                      --title="gDropboxCVS" \
                                      --text="Insert [PROJECT_NAME]:" \
                                      --entry-text $PROJECT_NAME \
                              )

		if [ "$PROJECT_NAME" = "" ]; then
			zenity --error --title="gDropboxCVS" --text="Wrong project name. Exiting." 
                        exit
		fi
		
		#LOCAL_FOLDER
		LOCAL_FOLDER=$(zenity --file-selection --directory --title="Choose [LOCAL_FOLDER]")
		case $? in
	#		 0)
	#		        zenity --error --title="gDropboxCVS" --text="$LOCAL_FOLDER choosen.";;
			 1)
				zenity --error --title="gDropboxCVS" --text="No directory choosen. Exiting." && exit;;
			-1)
				zenity --error --title="gDropboxCVS" --text="No directory choosen. Exiting." && exit;;
		esac


		#DROPBOX_CVS_FOLDER
		DROPBOX_CVS_FOLDER=$(zenity --file-selection --directory --title="Choose [DROPBOX_CVS_FOLDER]")
		case $? in
	#		 0)
	#		        zenity --error --title="gDropboxCVS" --text="$DROPBOX_CVS_FOLDER choosen.";;
			 1)
				zenity --error --title="gDropboxCVS" --text="No directory choosen. Exiting." && exit;;
			-1)
				zenity --error --title="gDropboxCVS" --text="No directory choosen. Exiting." && exit;;
		esac

		option=$(zenity --question   \
		 --title="gDropboxCVS" \
		 --text="gDropboxCVS parameters\n\n[PROJECT_NAME] = $PROJECT_NAME\n[LOCAL_FOLDER] = $LOCAL_FOLDER\n[DROPBOX_CVS_FOLDER] = $DROPBOX_CVS_FOLDER\n\nIs this correct?")
		if [ $? = 1 ]; then
			zenity --info --title="gDropboxCVS" --text="Unable to set parameters. Restart gDropboxCVS" && exit
		fi
	fi



	#Options configured, ready to start syncing

	#Upload selected
	if [ "$operation" = "Upload project to Dropbox cvs folder" ]; then

		option=$(zenity --question   \
		 --title="gDropboxCVS" \
		 --text="Upload project will update contents in $DROPBOX_CVS_FOLDER/$PROJECT_NAME\n\n Are you sure?")


		if [ $? = 0 ]; then

			#if secure mode is enabled, first we made a backup of Dropbox folder
			if [ "$SECURE_MODE" = "on" ]; then
				tar czf  $DROPBOX_CVS_FOLDER/backups/$PROJECT_NAME.tgz $DROPBOX_CVS_FOLDER/$PROJECT_NAME  | $(zenity --title "gDropboxCVS" --text="Generating backup files..." --progress --auto-close) 
				zenity --info --title="gDropboxCVS" --text="Compressed backup generated in $DROPBOX_CVS_FOLDER/backups/$PROJECT_NAME.tgz"			
			fi
			
			rsync -av --delete -r $LOCAL_FOLDER/ $DROPBOX_CVS_FOLDER/$PROJECT_NAME   | $(zenity --title "gDropboxCVS" --text="Syncing files..." --text-info --width 600 --height 400)

			zenity --info --title="gDropboxCVS" --text="Project upload complete"


		else
			zenity --info --title="gDropboxCVS" --text="Exit without changes"
		fi

	#Download selected
	else if [ "$operation" = "Dowload project to local folder" ]; then

		option=$(zenity --question   \
                                --title="gDropboxCVS" \
                                --text="Download project will update $LOCAL_FOLDER with the content of $DROPBOX_CVS_FOLDER/$PROJECT_NAME\n\n Are you sure?" \
                                --height 200)

		#user agrees the start syncing
		if [ $? = 0 ]; then

			#if secure mode is enabled, first we made a backup of Dropbox folder
			if [ "$SECURE_MODE" = "on" ]; then
				tar czf  $DROPBOX_CVS_FOLDER/backups/$PROJECT_NAME.tgz $LOCAL_FOLDER/$PROJECT_NAME  | $(zenity --title "gDropboxCVS" --text="Generating backup files..." --progress --auto-close) 
				zenity --info --title="gDropboxCVS" --text="Compressed backup generated in $DROPBOX_CVS_FOLDER/backups/$PROJECT_NAME.tgz"			
			fi

			#here it's the point, with rsync we overwrite local folder with the contents of CVS

                        rsync -av --delete -r $DROPBOX_CVS_FOLDER/$PROJECT_NAME/ $LOCAL_FOLDER  | $(zenity --title "gDropboxCVS" --text="Syncing files..." --text-info --width 600 --height 400)


			#Post update scripts
			#As we have introduce the FIX_PERMISSIONS parameter there's no need of asking user
			
			#option=$(zenity --question   \
			# --title="gDropboxCVS - Update permissions" \
			# --text="Add www-data group write permissions to /$LOCAL_FOLDER?\nYou must insert sudo password")

			if [ $FIX_PERMISSIONS = "on" ]; then
				gksudo "chgrp -R www-data $LOCAL_FOLDER"
				gksudo "chmod -R g+w $LOCAL_FOLDER"
				zenity --info --title="gDropboxCVS" --text="Permissions fixed"
			fi

			zenity --info --title="gDropboxCVS" --text="Project download complete"
				

		else
			zenity --info --title="gDropboxCVS" --text="Exiting without changes"
		fi

	fi fi
else
	zenity --info --title="gDropboxCVS" --text="Exiting without changes"
fi

