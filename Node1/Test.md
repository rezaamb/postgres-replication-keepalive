برای ساخت یک Table در دیتابیس 
```bash
docker exec -it pg-primary psql -U psgresql_user -d psgresql_db -c "SELECT pg_create_physical_replication_slot('standby1_slot');"
```
ریلود کردن بدون DownTime
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

