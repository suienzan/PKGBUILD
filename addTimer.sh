#! /usr/bin/bash

if [ ! "$1" ]; then
  echo "need arguments"
  exit 1
fi

cat <<EOF >~/.config/systemd/user/update-"$1"@.service

[Unit]
Description=Update $1

[Service]
Type=oneshot
WorkingDirectory=%h/%i/$1
ExecStart=/usr/bin/bash %h/%i/$1/upgrade.sh

EOF

cat <<EOF >~/.config/systemd/user/update-"$1"@.timer

[Unit]
Description=Check $1 update

[Timer]
Unit=update-$1@%i.service
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target


EOF
