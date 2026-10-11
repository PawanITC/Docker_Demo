# Jenkins LTS with common pipeline plugins baked into the image.
FROM jenkins/jenkins:lts-jdk21

# Install plugins at BUILD time so containers start ready to use.
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Jobs, credentials, plugins and config all live in JENKINS_HOME.
VOLUME /var/jenkins_home

# 8080 = web UI, 50000 = inbound agents.
EXPOSE 8080 50000
