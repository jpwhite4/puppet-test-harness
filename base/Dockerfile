FROM centos:centos7.9.2009
COPY . /build
RUN /build/install.sh && rm -rf /build
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
