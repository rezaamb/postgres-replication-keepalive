ایتدا یوزر ```repuser``` را ساخته و در فایل pg_hba.conf میگذاریم 
```bash
docker exec -it pg-primary psql -U psgresql_user -d psgresql_db -c "CREATE ROLE repuser WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'Repl@2025!';"
```

ساخت replication slot
```bash
docker exec -it pg-primary psql -U psgresql_user -d psgresql_db -c "SELECT pg_create_physical_replication_slot('standby1_slot');"
```
ریلود کردن بدون DownTime برای وقتی که postgresql.conf یا pg_hba.conf رو تغییر دادی
```bash
docker exec -it pg-primary psql -U psgresql_user -d psgresql_db -c "SELECT pg_reload_conf();"
```
باید اینو ببینی :
```
 pg_is_in_recovery
-------------------
 t
(1 row)
```

روی Standby – گرفتن بکاپ و بالا آوردن استندبای
```bash
docker compose down
```
خالی کردن دیتادایرکتوری استندبای
```bash
rm -rf /var/lib/postgresql/data/*
```

گرفتن pg_basebackup از primary

```bash
docker run --rm \
  -e PGPASSWORD='Repl@2025\!' \
  -v /var/lib/postgresql/data:/var/lib/postgresql/data \
  172.20.9.20:7071/postgres \
  pg_basebackup \
    -d "host=172.20.22.11 port=5432 user=repuser application_name=standby1" \
    -D /var/lib/postgresql/data \
    -Fp -Xs -P -R
```
✅ وقتی waiting for checkpoint و در نهایت 100% رو دیدی یعنی بکاپ کامل گرفته شده.

بالا آوردن کانتینر استندبای
```bash
docker compose up -d
docker ps
```
چک کردن این‌که استندبای واقعاً در حالت ریکاوری است
```bash
docker exec -it pg-standby psql -U psgresql_user -d psgresql_db -c "select pg_is_in_recovery();"
```
باید خروجی بشه:
```
 pg_is_in_recovery
-------------------
 t
(1 row)
```

روی Primary – چک کردن وضعیت رپلیکیشن
```bash
docker exec -it pg-primary psql -U psgresql_user -d psgresql_db -c "select client_addr, application_name, state, sync_state from pg_stat_replication;"
```
اگر همه‌چیز اوکی باشد، شبیه این می‌بینی:

```
 client_addr  | application_name |  state    | sync_state
--------------+------------------+-----------+-----------
 172.20.22.12 | standby1         | streaming | sync/async
```

وضعیت replication slot (برای health check)

```bash
docker exec -it pg-primary psql -U psgresql_user -d psgresql_db -c "SELECT slot_name, active FROM pg_replication_slots;"
```
باید standby1_slot رو ببینی و ستون active برابر t باشه.


تست رپلیکیشن (درج دیتا روی primary و دیدن روی standby)

روی primary: ساخت جدول و درج رکورد



```bash
docker exec -it pg-primary psql -U psgresql_user -d psgresql_db
```
```bash
CREATE TABLE IF NOT EXISTS repl_test(id int, note text);
INSERT INTO repl_test VALUES (1, 'hello from primary reza');
SELECT * FROM repl_test;
```

روی standby: خواندن همان جدول

```bash
docker exec -it pg-standby psql -U psgresql_user -d psgresql_db -c "SELECT * FROM repl_test;"
```
✅ اگر همان رکورد را دیدی، یعنی استریم رپلیکیشن درست کار می‌کند.



اگر به هر دلیلی primary کانتینرش Down شد :
```bash
docker exec -it pg-standby psql -U psgresql_user -d psgresql_db -c "SELECT pg_promote();"
docker exec -it pg-standby psql -U psgresql_user -d psgresql_db -c "SELECT pg_is_in_recovery();"
```
اگر خروجی شد:
```
 pg_is_in_recovery
-------------------
 f
(1 row)
```

