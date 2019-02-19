#!/bin/bash -ex

CUR_PATH="$(git rev-parse --show-toplevel)"
DEPENDENCIES_PATH="$CUR_PATH/Dependencies"

mkdir -p "$DEPENDENCIES_PATH"
cd "$DEPENDENCIES_PATH"

#if ! exists
if [ -e "$DEPENDENCIES_PATH/depot_tools" ]
then
  echo "depot tools are present"
else
  echo "cloning depot tools"
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi


#add depot to  PATH
PATH=$PATH:"$DEPENDENCIES_PATH/depot_tools"

#if ! exists webrtc
if [ -e "$DEPENDENCIES_PATH/WebRTC/src" ]
then 
  echo "webrtc src exists"
else
  mkdir -p WebRTC && cd WebRTC
  fetch webrtc
fi


#parse version file
#WEBRTC_VERSION_FILE="$CUR_PATH/webrtc-version.txt"
#WEBRTC_LIB_VERSION=$(cat $WEBRTC_VERSION_FILE | tr -d '\r\n')
#WEBRTC_RELEASE_VERSION=${WEBRTC_LIB_VERSION%%-*}
#WEBRTC_COMMIT_VERSION=$(sed '1!d' $WEBRTC_VERSION_FILE)
#ADDITIONAL_PATCHES=$(sed '2!d;s/-//;s/-/ /g' $WEBRTC_VERSION_FILE)
WEBRTC_COMMIT_VERSION=master

#checkout
cd "$DEPENDENCIES_PATH/WebRTC/src" 
git fetch --all
git reset --hard
git checkout branch-heads/$WEBRTC_RELEASE_VERSION -f
git clean -df


#sync
gclient sync --with_branch_heads

#apply patches

#legacy straight patch applying
#for patch in $ADDITIONAL_PATCHES
#do
#  echo "Applying patch $patch"
#  CLID=${patch%.*}
#  REVISION=${patch#*.}
#  curl -L "https://webrtc-review.googlesource.com/changes/$CLID/revisions/$REVISION/patch?download" | base64 -D | git apply --verbose
#done


#create Xcode project
if [ -e "$DEPENDENCIES_PATH/WebRTC/src/out/ios/all.xcworkspace" ]
then
  echo "Xcode project exists"
else
  cd "$DEPENDENCIES_PATH/WebRTC/src" 
  gn gen out/ios --args='target_os="ios" target_cpu="arm64"' --ide=xcode
  mv out/ios/products.xcodeproj out/ios/WebRTC.xcodeproj
  cd "$DEPENDENCIES_PATH"
fi

echo "Done"

