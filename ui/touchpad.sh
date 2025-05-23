#!/bin/bash

touchpad_xinput=`xinput list | grep -i touchpad`
touchpad_ideq=`echo $touchpad_xinput|awk '{print $6}'`
touchpad_id=${touchpad_ideq##*=}
echo $touchpad_id
xinput set-prop $touchpad_id "Device Enabled" $1
