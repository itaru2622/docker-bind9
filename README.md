## private DNS server with bind9 + dynamic DNS feature

## Requirement
   - OS: Linux
   - Software: docker, docker-compose

## docker image build


```bash
   # build
   #   zoneDir:   bind config folder to store named.conf (i.e /etc/bind)
   #   rootpwd:   password for root
   $ zoneDir=/etc/bind  rootpwd=changeme docker-compose build
```

## basic usage: start / stop

```bash
   # start
   #   dnsdip:    IP address of docker host
   #   forwarder: upstream DNS server IP to forward request as cache server.
   #   zoneDir:   bind config folder to store named.conf
   $ dnsdip=YourHostIP  forwarder=DNSIPinYourNW zoneDir=/etc/bind  docker-compose up

   # initialization and create your first zone.
   $ docker-compose exec bind9 bash -c "make initConf ; make addZone domain=local"

   # stop
   $ docker-compose down -v
```


## sample operation, to add new zone, A-record on demand (to examle.com)

   helper script: ${zoneDir}/Makefile in container

```bash
   $ docker-compose exec bind9 bash # do below after login to container's bash

   #    initialize zone when you want. (clear all exisiting records and zones)  (*A)
   $ make initConf

   #    add new zone(domain) on demand  (*B)
   $ make addZone domain=example.com

   #    add / update / delete recode (i.e A-record)
   $ make dynReg   fqdn=host1.subdomain.example.com  type='IN A'   v=192.168.0.1 # add new record when not exists.
   $ make dynReg   fqdn=host1.subdomain.example.com  type='IN A'   v=192.168.0.2 # update IP for fqdn
   $ make rmReg    fqdn=host1.subdomain.example.com  type='IN A'                 # remove record
      :

   #    confirm records in domain (by zone transfer)
   $ make getRecord domain=example.com

   #    store DDNS requests into zonefile, to freeze them ( i.e. backup ) (*C)
   $ make jnl2zone

```

## DNS Ops Alternatives.
 - the ops easier than other tools.
      - A initialize configurations
      - B adding domain/zone
      - C backup DDNS requests to zone file.
 - what you can do with other tools.
      - adding entry;          nsupdate (add multiple records from remote)
      - confirm zone entries:  dnz zone transfer ( dig axfr )
      - webmin x bind9 for management via GUI.

## bind9 with webmin
  - zoneDir has to be /etc/bind when using webmin for managing bind9
```bash
   $ make webminStart
   #    then you can access webmin via  http://${dnsdip}:10000/
   $ make webminReload
   $ make webminStop
```
