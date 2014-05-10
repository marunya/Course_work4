use Mojo::Base -base;

opendir D, 'Exploit' or die;
my @modules = map {s/\.pm$//; $_} grep {/^[^\.]/ && -f "Exploit/$_"} readdir D;
closedir D;

my @addresses;
open F, 'addresses' or die;
while (<F>) {
	chomp;
	push @addresses, $_;
}
close F;

for my $module (@modules) {
	eval "use Exploit::$module";
	if ($@) {
		print "ERROR: No such module [$module]\n";
		next;
	}
	for my $address (@addresses) {
		$address = 'http://'.$address unless ($address =~ /^http/);
		$address = Mojo::URL->new($address);
		$address->path('/') if ($address->path eq '');
		print "$address : " . run($address) . "\n";
	}
}