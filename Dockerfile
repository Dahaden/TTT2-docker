# BASE IMAGE
FROM ubuntu:questing

LABEL maintainer="dahaden"
LABEL description="A structured Garry's Mod dedicated server under a ubuntu linux image"

# INSTALL NECESSARY PACKAGES
RUN apt-get update && apt-get -y --no-install-recommends --no-install-suggests install \
    wget lib32gcc-s1 lib32stdc++6 ca-certificates screen tar bzip2 gzip unzip gdb iproute2

# Original
# RUN apt-get update && apt-get -y --no-install-recommends --no-install-suggests install \
#     wget lib32ncurses5 lib32gcc1 lib32stdc++6 lib32tinfo5 ca-certificates screen tar bzip2 gzip unzip gdb

# CLEAN UP
RUN apt-get clean
RUN rm -rf /tmp/* /var/lib/apt/lists/*

# SET STEAM USER
RUN useradd -d /home/gmod -m steam
USER steam
RUN mkdir /home/gmod/server && mkdir /home/gmod/steamcmd

# INSTALL STEAMCMD
RUN wget -P /home/gmod/steamcmd/ https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xvzf /home/gmod/steamcmd/steamcmd_linux.tar.gz -C /home/gmod/steamcmd \
    && rm -rf /home/gmod/steamcmd/steamcmd_linux.tar.gz

# SETUP STEAMCMD update txt
# COPY assets/update.txt /home/gmod/update.txt
RUN wget -P /home/gmod https://raw.githubusercontent.com/Dahaden/ttt2-docker/refs/heads/main/assets/update.txt
RUN /home/gmod/steamcmd/steamcmd.sh +runscript /home/gmod/update.txt +quit

# SETUP BINARIES FOR x32 and x64 bits
RUN mkdir -p /home/gmod/.steam/sdk32 \
    && cp -v /home/gmod/steamcmd/linux32/steamclient.so /home/gmod/.steam/sdk32/steamclient.so \
    && mkdir -p /home/gmod/.steam/sdk64 \
    && cp -v /home/gmod/steamcmd/linux64/steamclient.so /home/gmod/.steam/sdk64/steamclient.so

# CREATE DATABASE FILE
RUN touch /home/gmod/server/garrysmod/sv.db

# CREATE CACHE FOLDERS
RUN mkdir -p /home/gmod/server/steam_cache/content && mkdir -p /home/gmod/server/garrysmod/cache/srcds

# PORT FORWARDING
# https://developer.valvesoftware.com/wiki/Source_Dedicated_Server#Connectivity
EXPOSE 27015
EXPOSE 27015/udp
EXPOSE 27005/udp

# SET ENVIRONMENT VARIABLES
ENV MAXPLAYERS="16"
ENV GAMEMODE="sandbox"
ENV MAP="gm_construct"
ENV PORT="27015"

# SET GMOD MOUNT CONTENT
VOLUME /home/gmod/server/garrysmod/cfg

# ADD START SCRIPT
# COPY --chown=steam:steam assets/start.sh /home/gmod/start.sh
RUN wget -P /home/gmod https://raw.githubusercontent.com/Dahaden/ttt2-docker/refs/heads/main/assets/start.sh
RUN chmod +x /home/gmod/start.sh

# CREATE HEALTH CHECK
# COPY --chown=steam:steam assets/health.sh /home/gmod/health.sh
RUN wget -P /home/gmod https://raw.githubusercontent.com/Dahaden/ttt2-docker/refs/heads/main/assets/health.sh
RUN chmod +x /home/gmod/health.sh

HEALTHCHECK --start-period=10s \
    CMD /home/gmod/health.sh

# START THE SERVER
CMD ["/home/gmod/start.sh"]