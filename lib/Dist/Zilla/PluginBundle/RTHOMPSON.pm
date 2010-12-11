use strict;
use warnings;
use v5.10;
use utf8;

package Dist::Zilla::PluginBundle::RTHOMPSON;
# ABSTRACT: RTHOMPSON's Dist::Zilla Configuration

use Moose;
use MooseX::Has::Sugar;
with 'Dist::Zilla::Role::PluginBundle::Easy';

sub mvp_multivalue_args { qw( -remove copy_file move_file ) }

# Returns true for strings of 'true', 'yes', or positive numbers,
# false otherwise.
sub _parse_bool {
    $_ ||= '';
    return 1 if $_[0] =~ m{^(true|yes|1)$}xsmi;
    return if $_[0] =~ m{^(false|no|0)$}xsmi;
    die "Invalid boolean value $_[0]. Valid values are true/false yes/no 1/0";
}

sub configure {
    my $self = shift;

    my $defaults = {
        # AutoVersion by default
        version => 'auto',
        # Assume that the module is experimental unless told
        # otherwise.
        version_major => 0,
        # Assume that synopsis is perl code and should compile
        # cleanly.
        synopsis_is_perl_code => 1,
        # Realease to CPAN for real
        release => 'real',
        # Archive releases
        archive => 1,
        archive_directory => 'releases',
        # Copy README.pod from build dir to dist dir, for Github and
        # suchlike.
        copy_file => [],
        move_file => [ 'README.pod' ],
    };
    my %args = (%$defaults, %{$self->payload});

    # Use the @Filter bundle to handle '-remove'.
    if ($args{-remove}) {
        $self->add_bundle('@Filter' => { %args, -bundle => '@RTHOMPSON' });
        return;
    }

    # Add appropriate version plugin
    if (lc($args{version}) eq 'auto') {
        $self->add_plugins(
            [ 'AutoVersion' => { major => $args{version_major} } ]
        );
    }
    elsif (lc($args{version}) eq 'disable') {
        # No-op
        $self->add_plugins(
            [ 'StaticVersion' => { version => '' } ]
        );
    }
    else {
        # If version is empty, this is a no-op.
        $self->add_plugins(
            [ 'StaticVersion' => { version => $args{version} } ]
        );
    }

    # Copy files from build dir
    $self->add_plugins(
        [ 'CopyFilesFromBuild' => {
            copy => ($args{copy_file} || [ '' ]),
            move => ($args{move_file} || [ '' ])
        } ]
    );

    # Decide whether to test SYNOPSIS for syntax.
    if (_parse_bool($args{synopsis_is_perl_code})) {
        $self->add_plugins('SynopsisTests');
    }

    # Choose release plugin
    given ($args{release}) {
        when (lc eq 'real') {
            $self->add_plugins('UploadToCPAN')
        }
        when (lc eq 'fake') {
            $self->add_plugins('FakeRelease')
        }
        when (lc eq 'none') {
            # No release plugin
        }
        when ($_) {
            $self->add_plugins("$_")
        }
        default {
            # Empty string is the same as 'none'
        }
    }

    # Choose whether and where to archive releases
    if (_parse_bool($args{archive})) {
        $self->add_plugins(
            ['ArchiveRelease' => {
                directory => $args{archive_directory},
            } ]
        );
    }

    # All the invariant plugins
    $self->add_plugins(
        # @Basic
        'GatherDir',
        'PruneCruft',
        'ManifestSkip',
        'MetaYAML',
        'License',
        'ExecDir',
        'ShareDir',
        'MakeMaker',
        'Manifest',

        # Mods
        'PkgVersion',
        # TODO: Only add PodWeaver if weaver.ini exists
        'PodWeaver',

        # Generated Docs
        'InstallGuide',
        ['ReadmeAnyFromPod', 'text', {
            filename => 'README',
            type => 'text',
        }],
        # This one gets copied out of the build dir by default, and
        # does not become part of the dist.
        ['ReadmeAnyFromPod', 'pod', {
            filename => 'README.pod',
            type => 'pod',
        }],

        # This can't hurt. It's a no-op if github is not involved.
        'GithubMeta',

        # Tests
        'CriticTests',
        'PodTests',
        'HasVersionTests',
        'PortabilityTests',
        'UnusedVarsTests',
        ['CompileTests' => {
            # The test files don't seem to compile in the context of
            # this test. But it's ok, because if they really have
            # problems, they'll fail to compile when they run.
            skip => 'Test$',
        }],
        'KwaliteeTests',
        'ExtraTests',

        # Prerequisite checks
        'ReportVersions',
        'MinimumPerl',
        'AutoPrereqs',

        # Release checks
        'CheckChangesHasContent',

        # Release
        'NextRelease',
        'TestRelease',
        'ConfirmRelease',

    );
}
1; # Magic true value required at end of module
__END__

=head1 SYNOPSIS

In dist.ini:

    [@RTHOMPSON]

=head1 DESCRIPTION

This plugin bundle, in its default configuration, is equivalent to:

    [AutoVersion]
    major = 0
    [GatherDir]
    [PruneCruft]
    [ManifestSkip]
    [MetaYAML]
    [License]
    [ExecDir]
    [ShareDir]
    [MakeMaker]
    [Manifest]
    [PkgVersion]
    [PodWeaver]
    [InstallGuide]
    [ReadmeAnyFromPod / text ]
    filename = README
    type => text
    [ReadmeAnyFromPod / pod ]
    filename = README.pod
    type => pod
    [GithubMeta]
    [CriticTests]
    [PodTests]
    [HasVersionTests]
    [PortabilityTests]
    [UnusedVarsTests]
    [CompileTests]
    skip = Test$
    [SynopsisTests]
    [KwaliteeTests]
    [ExtraTests]
    [ReportVersions]
    [MinimumPerl]
    [AutoPrereqs]
    [CheckChangesHasContent]
    [NextRelease]
    [TestRelease]
    [ConfirmRelease]
    [CopyFilesFromBuild]
    move_file = README.pod
    [UploadToCPAN]
    [ArchiveRelease]
    directory = releases

There are several options that can change the default configuation,
though.

=head1 OPTIONS

The following options can be specified after the C<[@RTHOMPSON]> line
in your F<dist.ini>, and change the default behavior of the bundle.

=head2 C<-remove>

This option can be used to remove specific plugins from the bundle. It
can be used multiple times.

Obviously, the default is not to remove any plugins.

Example:

    ; Remove these two plugins from the bundle
    -remove = CriticTests
    -remove = GithubMeta

=head2 C<version>, C<version_major>

This option is used to specify the version of the module. The default
is 'auto', which uses the AutoVersion plugin to choose a version
number. You can also set the version number manually, or choose
'disable' to prevent this bundle from supplying a version.

Examples:

    ; Use AutoVersion (default)
    version = auto
    version_major = 0
    ; Use manual versioning
    version = 1.14.04
    ; Provide no version, so that another plugin can handle it.
    version = disable

=head2 C<copy_file>, C<move_file>

If you want to copy or move files out of the build dir and into the
distribution dir, use these two options to specify those files. Both
of these options can be specified multiple times.

The most common reason to use this would be to put automatically
generated files under version control. For example, Github likes to
see a README file in your distribution, but if your README file is
auto-generated during the build, you need to copy each newly-generated
README file out of its build directory in order for Github to see it.

If you want to include an auto-generated file in your distribution but
you I<don't> want to include it in the build, use C<move_file> instead
of C<copy_file>.

The default is to move F<README.pod> out of the build dir. If you use
C<move_file> in your configuration, this default will be disabled, so
if you want it, make sure to include it along with your other
C<move_file>s.

Example:

    copy_file = README
    move_file = README.pod
    copy_file = README.txt

=head2 C<synopsis_is_perl_code>

If this is set to true (the default), then the SynopsisTests plugin
will be enabled. This plugin checks the perl syntax of the SYNOPSIS
sections of your modules. Obviously, if your SYNOPSIS section is not
perl code (case in point: this module), you should set this to false.

Example:

    synopsis_is_perl_code = false

=head2 C<release>

This option chooses the type of release to do. The default is 'real,'
which means "really upload the release to CPAN" (i.e. load the
C<UploadToCPAN> plugin). You can set it to 'fake,' in which case the
C<FakeRelease> plugin will be loaded, which simulates the release
process without actually doing anything. You can also set it to 'none'
if you do not want this module to load any release plugin, in which
case your F<dist.ini> file should load a release plugin directly. Any
other value for this option will be interpreted as a release plugin
name to be loaded.

Examples:

    ; Release to CPAN for real (default)
    release = real
    ; For testing, you can do fake releases
    release = fake
    ; Or you can choose no release plugin
    release = none
    ; Or you can specify a specific release plugin.
    release = OtherReleasePlugin

=head2 C<archive>, C<archive_directory>

If set to true, the C<archive> option copies each released version of
the module to an archive directory, using the C<ArchiveRelease>
plugin. This is the default. The name of the archive directory is
specified using C<archive_directory>, which is F<releases> by default.

Examples:

    ; archive each release to the "releases" directory
    archive = true
    archive_directory = releases
    ; Or don't archive
    archive = false

=for Pod::Coverage  configure mvp_multivalue_args

=head1 BUGS AND LIMITATIONS

This module should be more configurable. Suggestions welcome.

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
