#!/usr/local/bin/perl -w

# CSCOT.COM
# Upload file to server
# tdonohue, 12.01.05

# param 0 - host
my $param_host = $ARGV[0];

# param 1 - username
my $param_username = $ARGV[1];

# param 2 - password
my $param_password = $ARGV[2];

# param 3 - local path and file
my $param_localfile = $ARGV[3];

# param 4 - remote path
my $param_remotepath = $ARGV[4];

# param 5 - remote filename
my $param_remotefile = $ARGV[5];

# param 6 - mode (ascii/binary)
my $param_mode = $ARGV[6];


use Net::FTP;

$ftp = Net::FTP->new($param_host, Debug => 0)
  or die "Cannot connect to ".$param_host.": $@";

$ftp->login($param_username, $param_password)
  or die "Cannot login ", $ftp->message;

$ftp->cwd($param_remotepath)
  or die "Cannot change working directory ", $ftp->message;

$ftp->put($param_localfile, $param_remotefile)
  or die "Cannot upload remote file ", $ftp->message;

$ftp->quit;

    