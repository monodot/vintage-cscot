#!/usr/local/bin/perl -w

# CSCOT.COM
# Send contents of mailing list queue
# tdonohue, 12.01.05


# include modules
use strict;
use DBI;
use cscot_settings;


# set up database variables
my $setting_db_schema = $cscot_settings::database{'schema'};
my $setting_db_username = $cscot_settings::database{'username'};
my $setting_db_password = $cscot_settings::database{'password'};


# declare variables
my ($dbh, $qry_queue, $qry_subscribers, $qry_delmail, @err_output);
my ($qu_mailoutid, $qu_listid, $qu_nextupdate, $qu_fromname, $qu_fromemail, $qu_subject, $qu_body);
my ($subs_email, $subs_number);
my (@txt_output, @txt_content, $txt_subject_caps);


push(@err_output, "MAILOUT REPORT");
push(@err_output, "");



# make database connection
$dbh = DBI ->
  connect(
    "DBI:mysql:$setting_db_schema:127.0.0.1",
    "$setting_db_username",
    "$setting_db_password",
    {RaiseError=>1}
);


# get queued items
$qry_queue = $dbh->prepare(qq{
  SELECT
    mq.MailoutID, mq.ListID, DATE_FORMAT(mq.NextUpdate, '%a %e %b'), mq.FromName, mq.FromEmail, mq.Subject, mq.Body
  FROM cscot_mailoutqueue mq, cscot_maillist ml
  WHERE
    mq.DeliveryDate <= NOW()
    AND mq.Queued = '1'
    AND mq.Sent = '0'
    AND mq.ListID = ml.ListID
});
$qry_queue->execute();
while (($qu_mailoutid, $qu_listid, $qu_nextupdate, $qu_fromname, $qu_fromemail, $qu_subject, $qu_body) = $qry_queue->fetchrow_array) {
  undef(@txt_output);

  # subject line
  $txt_subject_caps = uc($qu_subject);

  # body text
  @txt_content = split("\n", $qu_body);
  

  # write header
  push(@txt_output, "");
  push(@txt_output, "");
  push(@txt_output, "CSCOT.COM presents");
  push(@txt_output, $txt_subject_caps);
  push(@txt_output, "_________________________________________________________________");
  push(@txt_output, "");
  push(@txt_output, "");
  push(@txt_output, "");
  
  # write main content
  push(@txt_output, @txt_content);
  push(@txt_output, "");
  push(@txt_output, "");
  push(@txt_output, "");

  # write unsubscribe info
  push(@txt_output, "_________________________________________________________________");
  push(@txt_output, "");
  push(@txt_output, "HOW TO UNSUBSCRIBE");
  push(@txt_output, "_________________________________________________________________");
  push(@txt_output, "");
  push(@txt_output, "");
  push(@txt_output, "You can unsubscribe at any time from this e-mail list. Visit:");
  push(@txt_output, "http://www.cscot.com/connect/");
  push(@txt_output, "");
  push(@txt_output, "Enter your e-mail address and press the Unsubscribe button.");
  push(@txt_output, "");
  push(@txt_output, "Know someone who'd like to get this e-mail every week? Tell them");
  push(@txt_output, "to visit the address above for full details on how to subscribe.");
  push(@txt_output, "");
  push(@txt_output, "");
  push(@txt_output, "");
  
  # write footer
  push(@txt_output, "_________________________________________________________________");
  push(@txt_output, "");
  push(@txt_output, "CSCOT.COM - http://www.cscot.com/");
  push(@txt_output, "");
  push(@txt_output, "* Talk on the forums - http://forums.cscot.com/");
  push(@txt_output, "* Search club listings - http://www.cscot.com/listings/");
  push(@txt_output, "* Get your night listed - http://www.cscot.com/listings/submit/");
  push(@txt_output, "");
  push(@txt_output, "");
  push(@txt_output, "Please do not reply directly to this e-mail.");
  push(@txt_output, "To get in touch, visit: http://www.cscot.com/info/contact.php");
  push(@txt_output, "");
  push(@txt_output, "");
  push(@txt_output, "");
  if ($qu_nextupdate ne "") {
    push(@txt_output, ("++ Next update due in your inbox: " . $qu_nextupdate . " ++"));
  }
  push(@txt_output, "");


  # get guest subscribers
  $subs_number = 0;
  $qry_subscribers = $dbh->prepare(qq{
    SELECT Email
    FROM cscot_mailsubguest
    WHERE
      ListID = ?
      AND Confirmed = '1'
  });
  $qry_subscribers->execute($qu_listid);
  while ($subs_email = $qry_subscribers->fetchrow_array) {
    # send the mail (DEV ONLY)
    open (SENDMAIL, "|/usr/sbin/sendmail -t") or die "cannot open sendmail: $!";
    print SENDMAIL "To: " . $subs_email . "\n";
    print SENDMAIL "From: CSCOT Connect <null\@cscot.com>\n";
    print SENDMAIL "Subject: CSCOT " . $qu_subject . "\n\n";
    print SENDMAIL join("\n ", @txt_output);
    close (SENDMAIL);
    $subs_number++;
  }

  push(@err_output, $qu_subject);
  push(@err_output, "  " . $subs_number . " e-mail(s) sent.");

  # mark this mailout as sent
  $qry_delmail = $dbh->prepare(qq{
    UPDATE cscot_mailoutqueue SET Sent = '1' WHERE MailoutID = ?
  });
  $qry_delmail->execute($qu_mailoutid);
  
}
$qry_queue->finish();


# disconnect from database server
$dbh->disconnect();


# print out reporting messages
push(@err_output, "");
print join("\n", @err_output);

