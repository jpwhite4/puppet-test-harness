ARG PTEST_VERSION
FROM joetest:base-${PTEST_VERSION}
RUN yum install -y puppetserver
RUN sed -i 's/-Xms2g -Xmx2g/-Xms1g -Xmx1g/' /etc/sysconfig/puppetserver
COPY ./xms-puppet/code /etc/puppetlabs/code
COPY ./xms-puppet/bin/install-modules.sh /usr/local/bin/install-modules.sh
ENV PATH="${PATH}:/opt/puppetlabs/bin"
RUN /usr/local/bin/install-modules.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
