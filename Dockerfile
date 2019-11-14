FROM ubuntu:19.04

# Packages
RUN apt-get clean && apt-get update && apt-get install --no-install-recommends -y \
    gpg \
    curl \
    wget \
    lsb-release \
    add-apt-key \
    ca-certificates \
    dumb-init \
    tmux \
    net-tools \
    nano \
    openssh-client \
    # Common SDK
    git \
    sudo \
    gdb \
    pkg-config \
    build-essential \
    # Node SDK
    nodejs \
    npm \
    # Python SDK
    python3 \
    python3-dev \
    python3-setuptools \
    python3-pip \
    python3-wheel \
    python3-pylint-common \
    # Chromium
    chromium-browser \
    # Code Server
    bsdtar \
    openssl \
    locales \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# CF CLI
#RUN curl -sS -o - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add \
#    && echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list \
#    && apt-get update && apt-get install --no-install-recommends -y cf-cli \
#    && rm -rf /var/lib/apt/lists/*

# Docker
RUN curl -sSL https://get.docker.com/ | sh
RUN export DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4) # "
RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# Helm CLI
ENV HELM_VERSION="v2.14.3"
RUN wget -q https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm
# RUN curl "https://raw.githubusercontent.com/helm/helm/master/scripts/get --version 2.13.1" | bash

# Kubectl CLI
RUN curl -sL "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# Azure CLI
#RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null \
#    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list \
#    && apt-get update && apt-get install --no-install-recommends -y azure-cli \
#    && rm -rf /var/lib/apt/lists/*

# Python packages
RUN python3 -m pip install --upgrade setuptools \
    && python3 -m pip install wheel \
    && python3 -m pip install -U pylint autopep8 flake8

# Golang SDK
RUN curl -sL https://dl.google.com/go/go1.13.linux-amd64.tar.gz | tar -zx -C /usr/local

# Java SDK
#RUN apt-get update && apt-get install --no-install-recommends -y \
#    default-jre-headless \
#    default-jdk-headless \
#    maven \
#    gradle \
#    && rm -rf /var/lib/apt/lists/*

# .NET Core SDK
# RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
# RUN echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/prod $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/microsoft-prod.list
# RUN apt-get update && apt-get install --no-install-recommends -y \
#    libunwind8 \
#    dotnet-sdk-2.2 \
#    && rm -rf /var/lib/apt/lists/*

# Chrome
# RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add
# RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
# RUN apt-get update && apt-get install --no-install-recommends -y \
#    google-chrome-stable \
#    && rm -rf /var/lib/apt/lists/*

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
ENV DISABLE_TELEMETRY true

# RUN export CODE_VERSION=$(curl --silent "https://api.github.com/repos/cdr/code-server/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")') \
#     && curl -sL https://github.com/cdr/code-server/releases/download/${CODE_VERSION}/code-server${CODE_VERSION}-linux-x64.tar.gz | tar --strip-components=1 -zx -C /usr/local/bin code-server${CODE_VERSION}-linux-x64/code-server

RUN export CODE_VERSION=2.1688-vsc1.39.2 \
    && export CODE_ARCH=linux-x86_64 \
    && curl -sL https://github.com/cdr/code-server/releases/download/${CODE_VERSION}/code-server${CODE_VERSION}-${CODE_ARCH}.tar.gz | tar --strip-components=1 -zx -C /usr/local/bin code-server${CODE_VERSION}-${CODE_ARCH}/code-server

# Setup User
RUN groupadd --gid 1024 -r coder \
    && useradd -m -r coder -g coder -s /bin/bash \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
USER coder

# Setup User Go Environment
# RUN mkdir /home/coder/go
# ENV GOPATH "/home/coder/go"
ENV PATH "${PATH}:/usr/local/go/bin:/home/coder/go/bin"

# Setup Uset .NET Environment
# ENV DOTNET_CLI_TELEMETRY_OPTOUT "true"
# ENV MSBuildSDKsPath "/usr/share/dotnet/sdk/2.2.202/Sdks"
# ENV PATH "${PATH}:${MSBuildSDKsPath}"

# Setup User Visual Studio Code Extentions
ENV VSCODE_USER "/home/coder/.local/share/code-server/User"
ENV VSCODE_EXTENSIONS "/home/coder/.local/share/code-server/extensions"

RUN mkdir -p ${VSCODE_USER}
COPY --chown=coder:coder settings.json /home/coder/.local/share/code-server/User/

# Setup Go Extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/go \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode/vsextensions/Go/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/go extension

# Setup Python Extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/python \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/python/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/python extension

# Setup Java Extension
#RUN mkdir -p ${VSCODE_EXTENSIONS}/java \
#    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/redhat/vsextensions/java/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/java extension

#RUN mkdir -p ${VSCODE_EXTENSIONS}/java-debugger \
#    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscjava/vsextensions/vscode-java-debug/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/java-debugger extension

#RUN mkdir -p ${VSCODE_EXTENSIONS}/java-test \
#    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscjava/vsextensions/vscode-java-test/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/java-test extension

#RUN mkdir -p ${VSCODE_EXTENSIONS}/maven \
#    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscjava/vsextensions/vscode-maven/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/maven extension

# Setup Kubernetes Extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/yaml \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/redhat/vsextensions/vscode-yaml/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/yaml extension

RUN mkdir -p ${VSCODE_EXTENSIONS}/kubernetes \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-kubernetes-tools/vsextensions/vscode-kubernetes-tools/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/kubernetes extension

RUN helm init --client-only

# Setup Browser Preview
RUN mkdir -p ${VSCODE_EXTENSIONS}/browser-debugger \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/msjsdiag/vsextensions/debugger-for-chrome/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/browser-debugger extension

RUN mkdir -p ${VSCODE_EXTENSIONS}/browser-preview \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/auchenberg/vsextensions/vscode-browser-preview/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/browser-preview extension

# Setup GitLens
RUN mkdir -p ${VSCODE_EXTENSIONS}/gitlens \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/eamodio/vsextensions/gitlens/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/gitlens extension

# Setup Ansible Extension
# RUN mkdir -p ${VSCODE_EXTENSIONS}/ansible \
#     && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscoss/vsextensions/vscode-ansible/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/ansible extension

# Setup Docker Extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/docker \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-azuretools/vsextensions/vscode-docker/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/docker extension

# Setup Remote Development
RUN mkdir -p ${VSCODE_EXTENSIONS}/remote \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode-remote/vsextensions/vscode-remote-extensionpack/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/remote extension

# Setup OpenAPI (Swagger) editor
RUN mkdir -p ${VSCODE_EXTENSIONS}/swagger \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/42Crunch/vsextensions/vscode-openapi/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/swagger extension

# Setup Settings Sync
#RUN mkdir -p ${VSCODE_EXTENSIONS}/settings-sync \
#    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/Shan/vsextensions/code-settings-sync/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/settings-sync extension

# Setup PlantUML
RUN mkdir -p ${VSCODE_EXTENSIONS}/plantuml \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/jebbs/vsextensions/plantuml/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/plantuml extension

# Setup IntelliCode
RUN mkdir -p ${VSCODE_EXTENSIONS}/intellicode \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/VisualStudioExptTeam/vsextensions/vscodeintellicode/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/intellicode extension

# Setup Better Jinja
RUN mkdir -p ${VSCODE_EXTENSIONS}/jinjahtml \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/samuelcolvin/vsextensions/jinjahtml/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/jinjahtml extension

# Setup DotEnv
RUN mkdir -p ${VSCODE_EXTENSIONS}/dotenv \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/mikestead/vsextensions/dotenv/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/dotenv extension


# Setup User Workspace
RUN mkdir -p /home/coder/project

WORKDIR /home/coder/project

EXPOSE 8080

ENTRYPOINT ["dumb-init", "code-server"]
