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
#           This script downloads a media file from ZDF Mediathek
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
BASE_URL='https://api.zdf.de'
FILENAME=''     ## override with -f

##########################################
# Processing Options
##########################################

while getopts ":q:f:h" opt; do
  case $opt in
    f)  ## Filename to save
      FILENAME=$OPTARG
      ;;
    h)	## Help
      echo "Usage: ./download_zdf.sh -f filename.mp4 MEDIATHEK-URL"
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

JSON=$(wget $MEDIA_URL -q -O - | tr -d '\n\t ' | grep -oP "data-zdfplayer-jsb='(.*?)'" | cut -d $'\n' -f1 | cut -d \' -f2)

CONTENTURL=$(echo $JSON | jq -r '.content')
APITOKEN=$(echo $JSON | jq -r '.apiToken')

echo 'CONTENTURL: '$CONTENTURL

if test -z "$CONTENTURL" ; then
  echo -e "No Content URL found." >&2
  exit 1
fi

echo 'APITOKEN: '$APITOKEN

if test -z "$APITOKEN" ; then
  echo -e "No API Token found." >&2
  exit 1
fi

HEADER='--header=Api-Auth: Bearer '$APITOKEN
TEX_URL=$(wget "$HEADER" $CONTENTURL -q -O - | jq -r '.mainVideoContent | .["http://zdf.de/rels/target"] | .["http://zdf.de/rels/streams/ptmd-template"]' | sed -e 's/{playerId}/ngplayer_2_3/g')

echo 'TEX_URL: '$BASE_URL$TEX_URL

if test -z "$TEX_URL" ; then
  echo -e "No TEX URL found." >&2
  exit 1
fi

DOWNLOADURL=$(wget "$HEADER" $BASE_URL$TEX_URL -q -O - | jq -r '.priorityList | map(select(.formitaeten[0].type | contains("mp4"))) | .[0].formitaeten[0].qualities 
                                                         | map(select(.quality | contains("veryhigh"))) | .[0].audio.tracks[0].uri')

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
