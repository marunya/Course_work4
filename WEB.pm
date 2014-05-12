package WEB;

use Mojo::Base -strict;
use Mojo;
use URL::Encode qw(url_encode_utf8);
use Encode qw(encode decode);
use IO::File;

$/ = undef;

sub request {

	my %p = (
		method => 'GET',
		@_
	);

	my $Method = $p{method};
	my $URL = $p{url};
	my %GetParams = %{$p{get_params} // {}};
	my $Headers = $p{headers} // {};
	my %Cookies = %{$p{cookies} // {}};
	my $Multi = $p{multi};
	my %PostParams = %{$p{post_params} // {}};
	my @Files = @{$p{files} // []};

	my $tx = Mojo::Transaction::HTTP->new;
	my $ua = Mojo::UserAgent->new;

	# Method
	$tx->req->method($Method);

	# URL + GET params
	my $RequestURL = Mojo::URL->new;
	$RequestURL->parse($URL);
	$RequestURL->query(%GetParams);
	$tx->req->url($RequestURL);

	# POST
	if ($Multi) {
		# Multipart POST(multipart/form-data)
		my $boundary = '----WebKitFormBoundarysK0C7UtM6ga7G16M';
		my $body = '';
		if (%PostParams) {
			while ( my ($k, $v) = each %PostParams ) {
				# $v = encode('UTF-8', $v);
				$body .= "--${boundary}\x0D\x0AContent-Disposition: form-data; name=\"${k}\"\x0D\x0A\x0D\x0A${v}\x0D\x0A";
			}
		}
		if (@Files) {
			for my $file (@Files) {
				my $name = $file->{name};
				my $filename = $file->{filename};
				my $type = $file->{type};
				# File content
				my $file_content;
				my $location = $file->{location};
				if (defined $location) {
					my $fh = IO::File->new($location, 'r');
					if (defined $fh) {
						binmode $fh;
						$file_content = <$fh>;
					}
				} else {
					$file_content = $file->{content};
				}
				$body .= "--${boundary}\x0D\x0AContent-Disposition: form-data; name=\"${name}\"; filename=\"${filename}\"";
				$body .= "\x0D\x0AContent-Type: ${type}\x0D\x0A\x0D\x0A${file_content}\x0D\x0A";
			}
		}
		$body .= "--${boundary}--";
		my $content = Mojo::Content::Single->new;
		$content->auto_upgrade(0);
		$content->headers->from_hash({
			'Content-Type' => 'multipart/form-data; boundary=' . $boundary,
			'Content-Length' => length $body
		});
		$content->parse_body($body);
		$tx->req->content($content);
	} else {
		# Simple POST (application/x-www-form-urlencoded)
		if (%PostParams) {
			my $params = Mojo::Parameters->new(%PostParams)->to_string;
			my $content = Mojo::Content::Single->new;
			$content->headers->from_hash({
				'Content-Type' => 'application/x-www-form-urlencoded',
				'Content-Length' => length $params
			});
			$content->parse_body($params);
			$tx->req->content($content);
		}	
	}

	# Headers
	if ($Headers) {
		$tx->req->headers->from_hash($Headers);
	}

	# Cookies
	$tx->req->cookies(map {my $c = Mojo::Cookie::Request->new; $c->name($_); $c->value($Cookies{$_}); $c;} keys %Cookies);

	return $ua->start($tx);
}

1;