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
my $setting_local_img_path = "/home2/cscotco/public_html/beta/images/photosets/";
my $setting_db_tablename = "cscot_flickrset";


# set up database and flickr variables
my $setting_db_schema = $cscot_settings::database{'schema'};
my $setting_db_username = $cscot_settings::database{'username'};
my $setting_db_password = $cscot_settings::database{'password'};
my $setting_db_hostname = $cscot_settings::database{'hostname'};
my $setting_flickr_api_key = $cscot_settings::flickr{'api_key'};
my $setting_flickr_user_id = $cscot_settings::flickr{'user_id'};


# declare variables
my ($flickr_api, $flickr_response, $flickr_tree, @nodes);
my ($set_id, $set_photos, $set_title, $set_description, $set_primary, $set_secret, $set_server, @photosets, %photoids);
my (%local_photosets, $local_setid);
my ($dbh, $qry_getsets, $qry_local_upd, $qry_local_ins);

# connect to database
$dbh = DBI ->
  connect(
    "DBI:mysql:$setting_db_schema:$setting_db_hostname",
    "$setting_db_username",
    "$setting_db_password",
    {RaiseError=>1}
);

# connect to flickr
$flickr_api = new Flickr::API({'key' => $setting_flickr_api_key});
$flickr_response = $flickr_api->execute_method('flickr.photosets.getList', {
  'user_id' => $setting_flickr_user_id});

# check whether request was a success
if ($flickr_response->{success} == 0) {
  die "Error $flickr_response->{error_code}: $flickr_response->{error_message}";
}

# get list of photosets from the local db
$qry_getsets = $dbh->prepare("SELECT SetID FROM $setting_db_tablename ORDER BY SetID ASC");
$qry_getsets->execute();
if ($qry_getsets->rows > 0) {
  while (($local_setid) = $qry_getsets->fetchrow_array) {
    $local_photosets{$local_setid} = TRUE;
  }
}

# go through photosets and process all sets
$flickr_tree = new XML::Parser::Lite::Tree::XPath($flickr_response->{tree});
@nodes = $flickr_tree->select_nodes('/photosets/photoset');
foreach (@nodes) {
  # set the vital information about each photoset
  $set_id = $_->{attributes}->{id};
  $set_photos = $_->{attributes}->{photos};
  $set_primary = $_->{attributes}->{primary};
  $set_secret = $_->{attributes}->{secret};
  $set_server = $_->{attributes}->{server};
  $set_title = join('', map {$_->{content}} $flickr_tree->select_nodes("/photosets/photoset[\@id=$set_id]/title/text()"));
  $set_description = join('', map {$_->{content}} $flickr_tree->select_nodes("/photosets/photoset[\@id=$set_id]/title/description()"));

  # now add this information to an array
  push @photosets, { id => $set_id, photos => $set_photos, title => $set_title, description => $set_description };
  $photoids{$set_id} = TRUE;
  
  # check if this is already in the database
  if (exists $local_photosets{$set_id}) {
    # if it is, update the record
    $qry_local_upd = $dbh->prepare(qq{
      UPDATE $setting_db_tablename
      SET
        RemotePhotos = ?,
        RemoteTitle = ?,
        RemoteDescription = ?,
        RemotePrimary = ?,
        RemoteSecret = ?,
        RemoteServer = ?
      WHERE SetID = ?
    });
    $qry_local_upd->execute($set_photos, $set_title, $set_description, $set_primary, $set_secret, $set_server, $set_id);
  } else {
    # if not, insert the record
    $qry_local_ins = $dbh->prepare(qq{
      INSERT INTO $setting_db_tablename
      ( SetID, RemotePhotos, RemoteTitle, RemoteDescription, RemotePrimary, RemoteSecret, RemoteServer )
      VALUES
      ( ?, ?, ?, ?, ?, ?, ? )
    });
    $qry_local_ins->execute($set_id, $set_photos, $set_title, $set_description, $set_primary, $set_secret, $set_server);
  }
}

# now loop through database records and flag those which
#  were not received in the flickr download

# disconnect from database server
$dbh->disconnect();

