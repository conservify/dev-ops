FROM jenkins:2.60.3
USER root
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -yy libc6:i386 build-essential 
WORKDIR /tmp
RUN wget https://storage.googleapis.com/golang/go1.9.1.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.9.1.linux-amd64.tar.gz
RUN wget https://nodejs.org/dist/v6.11.4/node-v6.11.4-linux-x64.tar.xz && tar -C /usr/local -xf node-v6.11.4-linux-x64.tar.xz && mv /usr/local/node-* /usr/local/node
# COPY slack.crt /tmp
# RUN keytool -noprompt -storepass asdfasdf -keystore cacerts -importcert -alias slack_child -file /tmp/slack.crt
# RUN mkdir /var/lib/.keystore
# RUN ls $JAVA_HOME && ls $JAVA_HOME/lib
# RUN cp $JAVE_HOME/lib/security/cacerts /var/lib/.keystore/cacerts
USER jenkins
