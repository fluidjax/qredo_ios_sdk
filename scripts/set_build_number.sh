#!/bin/bash

target_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
dsym_plist="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME/Contents/Info.plist"

if [ -d .git ]; then
	git=$(sh /etc/profile; which git)
	number_of_commits=$("$git" rev-list HEAD --count)
	git_release_version=$("$git" describe --tags --always --abbrev=0)
	#this is a git directory
	echo "*****************************************************"
	echo $number_of_commits > $SRCROOT/buildnumber
    echo $git_release_version > $SRCROOT/releasenumber
else
  number_of_commits=$(cat "$SRCROOT/buildnumber")
  git_release_version=$(cat "$SRCROOT/releasenumber")
  echo "*****************************************************"
  echo "Commits is $number_of_commits" 
  echo "Release is $git_release_version"
fi;

for plist in "$target_plist" "$dsym_plist"; do
  if [ -f "$plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $number_of_commits" "$plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${git_release_version#*v}" "$plist"
  fi
done



