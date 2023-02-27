SHELL=/bin/bash

zoneDir   ?=/etc/bind
rndckey   ?=${zoneDir}/rndc.key

dnsdip    ?=127.0.0.1
forwarder ?=8.8.8.8
domain    ?=local

fqdn      ?=test.${domain}
ttl       ?=3600
type      ?=IN A
v         ?=${dnsdip}

BASE_SERIAL ?=$(shell date +%Y%m%d%H)

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
define NSUPDATE_CONTENT
server     ${dnsdip}
update delete ${fqdn}.          ${type}
update add    ${fqdn}.   ${ttl} ${type} ${v}
send
endef
export NSUPDATE_CONTENT

define DEL_CONTENT
server     ${dnsdip}
update delete ${fqdn}.          ${type}
send
endef
export DEL_CONTENT
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
define TEMPLATE_ZONE
; bind9 DNS Server Zone file
;    domainain: ${domain}
;    server:    ${dnsdip}
;
$$TTL 3D

@			IN SOA	${domain}. root.${domain}. (
				${BASE_SERIAL} ; serial
				1h         ; refresh
				15m        ; retry
				1d         ; expire
				1h         ; minimum
				)
			IN NS	${domain}.
${domain}.		IN A	${dnsdip}
endef
export TEMPLATE_ZONE
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
define INITIAL_NAMED
include "${rndckey}";
controls {
        inet 127.0.0.1 allow { 127.0.0.1; } keys { "rndc-key"; };
};
options {
        directory         "${zoneDir}";
        // UDP 53, from any
        listen-on         { any; };
        // HTTP 80, from any
        listen-on  port 80  tls none http default  { any; };
        listen-on-v6      { none; };
        forwarders        { ${forwarder} ; };  # { 8.8.8.8; };
        allow-recursion   { any; };
        allow-query       { any; };
        allow-query-cache { any; };
        allow-transfer    { any; };
};
endef
export INITIAL_NAMED

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
define TEMPLATE_NAMED_ENTRY
zone "${domain}" { type master; file "zone-${domain}"; allow-query { 0.0.0.0/0; }; allow-update { 0.0.0.0/0; }; allow-transfer { 0.0.0.0/0; }; };
endef
export TEMPLATE_NAMED_ENTRY
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

all: start

catConf:
	more ${zoneDir}/named.conf ${zoneDir}/zone-${domain} | cat

getRecord:
	-dig @${dnsdip} ${domain}. axfr
dynReg:
	echo "$${NSUPDATE_CONTENT}" | nsupdate
rmReg:
	echo "$${DEL_CONTENT}" | nsupdate


# 88888888888888888888888888888888888888888888888888888888888


start:: ${rndckey} initConf addZone
	named -4 -g -c ${zoneDir}/named.conf

${rndckey}:
	rndc-confgen -a -c ${rndckey}
	chmod 644  ${rndckey}

# make initConf
initConf: ${rndckey}
	rm -f ${zoneDir}/zone-* ${zoneDir}/managed-keys.bind*
	echo "$${INITIAL_NAMED}" > ${zoneDir}/named.conf

# make addZone domain=whatever.youwant
addZone::
	@echo "$${TEMPLATE_NAMED_ENTRY}" >> ${zoneDir}/named.conf
	@echo "$${TEMPLATE_ZONE}"         > ${zoneDir}/zone-${domain}
	-rndc -k ${rndckey} reload
addZone:: catConf

jnl2zone:
	rndc -k ${rndckey} freeze
	rm -f ${zoneDir}/*.jnl
	rndc -k ${rndckey} thaw

#webmin
webminStart:
	/usr/bin/webmin server start
webminStop:
	/usr/bin/webmin server stop
webminRestart:
	/usr/bin/webmin server restart
webminReload:
	/usr/bin/webmin server reload
