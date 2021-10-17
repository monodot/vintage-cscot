#!/usr/local/bin/perl -w

# CSCOT.COM
# Get all sets from our Flickr account using the API
# tdonohue, 21.02.06


# include modules
use strict;
use cscot_settings;
use DBI;
use Flickr::API;
use LWP::Simple;
use XML::Parser::Lite::Tree::XPath;
use Data::Dumper;


# set constants
use constant TRUE => 1;
use constant FALSE => 0;


# app settings
my $setting_local_img_path = "/home2/cscotco/public_html/beta/images/photostream/";
my $setting_db_tablename = "cscot_flickrphoto";


# set up database and flickr variables
my $setting_db_schema = $cscot_settings::database{'schema'};
my $setting_db_username = $cscot_settings::database{'username'};
my $setting_db_password = $cscot_settings::database{'password'};
my $setting_db_hostname = $cscot_settings::database{'hostname'};
my $setting_remote_ftphost = $cscot_settings::downloads{'ftphost'};
my $setting_remote_username = $cscot_settings::downloads{'username'};
my $setting_remote_password = $cscot_settings::downloads{'password'};
my $setting_flickr_api_key = $cscot_settings::flickr{'api_key'};
my $setting_flickr_user_id = $cscot_settings::flickr{'user_id'};


# declare variables
my ($flickr_api, $flickr_response, $flickr_tree, @nodes);
my ($set_id, $set_photos, $set_title, $set_description, $set_primary, $set_secret, $set_server, @photosets, %photoids);
my (%local_photos, $local_photoid, $local_lastupdate);
my ($dbh, $qry_getphotos, $qry_local_upd, $qry_local_ins);

# connect to database
$dbh = DBI ->
  connect(
    "DBI:mysql:$setting_db_schema:$setting_db_hostname",
    "$setting_db_username",
    "$setting_db_password",
    {RaiseError=>1}
);

# get complete list of photo_ids & last_modified times from local db
$qry_getphotos = $dbh->prepare("SELECT PhotoID, LastUpdate FROM $setting_db_tablename ORDER BY PhotoID ASC");
$qry_getphotos->execute();
if ($qry_getphotos->rows > 0) {
  while (($local_photoid, $local_lastupdate) = $qry_getphotos->fetchrow_array) {
    $local_photos{$local_photoid} = $local_lastupdate;
  }
}

# connect to flickr
$flickr_api = new Flickr::API({'key' => $setting_flickr_api_key});
$flickr_response = $flickr_api->execute_method('flickr.people.getPublicPhotos', {
  'user_id' => $setting_flickr_user_id},
  'extras' => 'last_update');

# check whether request was a success
if ($flickr_response->{success} == 0) {
  die "Error $flickr_response->{error_code}: $flickr_response->{error_message}";
}

# go through first page
$flickr_tree = new XML::Parser::Lite::Tree::XPath($flickr_response->{tree});
@nodes = $flickr_tree->select_nodes('/photos');
print Dumper (@nodes);
die;

# fuck knows what to do here
#   need to check if @nodes only contains one element (i.e. the main <photos> tag)
#   then glean the "total" attribute off it to find our number of photos

#if ($nodes == 1) {
#  print "hello";
#  print $nodes[0]->{attributes}->{lastupdate};
#}



# disconnect from database server
$dbh->disconnect();

die;
  


# get first list of photos
# set number of pages
# for each page
  # 




