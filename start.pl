use Mojo::Base -base;
use Mojo;
use Term::ANSIColor;

++$|;

opendir D, 'Exploit' or die;
my @modules = map {s/\.pm$//; $_} grep {/^[^\.]/ && -f "Exploit/$_"} readdir D;
closedir D;

my @addresses;
open F, 'addresses' or die;
while (<F>) {
	chomp;
	my $address = $_;
	$address = 'http://'.$address unless ($address =~ /^http/);
	$address = Mojo::URL->new($address);
	$address->path('/') if ($address->path eq '');
	push @addresses, $address;
}
close F;

for my $module (@modules) {
	eval "use Exploit::$module";
	if ($@) {
		print "ERROR: No such module [$module]\n";
		next;
	}
	print "\n$module\n";
	for my $address (@addresses) {
		my $result = run($address) ? 'TRUE' : 'false';
		print "	$address : $result\n";
	}
}