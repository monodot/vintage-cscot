#!/usr/bin/perl

use MIME::Lite;

my $from_address = 'CSCOT Listings <bounce@cscot.com>';
my $to_address = 'tom.donohue@example.com';
my $mail_server = 'localhost';
my $subject = "CSCOT Edinburgh listings: Wed 22 Sep to Sun 03 Oct";
my $mime_type = "multipart/related";
my $message_body = <<__EOT__;

<html>
<head>
<title></title>
</head>

<body>

<style type="text/css">
<!--
#cscot { font-size: 8pt; padding: 0 25px 0 25px }
#cscot #logo {  }
#cscot, #cscot a { font-family: Lucida Sans Unicode, Lucida Sans, Verdana, sans-serif }
#cscot a { text-decoration: underline }
#cscot em { color: #7F7F7F; font-style: normal }
#cscot h1 { font-family: Georgia; font-weight: normal; font-size: 22pt; margin: 20px 0 0 0 }
#cscot h2 { font-family: Georgia; font-weight: normal; font-size: 15pt; margin: 15px 0 }
#cscot h3 { font-size: 8pt; font-weight: bold; color: #900000 }
#cscot #listings a.d { font-weight: bold }
-->
</style>

<div id="cscot">

<div id="logo"><img src="cid:cscot_logo"></div>

<h1>Edinburgh club listings<br />
Wed 22 Sep to Sun 03 Oct</h1>

<p>Brought to you by <a href="http://www.cscot.com/">CSCOT.COM</a> - Scottish club listings, features and reviews</p>

<hr />

<h2>Welcome to this week's update!</h2>

<p>Here's what we've been up to this week, you crazy cats. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Vestibulum mi. Fusce viverra quam et odio. Sed semper. Mauris semper leo at velit. Curabitur ut quam. Etiam in eros a turpis mollis dapibus. Pellentesque ligula purus, lacinia at, cursus ac, bibendum at, velit. Donec lobortis lectus at turpis. Cras sit amet tellus nec velit vehicula tincidunt. Vestibulum vitae lacus. Donec ligula magna, ultrices ut, hendrerit a, placerat ut, orci. Proin at velit. Proin eleifend ligula sed sem. Donec pede nibh, viverra a, malesuada sed, viverra ut, enim. Etiam dui. Phasellus sed velit.</p>


<h2>What's in this e-mail?</h2>

<p>This e-mail includes all listings we have for this coming weekend, right up to and including next weekend, so you can plan ahead. Please note however that advance listings might be subject to change and if you don't see a night listed this week, it might appear on next week's update.</p>


<div id="listings">

<h1>The listings</h1>

<hr />

<p><a href="#" class="d">THURSDAY 23 SEPTEMBER</a></p>

<p>
<a href="#"><strong>Snatch Social</strong></a> at <a href="#">The Liquid Room</a><br />
<em>R&B, hip-hop, pop, rock</em><br />
10.30pm-3.00am, £3.50/£3 students
</p>

<p>
<a href="#"><strong>Kombustion</strong></a> at <a href="#">Ego</a><br />
<em>Hardcore, hard techno, techno</em><br />
10.30pm-3.00am, £5
</p>

</div>

</div>


</body>
</html>

__EOT__



my $message_body = <<__EOT__;

<html>
<head>
<title></title>
</head>

<body>
<pre>


Test        test
this is a test    1 2 3
_____________-  __________________



</pre>
</body>
</html>



__EOT__


my $mime_msg = MIME::Lite->new(
	From => $from_address,
	To => $to_address,
	Subject => $subject,
	Type => $mime_type,
	Data => $message_body
)
or die "Error creating MIME body\n";

$mime_msg->attach(
  Type => 'text/html',
  Data => $message_body);
$mime_msg->attach(
  Type => 'image/png',
  Id => 'cscot_logo',
  Encoding => 'base64',
  Path => 'cscot_logo.png');
$mime_msg->send;


#MIME::Lite->send('smtp', $ServerName);
#$mime_msg->send() or die "Error sending message: $!\n";

