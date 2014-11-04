# Maris Elsins / Pythian / 2013
# Source: https://github.com/MarisElsins/TOOLS/blob/master/Shell/getMOSPatch.sh
# Inspired by John Piwowar's work: http://only4left.jpiwowar.com/2009/02/retrieving-oracle-patches-with-wget/
# Usage:
# getMOSPatch.sh reset=yes  # Use to refresh the platform and language settings
# getMOSPatch.sh patch=patchnum_1[,patchnum_n]* [download=all] [regexp=...]# Use to download one or more patches. If "download=all" is set all patches will be downloaded without user interaction, you can also define regular expressen by passing regexp to filter the patch filenames.
# v1.0 Initial version

# exit on the first error
set -e

# Setting some variables for the files I'll operati with
PREF=`basename $0`
CD=`dirname $0`
CFG=${CD}/.${PREF}.cfg
TMP1=${CD}/.${PREF}.tmp1
TMP2=${CD}/.${PREF}.tmp2
TMP3=${CD}/.${PREF}.tmp3
COOK=${CD}/.${PREF}.cookies

# Processing the arguments by setting the respective variables
# all arguments are passed to the shell scripts in form argname=argvalue
# This command sets the following variables for each argument: p_argname=argvalue
for var in "$@" ; do eval "export p_${var}"; done

# Did we get all the variables we need?
if [ -z "$p_patch" ] && [ "$p_reset" != "yes" ] ; then
  echo "Not enough parameters.
  Usage:
  `basename $0` reset=yes  # Use to refresh the platform and language settings
  `basename $0` patch=patchnum_1[,patchnum_n]* [download=all] # Use to download one or more patches. If download=all is set all patches will be downloaded without user interaction"
  exit 1
fi

# change into p_destination if defined, so we can run this from crontab or from other script
if [ $p_destination ]; then
  echo "changing directory to $p_destination"
  pushd $p_destination >/dev/null 2>&1
  UNPUSHD="$?"
fi

# Reading the MOS user credentials. Set environment variables mosUser and mosPass if you want to skip this.
[[ $mosUser ]] || read -p "Oracle Support Userid: " mosUser;
[[ $mosPass ]] || read -sp "Oracle Support Password: " mosPass;
echo
touch ~/.wgetrc
chmod 600 ~/.wgetrc
perl -pi -e 'if(/^user=/){undef $_}' ~/.wgetrc
perl -pi -e 'if(/^password=/){undef $_}' ~/.wgetrc
echo "user=$mosUser" >> ~/.wgetrc
echo "password=$mosPass" >> ~/.wgetrc
set +e
wget --secure-protocol=TLSv1 --save-cookies=$COOK --keep-session-cookies --no-check-certificate "https://updates.oracle.com/Orion/SimpleSearch/switch_to_saved_searches" -O $TMP1 -o $TMP2 --no-verbose
RESULT=$?
perl -pi -e 'if(/^user=/){undef $_}' ~/.wgetrc
perl -pi -e 'if(/^password=/){undef $_}' ~/.wgetrc
if [ ${RESULT} -ne 0 ] ; then
  cat $TMP2
  exit 1
fi

rm $TMP2 $TMP1 $TMP3 >/dev/null 2>&1
set -e

# If we run the script the first time we need to collect Language and Platform settings.
# This part also executes if reset=yes of file is empty.
# This part fetches the simple search form from mos and parses all Platform and Language codes
if [ ! -f $CFG ] || [ "$p_reset" == "yes" ] || [ "`file -b $CFG`"  == "empty" ]; then
  echo; echo Getting the Platform/Language list
  wget --secure-protocol=TLSv1 --no-check-certificate --load-cookies=$COOK "https://updates.oracle.com/Orion/SavedSearches/switch_to_simple" -O $TMP1 -q
  echo "Available Platforms and Languages:"
  grep -A999 "<select name=plat_lang" $TMP1 | grep "^<option"| grep -v "\-\-\-" | awk -F "[\">]" '{print $2" - "$4}' > $TMP2
  cat $TMP2
  read -p "Comma-delimited list of required platform and language codes: " PlatLangCodes;
  > $CFG
  for PLATLANG in $(echo $PlatLangCodes | sed "s/,/ /g" | xargs -n 1 echo )
  do
    grep "^$PLATLANG " $TMP2 | sed "s/ - /;/g" >> $CFG
  done
  rm $TMP2
fi

if [ -z "$p_regexp" ] ; then
  p_regexp=".*"
fi

# Iterate patches one by one
for pp_patch in $(echo ${p_patch} | sed "s/,/ /g" | xargs -n 1 echo)
do
  IFS=$'\n'
  # Iterate languages one by one
  for PL in $(cat $CFG)
  do
    PLATLANG=`echo $PL | awk -F";" '{print $1}'`
    PLDESC=`echo $PL | awk -F";" '{print $2}'`
    echo
    echo "Getting list of files for patch $pp_patch for \"${PLDESC}\""

    wget --secure-protocol=TLSv1 --no-check-certificate --load-cookies=$COOK "https://updates.oracle.com/Orion/SimpleSearch/process_form?search_type=patch&patch_number=${pp_patch}&plat_lang=${PLATLANG}" -O $TMP1 -q
    grep "Download/process_form" $TMP1 | egrep "${p_regexp}" | sed 's/ //g' | sed "s/.*href=\"//g" | sed "s/\".*//g" > $TMP2
    rm $TMP1

    if [ `cat $TMP2 | wc -l` -gt 0 ] ; then
      if [ `cat $TMP2 | wc -l` -eq 1 ] ; then
        DownList="1"
      else
        set +
        if [ "$p_download" == "all" ] ; then
          DownList=""
        else
          cat $TMP2 | awk -F"=" '{print NR " - " $NF}' | sed "s/[?&]//g"
          read -p "Comma-delimited list of files to download: " DownList
          DownList=`echo -n ${DownList} | sed  "s/,/p;/g"`
        fi
        set -
      fi
      cat $TMP2 | sed -n "${DownList}p" >> $TMP3
    else
      echo "no patch available"
    fi
    rm $TMP2
  done
done

echo
echo "Downloading the patches:"
for URL in $(cat $TMP3)
do
  fname=`echo ${URL} | awk -F"=" '{print $NF;}' | sed "s/[?&]//g"`
  fname_=${fname%.zip}

  echo
  echo "Downloading file $fname ..."
  if [ $p_skip ] && [ -f $fname ]; then
    ls -l $fname
    echo "file $fname found,  skipping"
  else
    ##  wget --secure-protocol=TLSv1 --no-check-certificate --load-cookies=$COOK "$URL" -O $fname -q
    curl -b $COOK -c $COOK --tlsv1 --insecure --output $fname -L "$URL" ;
    echo "$fname completed with status: $?"
  fi

## download readme and rename to html or txt
  echo
  echo "Downloading readme file ..."
  curl -b $COOK -c $COOK --tlsv1 --insecure --output $fname_.readme -L "https://updates.oracle.com/Orion/Services/download?type=readme&bugfix_name=$pp_patch"
  if [ -f $fname_.readme ]; then
    if [ "`file -b $fname_.readme`" == "HTML document text" ]; then
      mv $fname_.readme $fname_.html
    else
      mv $fname_.readme $fname_.txt
    fi
  fi

## download xml
  echo
  echo "Downloading xml file ..."
  curl -b $COOK -c $COOK --tlsv1 --insecure --output ${fname%.zip}.xml -L "https://updates.oracle.com/Orion/Services/search?bug=$pp_patch"

done

#leave the pushd if defined, running popd
if [ $UNPUSHD ]; then
  popd >/dev/null 2>&1
fi

rm $TMP3
rm $COOK >/dev/null 2>&1
