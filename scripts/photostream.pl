#!/usr/local/bin/perl -w

# CSCOT.COM
# Get latest photos from our photostream using Flickr's API
# e.g. http://www.flickr.com/services/feeds/photos_public.gne?id=97374520@N00&format=atom_03
# tdonohue, 19.02.06


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
my $setting_maxphotos = 10; # max number of photos to return
my $setting_db_tablename = "cscot_flickrstream";


# set up database and flickr variables
my $setting_db_schema = $cscot_settings::database{'schema'};
my $setting_db_username = $cscot_settings::database{'username'};
my $setting_db_password = $cscot_settings::database{'password'};
my $setting_db_hostname = $cscot_settings::database{'hostname'};
my $setting_flickr_api_key = $cscot_settings::flickr{'api_key'};
my $setting_flickr_user_id = $cscot_settings::flickr{'user_id'};


# declare variables
my ($flickr_api, $flickr_response, $flickr_tree, @nodes);
my ($photo, $photofile, $photosrc, @photofiles);
my (@files_to_delete, $file_to_delete);
my ($dbh, $qry_remove, $qry_cache);
my $photoposition = 0;

# subroutine to check for empty dir
sub empty_dir ($) {
    local(*DIR, $_);
    return unless opendir DIR, $_[0];
    while (defined($_ = readdir DIR)) {
        next if /^\.\.?$/;
        closedir DIR;
        return 0;
    }
    closedir DIR;
    1;

}

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
$flickr_response = $flickr_api->execute_method('flickr.people.getPublicPhotos', {
  'user_id' => $setting_flickr_user_id,
  'per_page' => $setting_maxphotos,
  'page' => 1});

# check whether request was a success
if ($flickr_response->{success} == 0) {
  die "Error $flickr_response->{error_code}: $flickr_response->{error_message}";
}

# remove all files in img cache directory
chdir ($setting_local_img_path) or die "Could not change dir to $setting_local_img_path: $!";
@files_to_delete = <*>;
foreach $file_to_delete (@files_to_delete) {
  unlink $file_to_delete;
}

# remove all files from cache table
$qry_remove = $dbh->prepare("delete from ".$setting_db_tablename);
$qry_remove->execute();

# go through photolist and get all files
$flickr_tree = new XML::Parser::Lite::Tree::XPath($flickr_response->{tree});
@nodes = $flickr_tree->select_nodes('/photos/photo');
foreach (@nodes) {
	$photo = "http://static.flickr.com/"
    .$_->{attributes}->{server}."/"
    .$_->{attributes}->{id}."_"
    .$_->{attributes}->{secret}."_s.jpg";
	$photofile = $setting_local_img_path."$_->{attributes}->{id}.jpg";

  # retrieve photo and save to file
	open (FILE, "> $photofile") or die "error: $! and $^E";
	$photosrc = get($photo);
	print FILE $photosrc;

  # insert record into table
  $qry_cache = $dbh->prepare("insert into ".$setting_db_tablename." ( PhotoID, Position ) values ( ?, ? )");
  $qry_cache->execute($_->{attributes}->{id}, $photoposition);

  # increment position counter
  $photoposition++;

}

# wrap things up
close FILE;

# disconnect from database server
$dbh->disconnect();

