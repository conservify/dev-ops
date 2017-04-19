FROM nginx
COPY nginx /etc/nginx
COPY letsencrypt /etc/letsencrypt
RUN apt-get update && apt-get install -yy curl
RUN mkdir /var/lib/jenkins_artifacts
RUN ls -al /etc/nginx/
