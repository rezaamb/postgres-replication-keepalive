# /usr/local/bin/check_pg.sh

#!/bin/bash
# چک ﻡی<200c>کﻥیﻡ کﺎﻨﺗیﻥﺭ pg-standby ﺩﺭ ﺡﺎﻟ پﺎﺴﺧ<200c>گﻭیی ﺎﺴﺗ
docker exec pg-standby pg_isready -U postgres -d postgres >/dev/null 2>&1 || exit 1
exit 0
