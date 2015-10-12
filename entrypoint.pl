#!/usr/bin/perl
# vim:set et ts=2 sw=2:

# Author : djluo
# version: 2.0(20150107)
#
# 初衷: 每个容器用不同用户运行程序,已方便在宿主中直观的查看.
# 需求: 1. 动态添加用户,不能将添加用户的动作写死到images中.
#       2. 容器内尽量不留无用进程,保持进程树干净.
# 问题: 如用shell的su命令切换,会遗留一个su本身的进程.
# 最终: 使用perl脚本进行添加和切换操作. 从环境变量User_Id获取用户信息.

use Cwd;
use strict;
#use English '-no_match_vars';

my $uid = 1000;
my $gid = 1000;
my $pwd = cwd();

$uid = $gid = $ENV{'User_Id'} if $ENV{'User_Id'} =~ /\d+/;

sub add_user {
  my ($name,$id)=@_;

  system("/usr/sbin/useradd",
    "-s", "/bin/false",
    "-d", "/var/empty/$name",
    "-U", "--uid", "$id",
    "$name");
}
unless (getpwuid("$uid")){
  add_user("nginx",  "1080");
  add_user("docker", "$uid");
}

system("chown docker.docker -R ./logs") if ( -d "./logs");

unless ( -f "/etc/php5/fpm/nginx.conf"){
  system("cp", "-a", "/example/djluo-phpinfo.php", "./html/");
  system("cp", "-a", "/example/djluo-mysql.php",   "./html/");
}

my @confs= ( "nginx.conf", "php-fpm.conf", "php.ini", "supervisord.conf");
for my $conf (@confs) {
  unless ( -f "/etc/php5/fpm/$conf") {
    system("cp", "-a", "/conf/$conf", "/etc/php5/fpm/");
    system("sed", "-i", "s%/path/to/dir%$pwd%", "/etc/php5/fpm/$conf");
    system("chgrp", "docker", "/etc/php5/fpm/$conf");
  }
}

# 切换当前运行用户,先切GID.
#$GID = $EGID = $gid;
#$UID = $EUID = $uid;
$( = $) = $gid; die "switch gid error\n" if $gid != $( ;
$< = $> = $uid; die "switch uid error\n" if $uid != $< ;

exec(@ARGV);
