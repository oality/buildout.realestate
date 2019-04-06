FROM python:2.7-slim-stretch

ENV PIP=9.0.3 \
    ZC_BUILDOUT=2.11.4 \
    SETUPTOOLS=39.1.0 \
    WHEEL=0.31.1 \
    PLONE_MAJOR=5.1 \
    PLONE_VERSION=5.1.5 \
    LANG=fr_BE.UTF-8 \
    LANGUAGE=fr_BE:fr \
    LC_ALL=fr_BE.UTF-8

LABEL plone=$PLONE_VERSION \
    os="debian" \
    os.version="9" \
    name="Plone 5.1" \
    description="Plone image, based on Unified Installer" \
    maintainer="Benoit Suttor"

RUN useradd --system -m -d /plone -U -u 1000 plone \
 && mkdir -p /plone/ /data/filestorage /data/blobstorage

COPY base.cfg dev.cfg prod.cfg sources.cfg versions.cfg /plone/

RUN buildDeps="dpkg-dev git gcc libbz2-dev libc6-dev libjpeg62-turbo-dev libopenjp2-7-dev libpcre3-dev libssl-dev libtiff5-dev libxml2-dev libxslt1-dev wget zlib1g-dev" \
 && runDeps="gosu libjpeg62 libopenjp2-7 libtiff5 libxml2 libxslt1.1 lynx netcat poppler-utils rsync wv" \
 && apt-get update \
 && apt-get upgrade -y \
 && apt install -y locales \
 && apt-get install -y --no-install-recommends $buildDeps \
 && wget -O buildout-cache.tar.bz2 https://launchpad.net/plone/$PLONE_MAJOR/$PLONE_VERSION/+download/buildout-cache.tar.bz2  \
 && tar -jxf buildout-cache.tar.bz2 \
 && cp -rv ./buildout-cache/* /plone/ \
 && rm -rf ./buildout-cache* \
 && pip install pip==$PIP setuptools==$SETUPTOOLS zc.buildout==$ZC_BUILDOUT wheel==$WHEEL \
 && cd /plone \
 && ls -lah \
 && buildout -c prod.cfg \
 && ln -s /data/filestorage/ /plone/var/filestorage \
 && ln -s /data/blobstorage /plone/var/blobstorage \
 && mkdir /backups \
 && chown -R plone:plone /plone /data /backups \
 && ls -lah \
 && apt-get install -y --no-install-recommends $runDeps \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /plone/downloads/*

VOLUME /data

RUN sed -i -e 's/# fr_BE.UTF-8 UTF-8/fr_BE.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=fr_BE.UTF-8

COPY docker-initialize.py docker-entrypoint.sh /
RUN chmod +x docker-entrypoint.sh

EXPOSE 8080
WORKDIR /plone/

HEALTHCHECK --interval=1m --timeout=5s --start-period=1m \
  CMD nc -z -w5 127.0.0.1 8080 || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
