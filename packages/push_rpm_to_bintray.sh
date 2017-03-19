#!/bin/bash -u
#
# push_rpm_to_bintray.sh - francois@skymind.io
#
# This script push a rpm package to Bintray repo
#

function usage() {
  echo "$0 username api_key organisation repo_name rpm_file site_url"
  exit 0
}

if [ $# -lt 6 ]; then
 usage
fi

BINTRAY_USER=$1
BINTRAY_APIKEY=$2
BINTRAY_DESTINATION=$3
BINTRAY_REPO=$4
RPM_FILE=$5
BASE_DESC=$6

CURL_SILENT_CMD="curl --write-out %{http_code} --location --silent --output /dev/null -u$BINTRAY_USER:$BINTRAY_APIKEY"
CURL_VERBOSE_CMD="curl --write-out %{http_code} --location -u$BINTRAY_USER:$BINTRAY_APIKEY"


CURL_CMD=$CURL_SILENT_CMD

BINTRAY_ACCOUNT=$BINTRAY_DESTINATION

RPM_NAME=`rpm --queryformat "%{NAME}" -qp $RPM_FILE`
RPM_VERSION=`rpm --queryformat "%{VERSION}" -qp $RPM_FILE`
RPM_RELEASE=`rpm --queryformat "%{RELEASE}" -qp $RPM_FILE`
RPM_ARCH=`rpm --queryformat "%{ARCH}" -qp $RPM_FILE`
RPM_LICENSE=`rpm --queryformat "%{LICENSE}" -qp $RPM_FILE`
RPM_DESCRIPTION=`rpm --queryformat "%{DESCRIPTION}" -qp $RPM_FILE`

REPO_FILE_PATH=`basename $RPM_FILE`
DESC_URL=$BASE_DESC/$RPM_NAME

if [ -z "$RPM_NAME" ] || [ -z "$RPM_VERSION" ] || [ -z "$RPM_RELEASE" ] || [ -z "$RPM_ARCH" ]; then
  echo "no RPM metadata information in $RPM_FILE, skipping."
  exit -1
fi

echo "RPM_NAME=$RPM_NAME, RPM_VERSION=$RPM_VERSION, RPM_RELEASE=$RPM_RELEASE, RPM_ARCH=$RPM_ARCH"
echo "BINTRAY_USER=$BINTRAY_USER, BINTRAY_DESTINATION=$BINTRAY_DESTINATION, BINTRAY_REPO=$BINTRAY_REPO, RPM_FILE=$RPM_FILE, BASE_DESC=$BASE_DESC"

echo "Deleting package from Bintray.."
HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X DELETE https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$RPM_NAME`

if [ "$HTTP_CODE" != "200" ]; then
 echo "can't delete package -> $HTTP_CODE"
else
 echo "Package deleted"
fi

echo "Creating package on Bintray.."
DATA_JSON="{ \"name\": \"$RPM_NAME\", \"desc\": \"${RPM_DESCRIPTION}\", \"vcs_url\": \"$DESC_URL\", \"labels\": \"\", \"licenses\": [ \"$RPM_LICENSE\" ] }"

if [ "$XDEBUG" = "true" ]; then
 echo "DATA_JSON=$DATA_JSON"
fi

HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X POST https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/ --data "$DATA_JSON"`

if [ "$HTTP_CODE" != "201" ]; then
 echo "can't create package -> $HTTP_CODE"
 exit -1
else
 echo "Package created"
fi

echo "Uploading package to Bintray.."
HTTP_CODE=`$CURL_CMD -T $RPM_FILE -u$BINTRAY_USER:$BINTRAY_APIKEY -H "X-Bintray-Package:$RPM_NAME" -H "X-Bintray-Version:$RPM_VERSION-$RPM_RELEASE" "https://api.bintray.com/content/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$REPO_FILE_PATH;publish=1"`

if [ "$HTTP_CODE" != "201" ]; then
 echo "failed to upload package -> $HTTP_CODE"
 exit -1
else
 echo "Package uploaded"
fi

exit 0
