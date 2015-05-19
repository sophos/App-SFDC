package App::SFDC::Retrieve;
# ABSTRACT: Retrive files from SFDC

use strict;
use warnings;

use Data::Dumper;
use File::Path 'rmtree';
use FindBin '$Bin';
use Log::Log4perl ':easy';

use WWW::SFDC::Manifest;
use WWW::SFDC::Metadata;
use WWW::SFDC::Zip;

use Moo;
use MooX::Options;
with 'App::SFDC::Role::Logging',
	'App::SFDC::Role::Credentials';

option 'delete',
	default => 1,
	negativable => 1,
	is => 'ro';

option 'all',
	short => 'a',
	is => 'ro';

option 'file',
	is => 'ro',
	format => 's',
	repeatable => 1,
	short => 'f',
	autosplit => ',';

option 'manifest',
	is => 'ro',
	format => 's',
	lazy => 1,
	repeatable => 1,
	default => sub {
		my $self = shift;
		[
			"$Bin/../manifests/base.xml",
			$self->all
				? "$Bin/../manifests/all.xml"
				: (),
		]
	},
	isa => sub {
		for (@{$_[0]}) {
			LOGDIE "The manifest file $_ doesn't exist!"
				unless -e;
		}
	};

my @folders;

has '_manifest',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $manifest = WWW::SFDC::Manifest->new();

		return $manifest->addList(@{$self->file})
			if $self->file;

		$manifest->add(
			WWW::SFDC::Manifest->new()->readFromFile($_)
		) for @{$self->manifest};

		$manifest->addList(
			WWW::SFDC::Metadata->instance()
				->listMetadata(@folders)
		) if $self->all and @folders;

		return $manifest;
	};

option 'plugins',
	is => 'ro',
	format => 's',
	default => "$Bin/../plugins/retrieve.plugins.pm",
	isa => sub {
		LOGDIE "The plugins file $_[0] doesn't exist!"
			unless -e $_[0];
	};



sub _loadPlugins {
	my $self = shift;
	my $plugins = $self->plugins;
	eval {
		require $plugins;
	};
	LOGDIE "Couldn't load plugins from $plugins: $@"
		if $@;
	LOGDIE "Couldn't load plugins from $plugins: $@"
		if $!;
}

sub execute {
	my $self = shift;

	$self->_loadPlugins;

	rmtree 'src'
		if $self->all and $self->delete and -e 'src';

	mkdir 'src' unless -f 'src';

    WWW::SFDC::Zip::unzip(
    	'src',
    	WWW::SFDC::Metadata->instance()
    		->retrieveMetadata(
    			$self->_manifest->manifest()
    		),
    	\&_retrieveTimeMetadataChanges
   );
}

1;

__END__
