package App::SFDC::Retrieve;
# ABSTRACT: Retrive files from SFDC

use strict;
use warnings;

use Data::Dumper;
use File::HomeDir;
use File::Path 'rmtree';
use File::Share 'dist_file';
use FindBin '$Bin';
use Log::Log4perl ':easy';

use WWW::SFDC::Manifest;
use WWW::SFDC::Zip;

use Moo;
use MooX::Options;
with 'App::SFDC::Role::Logging',
    'App::SFDC::Role::Credentials';

=option --clean --no-clean

Whether or not to clean src/ before retrieving. Defaults to the value of --all.

=cut

option 'clean',
    doc => 'Whether or not to clean src/ before retrieving. Defaults to the value of --all',
    default => 1,
    negativable => 1,
    is => 'ro';

=option --all -a

Retrieve everything. If set, we'll read from all folders and manifests specified.

=cut

option 'all',
    doc => 'Retrieve everything, not just a subset',
    short => 'a',
    is => 'ro';

=option --file -f

Retrieve only specified files. You can use various calling style, for instance:

    -f "src/profiles/blah.profile" --file "src/classes/blah.cls,src/classes/foo.cls"

Setting this will ignore any manifests or folders otherwise specified.

=cut

option 'file',
    doc => 'Retrieve only specified files',
    is => 'ro',
    format => 's',
    repeatable => 1,
    short => 'f',
    autosplit => ',';

=option --manifest

Use the specified manifests(s). If no manifest is specified, Retrieve will
use the base.xml included with this distribution, and if --all is set, the
all.xml included.

=cut

sub _getFile {
    my $file = shift;
    -e && return $_ for "lib/$file", File::HomeDir->my_home."/.app-sfdc/$file";
    return PerlApp::extract_bound_file($file) if defined $PerlApp::VERSION;
    return dist_file("App-SFDC", $file);
}

option 'manifest',
    doc => 'Use specified manifest(s)',
    is => 'ro',
    format => 's',
    lazy => 1,
    repeatable => 1,
    default => sub {
        my $self = shift;
        [
            _getFile("manifests/base.xml"),
            $self->all
                ? _getFile("manifests/all.xml")
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
        my $manifest = WWW::SFDC::Manifest->new(
            constants => $self->_session->Constants,
            apiVersion => $self->_session->apiVersion,
        );

        return $manifest->addList(@{$self->file})
            if $self->file;

        $manifest->readFromFile($_) for @{$self->manifest};

        $manifest->addList(
            $self->_session->Metadata->listMetadata(@folders)
        ) if $self->all and @folders;

        return $manifest;
    };


=option --plugins

The plugins file to use. This file should provide:

    sub _retrieveTimeMetadataChanges {
        my ($path, $content) = @_;
        # This returns a new version of $content with any
        # changes you need made to it. You may use this to
        # compress profiles, remove files or nodes which
        # are causing issues in your organisation, ensure
        # standardised indentation, etc. For instance, if
        # you send outbound messages to dev instances of
        # other systems from your dev org, you may wish
        # to ensure those are set to the production URL.
        return $content;
    }

    our @folders = (
        {type => 'Document', folder => 'unfiled$public'},
        {type => 'EmailTemplate', folder => 'unfiled$public'},
        {type => 'Report', folder => 'unfiled$public'},
    );

The default is the retrieve.plugins.pm included with this
distribution.

=cut

option 'plugins',
    doc => 'Additional behaviour can be defined by plugins',
    is => 'ro',
    format => 's',
    default => _getFile("plugins/retrieve.plugins.pm"),
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

=method execute()

Retrieve metadata from Salesforce.com.

=cut

sub execute {
    my $self = shift;

    $self->_loadPlugins;

    rmtree 'src'
        if $self->all and $self->clean and -e 'src';

    mkdir 'src' unless -d 'src';

    WWW::SFDC::Zip::unzip(
        'src',
        $self->_session->Metadata->retrieveMetadata(
            $self->_manifest->manifest()
        ),
        \&_retrieveTimeMetadataChanges
   );
}

1;

__END__
