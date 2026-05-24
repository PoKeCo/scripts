#!/bin/bash
(
for i in {1..100}; do
    echo $i
    echo "# $i% done..."
    sleep 0.05
done
) | zenity --progress --title="Download" --text="Starting..." --percentage=0
