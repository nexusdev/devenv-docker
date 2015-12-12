#!/bin/bash
supervisord &
sleep 5
tail -f /var/log/ftpserver.log -f /var/log/ftpserver0.log
