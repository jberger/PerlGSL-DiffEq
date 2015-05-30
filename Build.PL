use strict;
use warnings;

use 5.008000;
use Module::Build;
require Alien::GSL;

my $min_gsl_version = 1.15;
my $gsl_version = Alien::GSL->config('version');

if ($gsl_version < $min_gsl_version) {
  print "PerlGSL::DiffEq requires GSL version >= $min_gsl_version but you only have $gsl_version\n";
  exit 0;
} 

my $build = Module::Build->new(
    module_name       => 'PerlGSL::DiffEq',
    dist_version_from => 'lib/PerlGSL/DiffEq.pm',
    dist_abstract     => 'A Perlish Interface to Solving ODEs using GSL v1.15+',
    dist_author       => 'Joel Berger <joel.a.berger@gmail.com>',
    license           => 'perl',
    requires          => {
      'perl' => '5.008',
      parent => 0,
    },
    configure_requires => {
      'Module::Build' => '0.38',
      'Alien::GSL' => '1.00',
    },
    build_requires    => {
      'ExtUtils::CBuilder' => 0,
    },
    c_source => 'src',
    extra_compiler_flags => '-Isrc ' . Alien::GSL->cflags,
    extra_linker_flags   => Alien::GSL->libs,
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/PerlGSL-DiffEq",
      bugtracker => "http://github.com/jberger/PerlGSL-DiffEq/issues",
    },
    no_index => {
      file => [ 'README.pod' ],
    },
  },
);

$build->create_build_script;

