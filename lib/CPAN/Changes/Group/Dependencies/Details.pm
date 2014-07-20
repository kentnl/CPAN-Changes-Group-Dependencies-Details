use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Changes::Group::Dependencies::Details;

our $VERSION = '0.001000';

# ABSTRACT: Full details of dependency changes.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use MooX::Lsub qw( lsub );
use Carp qw( croak );
use CPAN::Meta::Prereqs::Diff;

lsub arrow_join  => sub { qq[\x{A0}\x{2192}\x{A0}] };
lsub new_prereqs => sub { croak q{required parameter <new_prereqs> missing} };
lsub old_prereqs => sub { croak q{required parameter <old_prereqs> missing} };
lsub prereqs_diff => sub {
  my ($self) = @_;
  return CPAN::Meta::Prereqs::Diff->new(
    old_prereqs => $self->old_prereqs,
    new_prereqs => $self->new_prereqs,
  );
};

my $valid_change_types = {
  'Added' => {
    method   => 'is_addition',
    notation => 'toggle',
  },
  'Changed' => {
    method   => 'is_change',
    notation => 'change',
  },
  'Upgrade' => {
    method => sub { $_[0]->is_change && $_[0]->is_upgrade },
    notation => 'change',
  },
  'Downgrade' => {
    method => sub { $_[0]->is_change && $_[0]->is_downgrade },
    notation => 'change',
  },
  'Removed' => {
    method   => 'is_removal',
    notation => 'toggle',
  },
};

has change_type => (
  is       => 'ro',
  required => 1,
  isa      => sub {
    local $" = q[, ];
    croak "change_type must be one of <@{ keys %{$valid_change_types } }>, not $_[0]"
      unless exists $valid_change_types->{ $_[0] };
  }
);

my $valid_phases = { map { $_ => 1 } qw( configure build runtime test develop ) };

has phase => (
  is       => 'ro',
  required => 1,
  isa      => sub {
    local $" = q[, ];
    croak "phase must be one of <@{ keys %{$valid_phases } }>, not $_[0]" unless exists $valid_phases->{ $_[0] };
  }
);

my $valid_types = { map { $_ => 1 } qw( requires recommends suggests conflicts ) };

has type => (
  is       => 'ro',
  required => 1,
  isa      => sub {
    local $" = q[, ];
    croak "type must be one of <@{ keys %{$valid_types } }>, not $_[0]" unless exists $valid_types->{ $_[0] };
  }
);

sub changes {
  my ($self)  = @_;
  my (@diffs) = $self->prereqs_diff->diff(
    phases => [ $self->phase ],
    types  => [ $self->type ],
  );
  my $info   = $valid_change_types->{ $self->change_type };
  my $method = $info->{method};
  my (@relevant) = grep { $_->$method() } @diffs;
  return [] unless @relevant;
  my $formatter;
  if ( 'toggle' eq $info->{notation} ) {
    $formatter = sub {
      my $diff   = shift;
      my $output = $diff->module;
      if ( $diff->requirement ne '0' ) {
        $output .= q[ ] . $diff->requirement;
      }
      return $output;
    };
  }
  elsif ( 'change' eq $info->{notation} ) {
    my $arrow_join = $self->arrow_join;
    $formatter = sub {
      my $diff = shift;
      return $diff->module . q[ ] . $diff->old_requirement . $arrow_join . $diff->new_requirement;
    };
  }

  return [ map { $formatter->($_) } @relevant ];
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Group::Dependencies::Details - Full details of dependency changes.

=head1 VERSION

version 0.001000

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
