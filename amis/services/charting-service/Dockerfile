FROM conservify/fk-charting:main

ADD ./startup.sh /usr/local/bin/startup.sh
RUN chmod u+x /usr/local/bin/startup.sh

ENTRYPOINT [ "/usr/local/bin/startup.sh" ]