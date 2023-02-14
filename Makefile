SHELL=/bin/bash

zoneDir    ?=/etc/bind
rndckey    ?=${zoneDir}/rndc.key

dnsdip     ?=127.0.0.1
forwarder  ?=8.8.8.8
domain     ?=local

FQDN       ?=test.${domain}
TTL        ?=3600
IP         ?=${dnsdip}

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
define NSUPDATE_CONTENT
server     ${dnsdip}
update delete ${FQDN}.          IN A
update add    ${FQDN}.   ${TTL} IN A ${IP}
send
endef
export NSUPDATE_CONTENT

define DEL_CONTENT
server     ${dnsdip}
update delete ${FQDN}.          IN A
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
				2019051402 ; serial
				1h         ; refresh
				15m        ; retry
				1d         ; expire
				1h         ; minimum
				)
			NS	${domain}.
${domain}.		A	${dnsdip}
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


start: ${rndckey}
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
	/etc/init.d/webmin start
webminStop:
	/etc/init.d/webmin stop
webminRestart:
	/etc/init.d/webmin restart
webminReload:
	/etc/init.d/webmin reload
