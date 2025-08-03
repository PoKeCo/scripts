#!/usr/bin/env bash
# zenity-demo.sh

# 情報ダイアログ
zenity --info \
  --title="Info" \
  --text="This is an information dialog" \
  --width=300

# 警告ダイアログ
zenity --warning \
  --title="Warning" \
  --text="Disk usage exceeded threshold" \
  --width=300

# エラーダイアログ
zenity --error \
  --title="Error" \
  --text="Operation failed! Please try again." \
  --width=300

# 質問（Yes/No）
if zenity --question \
    --title="Confirm" \
    --text="Do you want to continue?" \
    --width=300; then
  echo "User chose Yes"
else
  echo "User chose No"
fi

# テキスト入力
user_input=$(zenity --entry \
  --title="Input Required" \
  --text="Enter your name:" \
  --width=300)
echo "Name: $user_input"

# パスワード入力
password=$(zenity --password \
  --title="Password" \
  --text="Enter your secret password:" \
  --width=300)
echo "Password length: ${#password}"

# カレンダー選択
selected_date=$(zenity --calendar \
  --title="Select Date" \
  --text="Choose a date:" \
  --day=1 --month=1 --year=2025 \
  --width=300)
echo "You picked: $selected_date"

# ファイル選択
file=$(zenity --file-selection \
  --title="Select a file to process" \
  --width=400)
echo "Selected file: $file"

# カラー選択
color=$(zenity --color-selection \
  --title="Pick a color" \
  --width=300)
echo "Picked color: $color"

# プログレス（フェイク処理）
(
  for i in {1..100}; do
    echo $i
    sleep 0.05
  done
) | zenity --progress \
  --title="Progress Dialog" \
  --text="Processing..." \
  --percentage=0 \
  --auto-close \
  --width=300

# リスト選択（単一選択）
list_item=$(zenity --list \
  --title="Choose one" \
  --column="Option" "Foo" "Bar" "Baz" \
  --width=300 --height=200)
echo "Selected: $list_item"

# フォーム入力（複数入力項目）
form_values=$(zenity --forms \
  --title="Form Input" \
  --text="Enter info:" \
  --add-entry="First name" \
  --add-entry="Last name" \
  --add-password="Password" \
  --width=400 --height=250)
echo "Form data: $form_values"

# テキスト表示（長文）
zenity --text-info \
  --title="Log Output" \
  --filename=<(echo -e "Line 1\nLine 2\nLine 3") \
  --width=400 --height=300
