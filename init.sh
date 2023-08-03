#!/bin/bash

/usr/bin/systemctl restart autofs
exec /usr/sbin/init
service ssh start
exec /usr/sbin/sshd -D