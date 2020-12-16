#!/bin/bash

# Example of enabling after the fact. This is just for posterity.

docker exec keycloak /opt/jboss/keycloak/bin/jboss-cli.sh --connect --command='/subsystem=logging/json-formatter=json:add(exception-output-type=formatted, pretty-print=false, meta-data={label=value})'
docker exec keycloak /opt/jboss/keycloak/bin/jboss-cli.sh --connect --command='/subsystem=logging/console-handler=CONSOLE:write-attribute(name=named-formatter, value=json)'
