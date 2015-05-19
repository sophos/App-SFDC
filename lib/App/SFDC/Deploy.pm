package App::SFDC::Deploy;

use strict;
use warnings;

use File::Find 'find';
use Log::Log4perl ':easy';

use WWW::SFDC::Manifest;
use WWW::SFDC::Metadata;
use WWW::SFDC::Zip;

use Moo;
use MooX::Options;
with 'App::SFDC::Role::Logging',
	'App::SFDC::Role::Credentials';

option 'all',
	is => 'ro',
	short => 'a';

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
		    find
				sub {
					push @filelist, $File::Find::name
						unless (-d or /(package\.xml|destructiveChanges(Pre|Post)?\.xml|\.bak)/)
				},
				'src';
		} else {
			INFO 'Reading files from STDIN';
			@filelist = <>;
		}
		DEBUG "File list for deployment: ". Dumper \@filelist;
		return \@filelist;
	};

option 'deletions',
	is => 'ro',
	default => 1;

option 'validate',
	is => 'ro',
	short => 'v';

option 'tests',
	is => 'ro',
	short => 't';


sub execute {
	return WWW::SFDC::Metadata->instance()->deployMetadata(
	    WWW::SFDC::Zip::makezip(
			'src',
			@fileList,
			($self->deletions
				? ('destructiveChanges.xml', 'destructiveChangesPre.xml', 'destructiveChangesPost.xml')
				: ()
			),
			'package.xml'
	    ), {
			singlePackage => 'true', # with this set, deployments starts after 1min; without, up to 75
			rollbackOnError => 'true',
			($self->tests ? (testLevel => 'testLevel') : ()),
			($self->validate ? (checkOnly => 'true') : ()),
	    }
   );
}

1;

__END__
