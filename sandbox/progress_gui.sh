#!/bin/bash
(
for i in {1..100}; do
    echo $i
    echo "# $i% 完了しました..."
    sleep 0.05
done
) | zenity --progress --title="ダウンロード" --text="開始中..." --percentage=0
