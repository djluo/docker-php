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
my $domain  = "www.example.com";
my $version = 0;
my $mysql_lists = "localhost:3306";

$version     = $ENV{'VER'}     if $ENV{'VER'};
$domain      = $ENV{'Domain'}  if $ENV{'Domain'};
$uid = $gid  = $ENV{'User_Id'} if $ENV{'User_Id'} =~ /\d+/;
$mysql_lists = $ENV{'Mysql_Lists'}  if $ENV{'Mysql_Lists'};

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

system("chown docker.docker -R ./log")  if ( -d "./log");
system("chown docker.docker -R ./logs") if ( -d "./logs");

my $confp = "/etc/php5/fpm/";
my @confs = ( "nginx.conf", "php-fpm.conf", "php.ini", "supervisord.conf");

for my $conf (@confs) {
  unless ( -f "$confp/$conf") {
    system("cp", "-a", "/conf/$conf", "$confp/");
    system("sed", "-i", "s%/path/to/dir%$pwd%", "$confp/$conf");

    if ( $conf eq "nginx.conf") {
      system("sed", "-i", "/server_name/s%www.example.com%$domain%", "$confp/$conf");
      #system("cp",  "-a", "/example/delete-me-phpinfo.php", "./html/");
      #system("cp",  "-a", "/example/delete-me-mysql.php",   "./html/");
    }

    system("chgrp", "docker", "$confp/$conf");
  }
}

unless ( -f "$pwd/html/config.sample.inc.php"){
  system("tar", "xf", "/phpmyadmin.tar.gz", "-C", "/");
  system("rsync", "-avl", "--del", "/phpMyAdmin-". $version . "-all-languages/", "$pwd/html/");
  system("rm", "-rf", "/phpMyAdmin-". $version . "-all-languages/");
}

my $secret="$pwd/html/blowfish_secret.inc.php";
unless ( -f "$secret" ){
  my $pw = `openssl rand -base64 32`;
     $pw = substr($pw, 0, 20);
  open(SEC,'>', "$secret") or die "open $secret: error";
  print SEC '<?php'."\n";
  print SEC '$cfg[\'blowfish_secret\'] =\'' . $pw ."\';\n";
  print SEC '$cfg[\'UploadDir\'] = \'\';' ."\n";
  print SEC '$cfg[\'SaveDir\'] = \'\';'   ."\n";
  close(SEC);
}

my $config = "$pwd/html/config.inc.php";
system("cp", "$config", "$config.".time() ) if ( -f "$config" );
open(INC,'>', "$config") or die "open $config: error";

print INC '<?php'."\n";
print INC 'include "' . $secret . "\";\n";
print INC '$i = 0;' . "\n";

my @lists = split(/,/, $mysql_lists);
for my $host (@lists) {
  my ($name,$port) = split(/:/, $host);

  print INC '$i++;' . "\n";
  print INC '$cfg[\'Servers\'][$i][\'auth_type\'] = \'cookie\';' . "\n";
  print INC '$cfg[\'Servers\'][$i][\'host\'] = \'' . $name .    "\';\n";
  print INC '$cfg[\'Servers\'][$i][\'port\'] = \'' . $port .    "\';\n";
  print INC '$cfg[\'Servers\'][$i][\'connect_type\'] = \'tcp\';' . "\n";
  print INC '$cfg[\'Servers\'][$i][\'compress\'] = false;'       . "\n";
  print INC '$cfg[\'Servers\'][$i][\'AllowNoPassword\'] = false;'. "\n";
}

close(INC);


# 切换当前运行用户,先切GID.
#$GID = $EGID = $gid;
#$UID = $EUID = $uid;
$( = $) = $gid; die "switch gid error\n" if $gid != $( ;
$< = $> = $uid; die "switch uid error\n" if $uid != $< ;

exec(@ARGV);
