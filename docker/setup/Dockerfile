FROM node

RUN apt-get update && apt-get install -y \
    locales \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*


RUN locale-gen ja_JP.UTF-8 && localedef -f UTF-8 -i ja_JP ja_JP
ENV LANG ja_JP.UTF-8
ENV TZ Asia/Tokyo

WORKDIR /app
COPY entrypoint.sh /
COPY app/ /app/
RUN chmod +x /entrypoint.sh
RUN yarn install

ENTRYPOINT ["/entrypoint.sh"]
