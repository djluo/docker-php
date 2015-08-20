FROM       docker.xlands-inc.com/baoyu/debian
MAINTAINER djluo <dj.luo@baoyugame.com>

RUN export http_proxy="http://172.17.42.1:8080/" \
    && export DEBIAN_FRONTEND=noninteractive     \
    && apt-get update \
    && apt-get install -y php5 php5-fpm php5-cli php5-mysql php5-mcrypt php5-gd \
    && apt-get clean \
    && unset http_proxy DEBIAN_FRONTEND \
    && rm -rf usr/share/locale \
    && rm -rf usr/share/man    \
    && rm -rf usr/share/doc    \
    && rm -rf usr/share/info   \
    && find var/lib/apt -type f -exec rm -f {} \;

ADD ./entrypoint.pl /entrypoint.pl

ENTRYPOINT ["/entrypoint.pl"]
CMD        ["/usr/sbin/php5-fpm", "--fpm-config", "/etc/php5/fpm/php-fpm.conf"]
