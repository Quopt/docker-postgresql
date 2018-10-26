# docker-postgresql
A docker postgres container that automatically backs itself up and maintains itself

Please note that this is a template and not intended for production use. Change to whatever you need first and carefully review the results. 

This postgres container is based of the offical postgres alpine image. I have used version 10.5 since this is the latest version of postgres available that is not beta. 

On postgres the following additional software is installed : 
- cron
- pg_cron

the pg_cron plugin will automatically be installed after the container is first started. cron will be started as well with 3 automated jobs : backup, vacuum, refresh statistics/rebuild indexes. They run every night at 2/3/4 AM.

The password assigned to the postgres user is not set to a default password, but generated using the current date. If security is your thing then you would probably want to login to your container asap after creation and change this. Check the logs for the password.

Optionally you may set the PG_PASSWORD environment variable. In which case this will be used for your password. 

An example yml file to start this container with would be (assuming that there is a data folder on your docker server where the databases files and backups are stored) : 

```version: "2"
services:
  postgresql:
    image: my-postgresql-image
    container_name: my-postgresql
    networks:
     - my_network
    ports:
     - 5432:5432
    volumes:
     - /data/postgresql/data:/var/lib/postgresql/data:z
     - /data/postgresql/data/backup:/backup:z
    restart: always
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000

networks:
  my_network:
       driver: bridge
```


All code provided under the AGPL-3.0 license. Use at your own risk. 
