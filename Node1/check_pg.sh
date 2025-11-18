# /usr/local/bin/check_pg.sh

#!/bin/bash

docker exec pg-primary pg_isready -U postgres -d postgres >/dev/null 2>&1 || exit 1

IS_PRIMARY=$(docker exec pg-primary psql -U postgres -tAc "SELECT NOT pg_is_in_recovery();") || exit 1
[ "$IS_PRIMARY" = "t" ] || exit 1

exit 0
