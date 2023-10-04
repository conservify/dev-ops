FROM node:16.20.1

WORKDIR /app

RUN git clone https://github.com/conservify/logs-viewer.git
RUN cd logs-viewer && npm install

EXPOSE 3000

WORKDIR /app/logs-viewer

ADD config.js ./server/config.js

ENTRYPOINT [ "node_modules/.bin/babel-node", "server/server.js" ]
