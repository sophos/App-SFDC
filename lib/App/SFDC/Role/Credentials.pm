package App::SFDC::Role::Credentials;
# ABSTRACT: Handle credential command-line input

use strict;
use warnings;
use 5.10.0;

use Config::Properties;
use File::HomeDir;
use Log::Log4perl ':easy';
use WWW::SFDC::SessionManager;

use Moo::Role;
use MooX::Options;

option 'username',
	is => 'ro',
	short => 'u',
	format => 's';

option 'password',
	is => 'ro',
	short => 'p',
	format => 's';

option 'url',
	is => 'ro',
	format => 's',
	default => 'https://login.salesforce.com';

option 'apiversion',
	is => 'ro',
	format => 'i',
	default => 33;

option 'credfile',
	is => 'ro',
	format => 's',
	lazy => 1,
	default => File::HomeDir->my_home."/.salesforce.properties",
	isa => sub {
		INFO "hi!";
		LOGDIE "The credentials file ".$_[0]." doesn't exist!"
			unless -e $_[0];
	};

option 'environment',
	is => 'ro',
	short => 'e',
	format => 's';

sub _readOptionsFromFile {
	my ($self) = @_;

	my $environment = $self->environment;

	INFO "Reading options for $environment from "
		. $self->credfile;

	my %environments = %{
      Config::Properties
      	->new(file => $self->credfile)
      	->splitToTree()
    };

    LOGDIE "Couldn't find credentials for $environment in "
    	.$self->credfile
    	unless $environments{$environment};

    $self->$_ = $environments{$environment}->{$_}
    	for qw(username password url apiversion);
}

sub BUILD {
	my $self = shift;

	$self->_readOptionsFromFile if $self->environment;

	LOGDIE 'You must specify a username and password '
		. 'either on the commandline or in a '
		. 'credentials file'
		unless $self->username and $self->password;

	WWW::SFDC::SessionManager->instance(
		username => $self->username,
		password => $self->password,
		url => $self->url,
		apiVersion => $self->apiversion
	);
}

1;

__END__
