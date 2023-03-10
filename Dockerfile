FROM debian:bullseye-slim

## Define build arguments.
ARG ROOTHOME='/root/home'
ARG DATAPATH="/usr/src/app/db"

## Install dependencies.
RUN apt-get update && apt-get install -y \
  build-essential pkg-config libssl-dev iproute2 curl \
  git jq lsof man neovim netcat procps qrencode tmux

## Install Rust.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

## Clone and build relay from source, then copy to bin.
WORKDIR /tmp

RUN git clone https://git.sr.ht/\~gheartsfield/nostr-rs-relay

RUN cd nostr-rs-relay \
  && . /root/.cargo/env \
  && cargo build -r \
  && cp ./target/release/nostr-rs-relay /usr/local/bin \
  && rm -r /tmp/*

## Install ngrok.
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null 
RUN echo "deb https://ngrok-agent.s3.amazonaws.com bullseye main" | tee /etc/apt/sources.list.d/ngrok.list 
RUN apt update && apt install ngrok

## Uncomment this if you want to install additional packages.
#RUN apt-get install -y <packages>

## Uncomment this if you want to wipe all repository lists.
#RUN rm -rf /var/lib/apt/lists/*

## Copy over runtime.
COPY image /
COPY config /config/
COPY home /root/home/

## Link entrypoint script to bin.
RUN mkdir -p /usr/bin
RUN ln -s $ROOTHOME/entrypoint.sh /usr/bin/entrypoint

## Add custom profile to bashrc.
RUN PROFILE="$ROOTHOME/.profile" \
  && printf "\n[ -f $PROFILE ] && . $PROFILE\n\n" >> /root/.bashrc

## Setup Environment.
ENV PATH="$ROOTHOME/bin:/root/.local/bin:$PATH"
ENV DATA="$DATAPATH"

WORKDIR /root/home

ENTRYPOINT [ "entrypoint" ]
