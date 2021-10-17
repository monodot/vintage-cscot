#!/usr/local/bin/perl
# Prints all lines from all three files
@files = ("f1.txt", "f2.txt", "f3.txt");
print "num: " . $#files;
for ($i = 0; $i<$#files; $i++){
open (FILE, $files[$i]) || die "Cannot open $files[$i]\n";
@lines = <FILE>;
close FILE;
push @all_lines, @lines;
}
print @all_lines;
