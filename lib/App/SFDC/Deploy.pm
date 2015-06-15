package App::SFDC::Deploy;
# ABSTRACT: Deploy files to SFDC

use strict;
use warnings;

use Data::Dumper;
use File::Find 'find';
use Log::Log4perl ':easy';

use WWW::SFDC::Manifest;
use WWW::SFDC::Zip;

use Moo;
use MooX::Options;
with 'App::SFDC::Role::Logging',
	'App::SFDC::Role::Credentials';

option 'all',
	is => 'ro',
	short => 'a';

option 'deletions',
	is => 'ro',
	default => 1,
	negativable => 1;

option 'files',
	format => 's',
	is => 'ro',
	lazy => 1,
	repeatable => 1,
	short => 'f',
	default => sub {
		my $self = shift;
		my @filelist;
		if ($self->all) {
		  find(
				sub {
					push @filelist, $File::Find::name
						unless (-d or /(package\.xml|destructiveChanges(Pre|Post)?\.xml|\.bak)/)
				},
				'src'
			);
		} else {
			INFO 'Reading files from STDIN';
			@filelist = <>;
		}
		DEBUG "File list for deployment: ". Dumper(\@filelist);
		return \@filelist;
	};

option 'rollback',
	is => 'ro',
	default => 0,
	negativable => 1;

option 'runtests',
	short => 't',
	is => 'ro',
	default => 0;

option 'validate',
	is => 'ro',
	short => 'v',
	default => 0;

has 'zipFile',
	lazy => 1,
	is => 'rw',
	default => sub {
		my $self = shift;

	print Dumper @{$self->files};
		WWW::SFDC::Zip::makezip(
			'src/',
			@{$self->files},
			'package.xml',
			(
				$self->deletions
				  ? ('destructiveChangesPre.xml', 'destructiveChangesPost.xml')
				  : ()
			)
		);
	};

has 'manifest',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		WWW::SFDC::Manifest->new(
			constants => $self->_session->Constants,
			apiVersion => $self->_session->apiVersion,
		)->addList(@{$self->files});
	};

sub execute {
	my $self = shift;
	$self->manifest->writeToFile('src/package.xml');
	$self->_session->Metadata->deployMetadata(
		$self->zipFile,
		{
			singlePackage => 'true',
			($self->rollback ? (rollbackonerror => 'true') : ()),
			($self->validate ? (checkOnly => 'true') : ()),
			($self->runtests ? (testLevel => 'runLocalTests') : ()),
		}
	);
}

1;

__END__