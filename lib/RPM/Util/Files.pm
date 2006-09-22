package RPM::Util::Files;

use strict;
use warnings;

our $VERSION = '0.10';

use base qw/Class::Accessor::Fast/;

use File::Spec;
use File::stat;
use File::Find::Object;
use Merge::HashRef;

use Data::Dumper;

use RPM::Util::Files::Entry;

__PACKAGE__->mk_accessors(qw/
  files
  package_name
  build_root
  defattr
  use_attr
  force_root
  docdirs
  ignore_filters
  docs_filters
  config_filters
/);

sub new {
    my ($class, $options) = @_;

    $options = Merge::HashRef::merge_hashref({
        files => [],
        package_name => '',
        build_root => './',
        defattr => [644, 'root', 'root', undef],
        use_attr => 0,
        force_root => 1,
        docdirs => [],
        ignore_filters => [],
        docs_filters => [],
        config_filters => []
    }, $options);

    $options->{'build_root'} = File::Spec->rel2abs($options->{'build_root'});

    my $self = $class->SUPER::new($options);

    return $self;
}

sub make_files {
    my $self = shift;

    my $tree = File::Find::Object->new({
        followlinks => 0,
        nocrossfs => 0
      },
      $self->build_root
    );

    my $build_root = $self->build_root();

    while (my $entry = $tree->next) {
        my $path = File::Spec->rel2abs($entry);

        $path =~ s|^$build_root||o;

        next if ($self->do_filters('ignore', $entry, $path));
        next if ($self->docdirs_filter($entry, $path));
        next if ($self->do_filters('docs', $entry, $path));
        next if ($self->do_filters('config', $entry, $path));

        $self->dir_filter($entry, $path);
    }
}

sub to_string {
    my $self = shift;
    my %entry_order = (
        'config' => 0,
        'dir' => 1,
        'file' => 2,
        'docdir' => 3,
        'docs' => 4
    );

    my @files = 
        sort { $entry_order{$a->entry_type} <=> $entry_order{$b->entry_type} || $a->{path} cmp $b->{path} }
        @{$self->files};

    my @to_string = ();

    foreach my $file (@files) {
        push(@to_string, $file->to_string($self->use_attr));
    }

    unless ($self->use_attr) {
        unshift(@to_string, "");
        unshift(@to_string, $self->_to_string_defattr);
    }

    unshift(@to_string, "");
    unshift(@to_string, $self->_to_string_files);

    return join("\n", @to_string);
}

sub do_filters {
    my ($self, $entry_type, $entry, $path) = @_;

    my $filter_name = join('_', $entry_type, 'filters');

    my @filters = @{$self->${filter_name}()};

    return 0 unless (@filters);

    foreach my $filter (@filters) {
        if (&$filter($entry, $path)) {
            if ($entry_type ne 'ignore') {
                $self->add_files_entry($entry_type, $entry, $path);
            }

            return 1;
        }
    }

    return 0;
}

sub docdirs_filter {
    my ($self, $entry, $path) = @_;

    foreach my $docdir (@{$self->docdirs}) {
        if ($path =~ m|^$docdir|) {
            if ($path eq $docdir) {
                # ad hoc
                $self->add_files_entry('docdir', $entry, $path);
            }

            return 1;
        }
    }

    return 0;
}

sub dir_filter {
    my ($self, $entry, $path) = @_;

    if (-d $entry) {
        $self->add_files_entry('dir', $entry, $path);
    }
    else {
        $self->add_files_entry('file', $entry, $path);
    }
}

sub add_files_entry {
    my ($self, $entry_type, $entry, $path) = @_;

    return if ($path eq '');

    my $files = $self->files;
    my $stat = stat($entry);

    push(@$files, RPM::Util::Files::Entry->new({
        'entry_type' => $entry_type,
        'entry' => $entry,
        'path' => $path,
        'user' => ($self->force_root) ? 'root' : (getpwuid($stat->uid))[0],
        'group' => ($self->force_root) ? 'root' : (getgrgid($stat->gid))[0],
        'mode' => sprintf("%04o", $stat->mode & 0777)
    }));
}

sub _to_string_defattr {
    my $self = shift;

    return sprintf("%%defattr(%s)", join(", " =>
      map { (defined $_) ? $_ : '-' }
      @{$self->defattr})
    );
}

sub _to_string_files {
    my $self = shift;

    return ($self->package_name) ? sprintf("%%files %s", $self->package_name) : '%files';
}

1; # End of RPM::Util::Files

=pod

=head1 NAME

RPM::Util::Files - Generate %files list in RPM Specfile

=head1 VERSION

This document describes RPM::Util::Files version 0.0.1

=head1 SYNOPSIS

    use RPM::Util::Files;

    my $util = RPM::Util::Files->new({
      build_root => '/var/tmp/some-package-version-root',
      docs_filters => [
        sub {
          my $entry = shift;
          
          return $entry =~ /manuals/;
        }
      ],
      config_filters => [
        sub {
          my $entry = shift;
          
          return $entry =~ /\.conf$/;
        }
      ],
    });

    $util->make_files;
    print $util->to_string;

=head1 EXPORT

none.

=head1 METHODS

=head2 new($options)

Constructor of this module.

=over

=item ARGUMENTS

=over

=item 1. $options

$options argument must be HASH reference.

=over

=item package_name

This is subpackage name in Specfile.

=item build_root

This is root directory building and extractiong package.

=item defattr

For B<%defattr> parameter.
Using this option in I<use_attr> parameter is false. 

=item use_attr

For B<%attr>
Forcing user and group parameter is B<root>.

=item docdirs

For B<%docdir> parameter.
This parameter must be ARRAY reference.

=item ignore_filters

This is callback list to exclude entry from B<%files> list.
This parameter must be ARRAY reference.

=item docs_filters

For B<%docs> parameter.
This is callback list to include entry as B<%docs>.
This parameter must be ARRAY reference.

=item config_filters

For B<%config> parameter.
This is callback list to include entry as B<%config>.
This parameter must be ARRAY reference.

=back

=back

=back

=head2 make_files()

Searching files and making %files list.

=head2 to_string()

Getting %files as string.

=head2 do_filters()

Execute filters by entry_type

=head2 docdirs_filter()

Execute filters for %docdir

=head2 dir_filter()

Execute filters for %dir

=head2 add_files_entry()

Add entry to %files list

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rpm-util-files at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RPM-Util-Files>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RPM::Util::Files

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


__END__


