echo Environment variables :
env
echo Setting rights ....
set -x

echo Starting PostGreSQL ....
date
cd /usr/local/bin

mkdir /var/lib/postgresql/data 
mkdir /var/lib/postgresql/backup
chmod -R 777 /var/lib/postgresql/backup

# create the postgresql.conf file with the proper configuration for internal network usage
if [ ! -f /var/lib/postgresql/data/postgresql.conf ]; then
  echo Creating database and connection permission files ...
  echo PG$(date -I) > /tmp/password
  export pwd=$(echo PG$(date -I))
  su -c "./initdb -D /var/lib/postgresql/data/data -U postgres --pwfile=/tmp/password" postgres
  echo Created password for user postgres = 
  cat /tmp/password
  echo "listen_addresses = '*'" >  /var/lib/postgresql/data/postgresql.conf

  echo "# TYPE  DATABASE        USER            ADDRESS                 METHOD" > /var/lib/postgresql/data/data/pg_hba.conf
  echo "# local is for Unix domain socket connections only" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "local   all             all                                     trust" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "# IPv4 local connections:" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "host    all             all             127.0.0.1/32            trust" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "# IPv6 local connections:" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "host    all             all             ::1/128                 trust" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "# Allow replication connections from localhost, by a user with the" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "# replication privilege." >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "local   replication     all                                     trust" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "host    replication     all             127.0.0.1/32            trust" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "host    replication     all             ::1/128                 trust" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "# TYPE DATABASE USER CIDR-ADDRESS  METHOD" >> /var/lib/postgresql/data/data/pg_hba.conf
  echo "host    all             all             0.0.0.0/0               md5" >> /var/lib/postgresql/data/data/pg_hba.conf
  
  echo Scheduling db maintentance : backup of all databases at 2 AM, vacuum at 3 AM, reindex at 4AM
  echo "0    2       *       *       *       /usr/local/bin/pg_dumpall --disable-triggers -U postgres | gzip -c > /backup/daily-backup.zip" >> /etc/crontabs/root
  echo "0    3       *       *       *       /usr/local/bin/vacuumdb -z -U postgres -a"  >> /etc/crontabs/root
  echo "0    4       *       *       *       /usr/local/bin/reindexdb -U postgres -a"  >> /etc/crontabs/root

  echo Creating pg_cron extension and setting postgres behaviour ...
  cp /tmp/postgresql.conf /var/lib/postgresql/data/data/postgresql.conf
  chmod 777 /var/lib/postgresql/data/data/postgresql.conf
  su -c "sleep 120; /usr/local/bin/psql -U postgres --command \"CREATE EXTENSION pg_cron;\" " postgres &
fi 

# start cron for maintenance tasks. Please note that if cron crashes (unlikely) that it will not automatically be restarted
crond & 

# start postgres as main docker process. If postgres crashes the container will automatically restart
su -c "./postgres -D /var/lib/postgresql/data/data" postgres
