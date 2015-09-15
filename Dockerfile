FROM       docker.xlands-inc.com/baoyu/debian
MAINTAINER djluo <dj.luo@baoyugame.com>

RUN export http_proxy="http://172.17.42.1:8080/" \
    && export DEBIAN_FRONTEND=noninteractive     \
    && apt-get update \
    && apt-get install -y php5 php5-fpm php5-cli php5-mysql php5-mcrypt php5-gd supervisor \
    && apt-get clean \
    && unset http_proxy DEBIAN_FRONTEND \
    && rm -rf usr/share/locale \
    && rm -rf usr/share/man    \
    && rm -rf usr/share/doc    \
    && rm -rf usr/share/info   \
    && find var/lib/apt -type f -exec rm -f {} \;

COPY ./entrypoint.pl /
COPY ./conf/         /conf
ENV PHP_INI_SCAN_DIR /etc/php5/conf.d

ENTRYPOINT ["/entrypoint.pl"]
CMD        ["/usr/bin/supervisord", "-n", "-c", "/etc/php5/fpm/supervisord.conf"]
