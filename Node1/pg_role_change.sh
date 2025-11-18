# /usr/local/bin/pg_role_change.sh

#!/bin/bash
STATE="$1"
echo "$(date) keepalived state change: $STATE" >> /var/log/keepalived-pg.log
exit 0
