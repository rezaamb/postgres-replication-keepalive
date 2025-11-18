# /usr/local/bin/pg_role_change.sh

LOGFILE="/var/log/keepalived-pg.log"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"
STATE="$1"

echo "$DATE [pg_role_change] called with args: $*" >> "$LOGFILE" 2>&1

if [ "$STATE" != "MASTER" ] && [ "$STATE" != "master" ]; then
  echo "$DATE [pg_role_change] not MASTER (state=$STATE), exiting" >> "$LOGFILE" 2>&1
  exit 0
fi

docker exec pg-standby pg_isready -U postgres -d postgres >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "$DATE [pg_role_change] pg-standby is not ready, abort" >> "$LOGFILE" 2>&1
  exit 1
fi

IS_IN_RECOVERY=$(docker exec pg-standby \
  psql -U postgres -tAc "SELECT pg_is_in_recovery();" 2>>"$LOGFILE" | tr -d '[:space:]')

echo "$DATE [pg_role_change] pg_is_in_recovery=$IS_IN_RECOVERY" >> "$LOGFILE" 2>&1

if [ "$IS_IN_RECOVERY" = "t" ]; then
  echo "$DATE [pg_role_change] running pg_ctl promote ..." >> "$LOGFILE" 2>&1
  docker exec -u postgres pg-standby \
    pg_ctl -D /var/lib/postgresql/data promote >>"$LOGFILE" 2>&1
  RC=$?
  echo "$DATE [pg_role_change] promote exit code=$RC" >> "$LOGFILE" 2>&1
else
  echo "$DATE [pg_role_change] already primary, nothing to do" >> "$LOGFILE" 2>&1
fi

exit 0
