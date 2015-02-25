#!/usr/bin/perl

########################################################################
# (c) 2008 Indika Udagedara
# indika.udagedara@gmail.com
# http://indikaudagedara.blogspot.com
# 
# ----------
# LICENCE
# ----------
# This work is protected under GNU GPL
# It simply says 
# "	you are hereby granted to do whatever you want with this
# 	except claiming you wrote this."
#
#
# ----------
# README
# ----------
# A simple tool to download via http proxies which enforce a download
# size limit. Requires curl.
# This is NOT a hack. This uses the absolutely legal HTTP/1.1 spec
# Tested only for squid-2.6. Only squids will work with this(i think)
# Please read the verbose README provided kindly by Rahadian Pratama
# if u r on cygwin and think this documentation is not enough :)
# 
# ----------
# USAGE
# ----------
# + 	Edit below configurations(mainly proxy)
# + 	First run with -i <file> giving a sample file of same type that
# 	you are going to download. Doing this once is enough.
#	eg. to download '.tar' files first run with
#		pget -i my.tar ('my.tar' should be a real file)
# +	Run with 
#		pget -g <URL>
#
#
########################################################################




########################################################################
# CONFIGURATIONS - CHANGE THESE FREELY
########################################################################

# *magic* file 
# pls set absolute path if in cygwin
my $_extFile 	= "./pget.ext" ;

# download in chunks of below size
my $_chunkSize 	=  1024*1024; 		# in Bytes


# the proxy that troubles you 
my $_proxy	= "192.168.2.2:3128";	# proxy URL:port
my $_proxy_auth	= "user:pass";		# proxy user:pass


# whereis curl
# pls set absolute path if in cygwin
my $_curl	= "/usr/bin/curl";




########################################################################
# EDIT BELOW ONLY IF YOU KNOW WHAT YOU ARE DOING
########################################################################

use warnings;
my $_version = "0.1.0";

PrintBanner();
if (@ARGV == 0)
{
	PrintHelp();
	exit;
}

PrimaryValidations();

my $val;
while(scalar(@ARGV))
{
	my $arg = shift(@ARGV);
	if($arg eq '-h')
	{
		PrintHelp();
	}
	elsif($arg eq '-i') 
	{	
		$val = shift(@ARGV);
		if (!defined($val))
		{
			printf("-i option requires a filename\n");
			exit;
		}
		Init($val);
	}
	elsif($arg eq '-g')
	{	
		$val = shift(@ARGV);
		if (!defined($val))
		{
			printf("-g option requires a URL\n");
			exit;
		}
		GetURL($val);
	}
	elsif($arg eq '-c')
	{	
		$val = shift(@ARGV);
		if (!defined($val))
		{
			printf("-c option requires a URL\n");
			exit;
		}
		ContinueURL($val);
	}
	else 
	{ 
		printf ("Unknown option %s\n", $arg);
		PrintHelp();
	}
}


sub GetURL
{

	my ($URL) = @_;
	chomp($URL);

	my $fileName = GetFileName($URL);
	my %mapExt;
	my $first;
	my $readLen;
	my $ext = GetExt($fileName);

	ReadMap($_extFile, \%mapExt);
	if ( exists($mapExt{$ext}))
	{
		$first = $mapExt{$ext};
		GetFile($URL, $first, $fileName, 0);
	}
	else
	{
		die "Unknown ext in $fileName. Rerun with -i <fileName>";
	}




}

sub ContinueURL
{
	my ($URL) = @_;
	chomp($URL);

	my $fileName = GetFileName($URL);
	my $fileSize = 0;	

	$fileSize = -s $fileName;	
	printf("Size = %d\n",  $fileSize);

	my $first = -1;


	if ( $fileSize > 0 )
	{
		$fileSize -= 1;	
		GetFile($URL, $first, $fileName, $fileSize);
	}
	else
	{
		GetURL($URL);
	}

}

sub Init
{
	my ($fileName) = @_;
	my ($key, $value);
	my %mapExt;
	my $ext = GetExt($fileName);
	
	if ( $ext eq "")
	{
		die "Cannot get ext of \'$fileName\'";
	}

	ReadMap($_extFile, \%mapExt);

	my $b = GetFirst($fileName);
	$mapExt{$ext} = $b;
	WriteMap($_extFile, \%mapExt);
	
	print "I handle\n";
	while ( ($key, $value) = each(%mapExt) )
	{
		print "\t$key ->  $value\n";
	}
}

sub GetExt
{
	my ($name) = @_;
	my @x = split(/\./, $name);
	my $ext = "";

	if (@x != 1)
	{
		$ext = pop @x;
	}

	return $ext;
}

sub ReadMap
{
	my($fileName, $mapRef) = @_;

	my $f; 
	my @arr;
	open($f, '<', $fileName) or die "Couldn't open $fileName";

	my %map = %{$mapRef};

	while (<$f>)	
	{
		my $line = $_;
		chomp($line);
		@arr = split(/[ \t]+/, $line, 2);
		$mapRef->{ $arr[0]} = $arr[1];
	}

	printf("known ext\n");
	while (($key, $value) = each(%$mapRef))
	{
		print("$key, $value\n");	
	}

	close($f);
	
}


sub WriteMap
{
	my ($fileName, $mapRef) = @_;

	my $f; 
	my @arr;
	open($f, '>', $fileName) or die "Couldn't open $fileName";

	my ($k, $v);

	while( ($k, $v) = each(%{$mapRef}))
	{
		print $f "$k" . "\t$v\n";
	}
	close($f);


}


sub PrintHelp
{
	print "usage:
	-h Print this help
	-i <filename> Initialize for this filetype
	-g <URL> Get this URL\n
	-c <URL> Continue this URL\n"
}


sub GetFirst
{

	my ($fileName) = @_;
	my $f;
	open($f, "<$fileName") or die "Couldn't open $fileName";
	my $buffer = "";
	my $first = -1;

	binmode($f); 
	sysread($f, $buffer, 1, 0);
	close($f);
	$first = ord($buffer);
	return $first;
}


sub GetFirstFromMap
{

}

sub GetFileName
{
	my ($URL) = @_;
	my @x = split(/\//, $URL);
	my $fileName = pop @x;
	return $fileName;

}


sub GetChunk
{
	my ($URL, $file, $offset, $readLen) = @_;
	
	my $end = $offset + $_chunkSize - 1;	
	my $curlCmd = "$_curl -x $_proxy -u $_proxy_auth -r $offset-$end -# \"$URL\"";
	print "$curlCmd\n";
	my $buff = `$curlCmd`;
	${$readLen} = syswrite($file, $buff, length($buff));
}


sub GetFile
{
	my ($URL, $first, $outFile, $fileSize) = @_;
	my $readLen = 0;
	
	my $start = $fileSize + 1;
	my $file;

	open($file, "+>>$outFile") or die "Couldn't open $outFile to write";

	if ($fileSize <= 0)
	{
		my $uc = pack("C", $first);
		syswrite ($file, $uc, 1);
	}

	do
	{
		GetChunk($URL, $file, $start ,\$readLen);
		$start = $start + $_chunkSize;
		$fileSize += $readLen;

	}while ($readLen == $_chunkSize);

	printf("Downloaded %s(%d bytes).\n", $outFile, $fileSize);
		

	close($file);

}

sub PrintBanner
{
	printf ("pget version %s\n", $_version);
	printf ("There is absolutely NO WARRANTY for pget.\n");
	printf ("Use at your own risk. You have been warned.\n\n");
}


sub PrimaryValidations
{
	unless( -e "$_curl")	
	{
		printf("ERROR:curl is not at %s. Pls install or provide correct path.\n", $_curl);
		exit;
	}

	unless( -e "$_extFile")
	{
		printf("extFile is not at %s. Creating one\n", $_extFile);
		`touch $_extFile`;
	}

	if ( $_chunkSize <= 0)
	{
		printf ("Invalid chunk size. Using 1Mb as default.\n");
		$_chunkSize = 1024*1024;
	}
}
