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


# set constants
use constant TRUE => 1;
use constant FALSE => 0;


# app settings
my $setting_subject_title = "Edinburgh Weekly Update";
my $setting_eventurl_start = "http://www.cscot.com/listings/event/";
my $setting_eventurl_end = "/";
my $setting_num_listings_days = 13;
my $setting_toaddr = "tom.donohue\@example.com";
my $setting_publishday = 2; # day of week on which this newsletter is usually published
my @today = Today();
$Text::Wrap::columns = 65; # default is 76


# set up database variables
my $setting_db_schema = $cscot_settings::database{'schema'};
my $setting_db_username = $cscot_settings::database{'username'};
my $setting_db_password = $cscot_settings::database{'password'};


# declare variables
my ($dbh, $qry_news, $qry_remnews, $qry_events, $qry_genres, $qry_queue, $i, @txt_output, @txt_news, @txt_headlines, $txt_genres, $txt_subject, $txt_body, $contents_id, $is_news);
my ($news_item_id, $news_headline_caps, $news_headline_normal, $news_article, @news_article_array);
my ($ev_name, $ev_price, $ev_id, $ev_venue, $ev_occid, $ev_timestart, $ev_timeend, @ev_genres, $genre_name);
my ($date_fordisplay, $date_fordatabase, $date_listings_start, $date_listings_start_caps, $date_listings_end, $date_listings_next);
my ($new_year, $new_month, $new_day, $new_day_name, $new_month_name, $current_dow);


# initialise variables
$contents_id = 1;
$is_news = FALSE;


# make database connection
$dbh = DBI ->
  connect(
    "DBI:mysql:$setting_db_schema:127.0.0.1",
    "$setting_db_username",
    "$setting_db_password",
    {RaiseError=>1}
);


# get formatted start date for listings
($new_year, $new_month, $new_day) = Today();
$new_day_name = Day_of_Week_to_Text(Day_of_Week($new_year, $new_month, $new_day));
$new_month_name = Month_to_Text($new_month);
$date_listings_start = substr($new_day_name, 0, 3) . " " . $new_day . " " . substr($new_month_name, 0, 3);
$date_listings_start_caps = $date_listings_start;
$date_listings_start_caps =~ tr/a-z/A-Z/;


# get formatted end date for listings
($new_year, $new_month, $new_day) = Add_Delta_Days( Today(), ($setting_num_listings_days - 1) );
$new_day_name = Day_of_Week_to_Text(Day_of_Week($new_year, $new_month, $new_day));
$new_month_name = Month_to_Text($new_month);
$date_listings_end = substr($new_day_name, 0, 3) . " " . $new_day . " " . substr($new_month_name, 0, 3);


# get formatted date for next issue
$current_dow = Day_of_Week(@today);
if ($setting_publishday == $current_dow) {
  ($new_year, $new_month, $new_day) = Add_Delta_Days(@today,+7);
} else {
  if ($setting_publishday > $current_dow) {
    ($new_year, $new_month, $new_day) = Add_Delta_Days(@today, $setting_publishday - $current_dow);
    #@prev = Add_Delta_Days(@next,-7);
  } else {
    ($new_year, $new_month, $new_day) = Add_Delta_Days(@today, ($setting_publishday - $current_dow + 7));
    #@next = Add_Delta_Days(@prev,+7);
  }
}
$date_listings_next = $new_year . "-" . $new_month . "-" . $new_day;


# write subject line
$txt_subject = $setting_subject_title . " - " . $date_listings_start;


# get news items to publish
$qry_news = $dbh->prepare(qq{
  SELECT
    NewsItemID, UPPER(Headline) AS HeadlineCaps, Headline as HeadlineNormal, Article
  FROM cscot_newsitem
  WHERE
    PublishEmail = '1'
  ORDER BY PriorityEmail DESC, DateAdded ASC
});
# get latest news
#$qry_news = $dbh->prepare(qq{
#  SELECT
#    NewsItemID, UPPER(Headline) AS HeadlineCaps, Headline AS 
#HeadlineNormal, Article
#  FROM cscot_newsitem
#  WHERE
#    PublishEmail = '1'
#  AND DateAdded <= NOW()
#  AND DateAdded >= DATE_SUB(NOW(), INTERVAL 7 DAY)
#  AND ((RegionOnly = '0') OR (RegionOnly = '1'))
#  ORDER BY PriorityEmail DESC, DateAdded ASC
#});
$qry_news->execute();
if ($qry_news->rows > 0) {
  $is_news = TRUE;
  while (($news_item_id, $news_headline_caps, $news_headline_normal, $news_article) = $qry_news->fetchrow_array) {
    $qry_remnews = $dbh->prepare(qq{
      UPDATE cscot_newsitem
      SET PublishEmail = '0'
      WHERE NewsItemID = '$news_item_id'
});
    $qry_remnews->execute();
    $news_article =~ s/<(.*)p>\r\n//gi; # remove P tags
    $news_article =~ s/<strong>(.*?)<\/strong>/uc $1/ge; # capitalise STRONG text
    $news_article =~ s/<(.*)blockquote>\r\n//gi; # remove BLOCKQUOTE tags
    $news_article =~ s/<(.*?)>//gi; # strip HTML tags

    $news_article =~ s/&pound;/GBP /gi; # change &pound; to GBP
    $news_article =~ s/&amp;/&/gi; # change &amp; to ampersand
    $news_article =~ s/&quot;/"/gi; # change &quot; to quotation marks
#    $news_article = wrap("", "", $news_article); # wrap article text
    $news_article = fill("", "", $news_article); # wrap article text
    @news_article_array = split("\n", $news_article); # store in array
  
    push(@txt_headlines, ("   * " . $news_headline_normal));
    push(@txt_news, $news_headline_caps);
    push(@txt_news, "");
    push(@txt_news, @news_article_array);
    push(@txt_news, "");
    push(@txt_news, ".................................................................");
    push(@txt_news, "");
  }  
}
$qry_news->finish();


# write table of contents
push(@txt_output, "CONTENTS");
push(@txt_output, "");
if ($is_news == TRUE) {
  push(@txt_output, ($contents_id . "/ News & previews"));
  push(@txt_output, @txt_headlines);
  $contents_id++;
}
push(@txt_output, ($contents_id . "/ Club Listings: " . $date_listings_start . " to " . $date_listings_end));
$contents_id++;
push(@txt_output, ($contents_id . "/ How to unsubscribe"));
$contents_id++;
push(@txt_output, "");
push(@txt_output, "");
push(@txt_output, "");
if ($is_news == TRUE) {
  push(@txt_output, "_________________________________________________________________");
  push(@txt_output, "");
  push(@txt_output, "NEWS & PREVIEWS");
  push(@txt_output, "_________________________________________________________________");
  push(@txt_output, "");
  push(@txt_output, "");
  push(@txt_output, @txt_news);
  push(@txt_output, "To suggest a news item for inclusion, go to");
  push(@txt_output, "http://www.cscot.com/info/contact.php");
  push(@txt_output, "");
  push(@txt_output, "");
  push(@txt_output, "");
}


# write listings start
push(@txt_output, "_________________________________________________________________");
push(@txt_output, "");
push(@txt_output, "CLUB LISTINGS");
push(@txt_output, "_________________________________________________________________");
push(@txt_output, "");
push(@txt_output, "");
push(@txt_output, "City-wide club listings for the next 12 days now follow; these");
push(@txt_output, "listings come from updates that venues and promoters have sent to");
push(@txt_output, "us. Occasionally there may be errors or last-minute changes, so");
push(@txt_output, "it's recommended you contact the venue first before heading out.");
push(@txt_output, "");
push(@txt_output, "To get your night listed here, follow the link at the bottom of");
push(@txt_output, "this e-mail and send us your details. Now on with the listings...");


# loop through days
for ($i = 0; $i < $setting_num_listings_days; $i++) {
  # create next future date
  ($new_year, $new_month, $new_day) = Add_Delta_Days( Today(), $i );
  $new_day_name = Day_of_Week_to_Text(Day_of_Week($new_year, $new_month, $new_day));
  $new_month_name = Month_to_Text($new_month);

  $date_fordisplay = $new_day_name . " " . $new_day . " " . $new_month_name;
  $date_fordisplay =~ tr/a-z/A-Z/;
  $date_fordatabase = $new_year . "-" . $new_month . "-" . $new_day;

  $qry_events = $dbh->prepare(qq{
    SELECT
      UPPER(ev.EventName),
      ev.Price,
      ev.EventID,
      TRIM(CONCAT(vn.Prefix, ' ', vn.Name)) AS VenueName,
      oc.OccurrenceID,
      LOWER(TIME_FORMAT(ev.TimeStart, "%l.%i%p")) AS TimeStart,
      LOWER(TIME_FORMAT(ev.TimeEnd, "%l.%i%p")) AS TimeEnd
    FROM cscot_event ev, cscot_occurrence oc, cscot_venue vn
    WHERE
      ev.EventID = oc.EventID
      AND ev.VenueID = vn.VenueID
      AND oc.Date = '$date_fordatabase'
      AND vn.RegionID = '1'
    ORDER BY EventName ASC
    LIMIT 0,10
  });
  $qry_events->execute();

  if ($qry_events->rows > 0) {
    # write date header
    push(@txt_output, "");
    push(@txt_output, "");
    push(@txt_output, "_________________________________________________________________");
    push(@txt_output, "");
    push(@txt_output, $date_fordisplay);
    push(@txt_output, "");

    while (($ev_name, $ev_price, $ev_id, $ev_venue, $ev_occid, $ev_timestart, $ev_timeend) = $qry_events->fetchrow_array) {
      undef(@ev_genres);

      # get list of genres
      $qry_genres = $dbh->prepare(qq{
        SELECT DISTINCT LOWER(gr.Genre)
        FROM cscot_genre gr, cscot_musicpolicy mp
        WHERE mp.EventID = '$ev_id' AND mp.GenreID = gr.GenreID
        ORDER BY Genre ASC
      });
      $qry_genres->execute();
      while ($genre_name = $qry_genres->fetchrow_array) {
        push(@ev_genres, $genre_name);
      }
      $qry_genres->finish();

      $ev_price =~ s/£/GBP /gi; # change £ to GBP
    
      # write event details
      push(@txt_output, "");
      push(@txt_output, ($ev_name . " at " . $ev_venue));
      if (@ev_genres > 0) {
        $txt_genres = join(", ", @ev_genres);
        $txt_genres = ucfirst($txt_genres);
        push(@txt_output, (" | " . $txt_genres));
      }
      if ($ev_price ne "") {
        $ev_price = " | " . $ev_price;
      }
      push(@txt_output, ($ev_price . " | " . $ev_timestart . "-" . $ev_timeend));
      push(@txt_output, (" | " . $setting_eventurl_start . $ev_occid . $setting_eventurl_end));
    }
  }
  $qry_events->finish();
}
push(@txt_output, "");
push(@txt_output, "");
push(@txt_output, "** Note: GBP = Pounds Sterling");
push(@txt_output, "");
push(@txt_output, "For full club listings visit: http://www.cscot.com/listings/");
push(@txt_output, "Or view the calendar: http://www.cscot.com/listings/calendar.php");
push(@txt_output, "");
push(@txt_output, "");
push(@txt_output, "");


# formulate body text
$txt_body = join("\n", @txt_output);


# add mail to the queue
$qry_queue = $dbh->prepare(qq{
  INSERT INTO cscot_mailoutqueue
  ( ListID, DeliveryDate, NextUpdate, Subject, Body, Queued )
  VALUES
  (
    '1',
    '0000-00-00',
    '$date_listings_next',
    '$txt_subject',
    '$txt_body',
    '1'
  )
});
$qry_queue = $dbh->prepare(qq{
  INSERT INTO cscot_mailoutqueue
  ( ListID, DeliveryDate, NextUpdate, Subject, Body, Queued )
  VALUES
  (
    '2',
    '0000-00-00',
    ?,
    ?,
    ?,
    '1'
  )
});
$qry_queue->execute($date_listings_next, $txt_subject, $txt_body);
$qry_queue->finish();


# disconnect from database server
$dbh->disconnect();

  


