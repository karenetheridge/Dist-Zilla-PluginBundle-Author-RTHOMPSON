use strict;
use warnings;
use v5.10;
use utf8;

package Dist::Zilla::PluginBundle::RCT;
# ABSTRACT: RCT's Dist::Zilla Configuration

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

=for Pod::Coverage  configure

=cut

sub configure {
    my $self = shift;
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
        'PodWeaver',

        # Generated Docs
        'InstallGuide',
        'ReadmeFromPod',
        'ReadmeMarkdownFromPod',
        ['CopyFilesFromBuild' => {
            # This is for GitHub and similar things the expect a
            # README under version control.
            file => [ 'README.mkdn' ],
        }],
        'GithubMeta',

        # Tests
        'CriticTests',
        'PodTests',
        'HasVersionTests',
        'PortabilityTests',
        'SynopsisTests',
        'UnusedVarsTests',
        ['CompileTests' => {
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
        'ArchiveRelease',

        # 'FakeRelease',
        'UploadToCPAN',

    );
}
1; # Magic true value required at end of module
__END__

=head1 SYNOPSIS

In dist.ini:

    [@RCT]

=head1 DESCRIPTION

See the code. It lists all the plugins that it loads quite clearly.

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
