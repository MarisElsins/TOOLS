du -sm $(mount | grep -v " / " | awk -v ORS=" " '{print "--exclude="$3}') $PWD/*
