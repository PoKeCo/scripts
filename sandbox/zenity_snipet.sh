#!/usr/bin/env bash
# zenity-demo.sh

# Information dialog
zenity --info \
  --title="Info" \
  --text="This is an information dialog" \
  --width=300

# Warning dialog
zenity --warning \
  --title="Warning" \
  --text="Disk usage exceeded threshold" \
  --width=300

# Error dialog
zenity --error \
  --title="Error" \
  --text="Operation failed! Please try again." \
  --width=300

# Question dialog (Yes/No)
if zenity --question \
    --title="Confirm" \
    --text="Do you want to continue?" \
    --width=300; then
  echo "User chose Yes"
else
  echo "User chose No"
fi

# Text input
user_input=$(zenity --entry \
  --title="Input Required" \
  --text="Enter your name:" \
  --width=300)
echo "Name: $user_input"

# Password input
password=$(zenity --password \
  --title="Password" \
  --text="Enter your secret password:" \
  --width=300)
echo "Password length: ${#password}"

# Calendar selection
selected_date=$(zenity --calendar \
  --title="Select Date" \
  --text="Choose a date:" \
  --day=1 --month=1 --year=2025 \
  --width=300)
echo "You picked: $selected_date"

# File selection
file=$(zenity --file-selection \
  --title="Select a file to process" \
  --width=400)
echo "Selected file: $file"

# Color selection
color=$(zenity --color-selection \
  --title="Pick a color" \
  --width=300)
echo "Picked color: $color"

# Progress dialog (fake processing)
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

# List selection (single selection)
list_item=$(zenity --list \
  --title="Choose one" \
  --column="Option" "Foo" "Bar" "Baz" \
  --width=300 --height=200)
echo "Selected: $list_item"

# Form input (multiple fields)
form_values=$(zenity --forms \
  --title="Form Input" \
  --text="Enter info:" \
  --add-entry="First name" \
  --add-entry="Last name" \
  --add-password="Password" \
  --width=400 --height=250)
echo "Form data: $form_values"

# Text display (long content)
zenity --text-info \
  --title="Log Output" \
  --filename=<(echo -e "Line 1\nLine 2\nLine 3") \
  --width=400 --height=300
