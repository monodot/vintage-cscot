#!/usr/local/bin/perl -w

# CSCOT.COM
# Generate weekly update mail and save to queue
# tdonohue, 12.01.05


# include modules
use strict;
use DBI;
use Text::Wrap;
use POSIX qw(strftime);
use Date::Calc qw(Today Add_Delta_Days Day_of_Week_to_Text Day_of_Week Month_to_Text Date_to_Text);
use cscot_settings;


my ($dbh);



# set up database variables
my $setting_db_schema = $cscot_settings::database{'schema'};
my $setting_db_username = $cscot_settings::database{'username'};
my $setting_db_password = $cscot_settings::database{'password'};


# make database connection
$dbh = DBI ->
  connect(
    "DBI:mysql:$setting_db_schema:127.0.0.1",
    "$setting_db_username",
    "$setting_db_password",
    {RaiseError=>1}
);


# disconnect from database server
$dbh->disconnect();

  


