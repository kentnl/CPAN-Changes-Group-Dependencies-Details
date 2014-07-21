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
use charnames ':full';

























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

my $valid_phases = { map { $_ => 1 } qw( configure build runtime test develop ) };
my $valid_types  = { map { $_ => 1 } qw( requires recommends suggests conflicts ) };

lsub arrow_join           => sub { qq[\N{NO-BREAK SPACE}\N{RIGHTWARDS ARROW}\N{NO-BREAK SPACE}] };
lsub change_type_method   => sub { $valid_change_types->{ $_[0]->change_type }->{method} };
lsub change_type_notation => sub { $valid_change_types->{ $_[0]->change_type }->{notation} };
lsub group_name_split     => sub { q[ / ] };
lsub group_type_split     => sub { q[ ] };
lsub new_prereqs          => sub { croak q{required parameter <new_prereqs> missing} };
lsub old_prereqs          => sub { croak q{required parameter <old_prereqs> missing} };

lsub diffs => sub {
  return [ $_[0]->prereqs_diff->diff( phases => [ $_[0]->phase ], types => [ $_[0]->type ], ) ];
};

lsub group_name => sub {
  return $_[0]->change_type . $_[0]->group_name_split . $_[0]->phase . $_[0]->group_type_split . $_[0]->type;
};

lsub prereqs_diff => sub {
  return CPAN::Meta::Prereqs::Diff->new( old_prereqs => $_[0]->old_prereqs, new_prereqs => $_[0]->new_prereqs, );
};

has change_type => (
  is       => 'ro',
  required => 1,
  isa      => sub {
    local $" = q[, ];
    croak "change_type must be one of <@{ keys %{$valid_change_types } }>, not $_[0]"
      unless exists $valid_change_types->{ $_[0] };
  },
);

lsub change_formatter => sub {
  my ($self) = @_;
  if ( 'toggle' eq $self->change_type_notation ) {
    return sub {
      my $diff   = shift;
      my $output = $diff->module;
      if ( $diff->requirement ne '0' ) {
        $output .= q[ ] . $diff->requirement;
      }
      return $output;
    };
  }
  return sub {
    my $arrow_join = $self->arrow_join;
    return sub {
      my $diff = shift;
      return $diff->module . q[ ] . $diff->old_requirement . $arrow_join . $diff->new_requirement;
    };
  };
};

has phase => (
  is       => 'ro',
  required => 1,
  isa      => sub {
    local $" = q[, ];
    croak "phase must be one of <@{ keys %{$valid_phases } }>, not $_[0]" unless exists $valid_phases->{ $_[0] };
  },
);

has type => (
  is       => 'ro',
  required => 1,
  isa      => sub {
    local $" = q[, ];
    croak "type must be one of <@{ keys %{$valid_types } }>, not $_[0]" unless exists $valid_types->{ $_[0] };
  },
);

sub changes {
  my ($self)     = @_;
  my $method     = $self->change_type_method;
  my (@relevant) = grep { $_->$method() } @{ $self->diffs };
  return [] unless @relevant;
  my $formatter = $self->change_formatter;
  return [ map { $formatter->($_) } @relevant ];
}

sub attach_to {
  my ( $self, $release, $force ) = @_;
  my $changes    = $self->changes;
  my $group_name = $self->group_name;
  $release->delete_group($group_name);
  return unless ( @{$changes} or $force );
  $release->add_group($group_name);
  $release->set_changes( { group => $group_name }, @{$changes} );
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

=head1 SYNOPSIS

  my $old_prereqs => CPAN::Meta->load_file('Dist-Foo-1.01/META.json')->effective_prereqs,
  my $new_prereqs => CPAN::Meta->load_file('Dist-Foo-1.01/META.json')->effective_prereqs,

  my $group =  CPAN::Changes::Group::Dependencies::Details->new(
    old_prereqs => $old_prereqs,
    new_prereqs => $new_prereqs,
    change_type => 'Added',
    phase       => 'runtime',
    type        => 'requires',
  )->attach_to($cpan_changes_release);

=head1 DESCRIPTION

This is simple an element of refactoring in my C<dep_changes> script.

It is admittedly not very useful in its current incarnation due to needing quite a few instances
to get anything done with them, but that's mostly due to design headaches about thinking of I<any> way to solve a few problems.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
