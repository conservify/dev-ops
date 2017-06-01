FROM jenkins:2.46.3
USER root
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -yy libc6:i386
WORKDIR /tmp
# COPY slack.crt /tmp
# RUN keytool -noprompt -storepass asdfasdf -keystore cacerts -importcert -alias slack_child -file /tmp/slack.crt
# RUN mkdir /var/lib/.keystore
# RUN ls $JAVA_HOME && ls $JAVA_HOME/lib
# RUN cp $JAVE_HOME/lib/security/cacerts /var/lib/.keystore/cacerts
USER jenkins
