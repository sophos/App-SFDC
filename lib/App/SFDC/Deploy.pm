package App::SFDC::Deploy;

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

=option --all -a

If set, Deploy will read every file from src/ and attempt to deploy them,
rather than reading from STDIN.

=cut

option 'all',
	is => 'ro',
	short => 'a';

=option --deletions --no-deletions

If set, Deploy will add src/destructiveChanges.xml,
src/destructiveChangesPre.xml, and src/destructChangesPost.xml to the package
if they exist. Set by default.

=cut

option 'deletions',
	is => 'ro',
	default => 1,
	negativable => 1;

=option --files -f

Specific files for deployment: can be specified multiple times. If this is
set, it overrides --all; if neither this nor --all is set, Deploy reads from
STDIN.

=cut

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

=option --rollback --no-rollback

If set, sends the 'rollbackOnError' header to Salesforce so that if any
component fails to deploy, the deployment as a whole fails. Set by default.

=cut

option 'rollback',
	is => 'ro',
	default => 0,
	negativable => 1;

=option --runtests -t

If set, sets the 'testLevel' header to 'runLocalTests'. Unset by defailt.

=cut

option 'runtests',
	short => 't',
	is => 'ro',
	default => 0;

=option --validate -v

If set, perform a dry-run deployment.

=cut

option 'validate',
	is => 'ro',
	short => 'v',
	default => 0;

=attr zipFile



=cut

has 'zipFile',
	lazy => 1,
	is => 'rw',
	default => sub {
		my $self = shift;

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