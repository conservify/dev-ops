FROM jboss/keycloak:12.0.2

ADD theme /opt/jboss/keycloak/themes/fk
RUN mkdir /opt/jboss/startup-scripts
ADD logging.properties /opt/jboss/keycloak/standalone/configuration/logging.properties
ADD standalone-ha.xml /opt/jboss/keycloak/standalone/configuration/standalone-ha.xml