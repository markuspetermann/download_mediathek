#!/bin/bash

# ------------------------------------------------------------------
# [Author]  Markus Petermann
#           https://markuspetermann.net
#
#           Based on the original script from Leo Gaggl
#           http://www.gaggl.com / https://github.com/leogaggl/media
#
#           SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND
#           License GPL V2 - details see attached LICENSE file
#
#           This script downloads a media file from ARD Mediathek
#           http://github.com/markuspetermann/download_mediathek
#
# Dependency:
#     http://stedolan.github.io/jq/
#     Debian/Ubuntu: sudo apt-get install jq
# ------------------------------------------------------------------

##########################################
## Local Variables
##########################################

MEDIA_URL=${BASH_ARGV[0]}
QUALITY=3       ## override with -q
FILENAME=''     ## override with -f

##########################################
# Processing Options
##########################################

while getopts ":q:f:h" opt; do
  case $opt in
    q)  ## Download quality setting
      QUALITY=$OPTARG
      ;;
    f)  ## Filename to save
      FILENAME=$OPTARG
      ;;
    h)  ## Help
      echo "Usage: ./download_mediathek.sh -f filename.mp4 -q 0-3 MEDIATHEK-URL"
          exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

##########################################
## Get download URL from Mediathek URL
##########################################
if test -z "$MEDIA_URL" ; then
  echo -e "Error: missing or invalid parameters\n\nUsage:\n $0 - for useage info use -h." >&2;
  exit 1
fi

site=$(wget $MEDIA_URL -q -O -)
re="O_STATE__\s=\s(.+);\s+<"

if [[ $site =~ $re ]]; then
  json=${BASH_REMATCH[1]}
fi

DOWNLOADURL=$(echo $json | jq -r '[[.[keys[] | select(contains(".mediaCollection._mediaArray.0._mediaStreamArray."))]] | .[] | ._stream.json | .[]]
                                  | map(select(test("(lo\\.mp4|hi\\.mp4|hq\\.mp4|hd\\.mp4)"))) | .['$QUALITY']')

echo 'Downloading: ' ${DOWNLOADURL}

if test -z "$DOWNLOADURL" ; then
  echo -e "No downloadable media found." >&2;
  exit 1
fi

##########################################
## Download
##########################################
if [ -n "$FILENAME" ]; then
  wget -O ${FILENAME} ${DOWNLOADURL}
else
  wget ${DOWNLOADURL}
fi
