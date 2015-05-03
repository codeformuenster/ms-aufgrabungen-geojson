#!/bin/bash
exec go-cron "$SCHEDULE" /bin/bash /convert.sh
