#!/usr/local/bin/perl -w

# CSCOT.COM
# Settings package
# tdonohue, 12.01.05

# use the ip address 127.0.0.1 instead of localhost.
# If needed, the port is 3306.


# the all-important line
use strict;


# define package name
package cscot_settings;


# db settings
our %database = ();
%database = (
  schema => 'cscotco_forums',
  username => 'cscotco',
  password => 'henlohenlohenlo',
  hostname => '127.0.0.1'
);


# flickr settings
our %flickr = ();
%flickr = (
  api_key => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  user_id => '12345668899@N00'
);


# downloads.cscot.com ftp settings
our %downloads = ();
%downloads = (
  hostname => 'downloads.example.com',
  ftphost => '1.2.3.4',
  username => 'redacted',
  password => 'redacted'
);
