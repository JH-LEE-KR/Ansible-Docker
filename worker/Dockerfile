# Dockerfile
FROM ubuntu:20.04

LABEL name="Jaeho Lee"
LABEL email="dlwogh9344@khu.ac.kr"

# Disable interactive prompts from Apt
ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Seoul

ARG ANSIBLE_USER
ARG PASSWORD

SHELL ["/bin/bash", "-c"]

# Add user and set password
RUN useradd -m -s /bin/bash ${ANSIBLE_USER} \
    && echo "${ANSIBLE_USER}:${PASSWORD}" | chpasswd \
    && usermod -aG sudo ${ANSIBLE_USER} \
    && mkdir /home/${ANSIBLE_USER}/.ssh \
    && chown -R ${ANSIBLE_USER}.${ANSIBLE_USER} /home/${ANSIBLE_USER} \
    && chmod -R 755 /home/${ANSIBLE_USER}

# Install packages and set ssh
RUN sed -i "s/archive.ubuntu.com/mirror.kakao.com/g" /etc/apt/sources.list
RUN apt-get update \
  && apt-get install -y openssh-server \
  && apt-get install -y sshpass \
  && apt-get install -y sudo \
  && apt install -y python3.8 \
  && apt install -y python3-pip \
  && alias python=python3.* \
  && sed -i "34s/.*/PermitRootLogin yes/" /etc/ssh/sshd_config \
  && echo "root:${PASSWORD}" | chpasswd 

# Set sudoers to behave same as the default user
RUN echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# System init script
EXPOSE 22
ADD ../init.sh /init.sh
RUN chmod +x /init.sh
ENTRYPOINT [ "/init.sh" ]