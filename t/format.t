use strict;
use warnings;

use Test::More;

# FILENAME: format.t
# CREATED: 07/26/14 20:47:10 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test format is expected

use CPAN::Changes 0.30;
use CPAN::Changes::Release;
use CPAN::Changes::Group;
use CPAN::Changes::Group::Dependencies::Details;
use Test::Differences qw( eq_or_diff );

my $release = CPAN::Changes::Release->new(
  version => '0.01',
  date    => '2014-07-26',
);

my $details = CPAN::Changes::Group::Dependencies::Details->new(
  old_prereqs => {},
  new_prereqs => {
    runtime => { requires => { 'Moo' => '1.0' } },
    develop => { suggests => { 'Moo' => '1.2' } },
  },
  change_type => 'Added',
  phase       => 'runtime',
  type        => 'requires',
);

{
  my $expected = <<'EOF';
 [Added / runtime requires]
 - Moo 1.0
EOF

  eq_or_diff( $details->serialize, $expected, 'Group serialization' );
}
$release->attach_group($details);
{
  my $expected = <<'EOF';
0.01 2014-07-26
 [Added / runtime requires]
 - Moo 1.0

EOF

  eq_or_diff( $release->serialize, $expected, 'Release serialization' );
}
pass("ok");

done_testing;

