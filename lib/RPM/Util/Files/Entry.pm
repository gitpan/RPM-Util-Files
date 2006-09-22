package RPM::Util::Files::Entry;

use strict;
use warnings;

our $VERSION = '0.10';

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/
  entry_type
  entry
  path
  user
  group
  mode
/);

sub to_string {
    my ($self, $use_attr) = @_;
    
    my @to_string = ();

    push(@to_string, $self->path);
    unshift(@to_string, '%' . $self->entry_type) unless ($self->entry_type eq 'file');
    unshift(@to_string, sprintf("%%attr(%s, %s, %s)", $self->mode, $self->user || '-', $self->group || '-')) if ($use_attr);

    return join(" ", @to_string);
}

1; # End of RPM::Util::Files::Entry

=head1 NAME

RPM::Util::Files::Entry -- Entry item class in %files list.
=head1 VERSION

This document describes RPM::Util::Files::Entry version 0.0.1

=cut

=head1 SYNOPSIS

    use RPM::Util::Files::Entry;

    my $entry = RPM::Util::Files::Entry->new({
      'entry_type' => 'file',
      'entry' => '/var/tmp/some-package-version-root/usr/local/bin/some',
      'path' => '/usr/local/bin/some',
      'user' => 'root',
      'group' => 'root',
      'mode' => '0644'
    });

=head1 METHODS

=head2 to_string($use_attr)

Getting entry as string.
$use_attr parameter is true, using B<%attr> parameter.

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rpm-util-files-entry at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RPM-Util-Files>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RPM::Util::Files::Entry

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RPM-Util-Files>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RPM-Util-Files>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RPM-Util-Files>

=item * Search CPAN

L<http://search.cpan.org/dist/RPM-Util-Files>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Toru Yamaguchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

