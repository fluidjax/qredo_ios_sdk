#!/bin/bash

target_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
dsym_plist="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME/Contents/Info.plist"

git=$(sh /etc/profile; which git)
number_of_commits=$("$git" rev-list HEAD --count)

echo "*******************"
echo $number_of_commits
echo $git_release_version



for plist in "$target_plist" "$dsym_plist"; do
  if [ -f "$plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $number_of_commits" "$plist"
  fi
done



