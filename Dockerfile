FROM jenkins/jenkins:lts

USER root

# Install necessary tools including gosu for proper user switching
RUN apt-get update && \
    apt-get install -y curl tini wget gnupg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    DEBIAN_CODENAME=$(lsb_release -cs) && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian ${DEBIAN_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install gosu
RUN set -eux; \
    apt-get update; \
    apt-get install -y gosu; \
    rm -rf /var/lib/apt/lists/*; \
    # Verify that gosu works
    gosu nobody true

# Create custom user with specific UID/GID
RUN groupadd -g 1001 rrkts_jenkins && \
    useradd -u 1001 -g rrkts_jenkins -m -s /bin/bash rrkts_jenkins && \
    mkdir -p /home/rrkts_jenkins && \
    chown -R rrkts_jenkins:rrkts_jenkins /home/rrkts_jenkins

RUN mkdir -p /usr/share/jenkins/ref/plugins && \
    chown -R rrkts_jenkins:rrkts_jenkins /usr/share/jenkins/ref && \
    chown -R rrkts_jenkins:rrkts_jenkins /usr/share/jenkins/ref/plugins

# Create the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create directories with proper permissions
RUN mkdir -p /var/jenkins_home && \
    chown -R rrkts_jenkins:rrkts_jenkins /var/jenkins_home

# We keep USER as root so that the entrypoint script can set permissions 
# and then switch to the rrkts_jenkins user

ENTRYPOINT ["/entrypoint.sh"]
