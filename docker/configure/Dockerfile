FROM php:7.4-cli

RUN apt-get update && apt-get install -y \
    locales \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN locale-gen ja_JP.UTF-8 && localedef -f UTF-8 -i ja_JP ja_JP
ENV LANG ja_JP.UTF-8
ENV TZ Asia/Tokyo

WORKDIR /usr/src/app
COPY entrypoint.sh /
COPY app/ /usr/src/app/
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
