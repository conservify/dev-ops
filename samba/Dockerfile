FROM appcontainers/samba
RUN groupadd jlewallen -g 1000
RUN useradd -ms /bin/bash jlewallen -u 1000 -g 1000
COPY smb.conf /etc/samba
