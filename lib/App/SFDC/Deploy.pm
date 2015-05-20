package App::SFDC::Deploy;
# ABSTRACT: Deploy files to SFDC

use strict;
use warnings;

use Data::Dumper;
use File::Find 'find';
use Log::Log4perl ':easy';

use WWW::SFDC::Manifest;
use WWW::SFDC::Metadata;
use WWW::SFDC::Zip;

use Moo;
use MooX::Options;
with 'App::SFDC::Role::Logging',
    'App::SFDC::Role::Credentials';

=option --all -a

Deploy all files in the src/ directory.

=cut

option 'all',
    doc => 'Deploy all files in the src/ directory.',
    is => 'ro',
    short => 'a';

=option --files -f

Files to deploy. Defaults to a list read from STDIN, unless all is set.

You can use various calling style, for instance:

    -f "src/profiles/blah.profile" --file "src/classes/blah.cls,src/classes/foo.cls"

=cut

option 'files',
    doc => 'Files to deploy. Defaults to a list read from STDIN, unless all is set.',
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
                'src/';
        } else {
            INFO 'Reading files from STDIN';
            @filelist = <>;
        }
        DEBUG "File list for deployment: ". Dumper \@filelist;
        return \@filelist;
    };

=option --deletions --no-deletions

Whether or not to deploy deletions. By default, Deploy includes any of the
following, if they're present:

    destructiveChanges.xml
    destructiveChangesPre.xml
    destructiveChangesPost.xml

=cut

option 'deletions',
    doc => 'Whether or not to deploy deletions.',
    is => 'ro',
    default => 1;

=option --validate -v

If set, set 'isCheckOnly' to true, i.e. perform a validation deployment.

=cut

option 'validate',
    doc => 'Perform a validation deployment',
    is => 'ro',
    short => 'v';

=option --tests -t

If set, set 'testLevel' to 'RunLocalTests', i.e. run all tests in your own
namespace. This has no effect on Production, and doesn't work before API v34.0

=cut

option 'tests',
    doc => 'Run local tests before deployment',
    is => 'ro',
    short => 't';

=method execute()

Perform a validation to Salesforce.com.

=cut

has '_manifest',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return WWW::SFDC::Manifest
            ->new(apiversion => $self->apiversion)
            ->addList(@{$self->files})
            ->writeToFile('src/package.xml');
    };


sub execute {
    my $self = shift;
    return WWW::SFDC::Metadata->instance()->deployMetadata(
        WWW::SFDC::Zip::makezip(
            'src/',
            $self->_manifest->getFileList,
            ($self->deletions
                ? ('destructiveChanges.xml', 'destructiveChangesPre.xml', 'destructiveChangesPost.xml')
                : ()
            ),
            'package.xml'
        ), {
            singlePackage => 'true', # with this set, deployments starts after 1min; without, up to 75
            rollbackOnError => 'true',
            ($self->tests ? (testLevel => 'RunLocalTests') : ()),
            ($self->validate ? (checkOnly => 'true') : ()),
        }
   );
}

1;

__END__

=head1 OVERVIEW

Deployments to Salesforce.com using the Metadata API. Consumes
L<App::SFDC::Role::Credentials> and L<App::SFDC::Role::Logging>
(look in those for extra options to be used).

To use this within your own script, use

    App::SFDC::Deploy->new_with_options->execute();

or

    App::SFDC::Deploy->new($MY_OPTIONS)->execute();
