# /usr/local/bin/check_pg.sh

#!/bin/bash
docker exec pg-standby pg_isready -U postgres -d postgres >/dev/null 2>&1 || exit 1
exit 0
