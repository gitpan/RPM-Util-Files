use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'RPM::Util::Files',
    license => 'perl',
    dist_author => 'Toru Yamaguchi <zigorou@cpan.org>',
    dist_version_from => 'lib/RPM/Util/Files.pm',
    # dist_abstract => 'test',
    build_requires => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'File::stat' => 0,
        'File::Find::Object' => 0,
        'Merge::HashRef' => 0,
        'Class::Accessor::Fast' => 0,
        'Pod::Usage' => 0,
        'Getopt::Long' => 0
    },
    script_files => [ 'bin/rpm-files-maker' ],
    add_to_cleanup => [ 
        'RPM-Util-Files-*',
        '_build',
        'blib'
    ],
);

$builder->create_build_script();
