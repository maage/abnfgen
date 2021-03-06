#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use List::Util qw( sum max );
use Scalar::Util qw( refaddr );

use constant MAX_LIN_PROB => 100;
use constant MAX_DEPTH    => 10;

my %Rule = ();

my $model    = {};
my @sentence = (
  "The quick brown fox jumped over the lazy dog.",
  "Now is the time for all good men to come to the aid of the party.",
  "It's not over till it's over",
  "It's not over till the fat lady sings."
);

sentence( $model, $_ ) for @sentence;

print Dumper( $model );

exit;

sub def(@);

=for test

my @dist = ( 0 ) x 10;
for ( 1 .. 1000 ) {
  my $r = pow_rand( 100, 1 );
  die "$r >= 100" if $r >= 100;
  die "$r < 0" if $r < 0;
  my $q = int( $r / 10 );
  $dist[$q]++;
}
my $max = max @dist;
for my $bar ( @dist ) {
  print '', '#' x ( $bar * 80 / $max ), "\n";
}
exit;

=cut

def lc_letter => opt( 'a' .. 'z' );
def uc_letter => opt( 'A' .. 'Z' );
def letter    => opt( \'lc_letter', \'uc_letter' );
def word      => rep( \'lc_letter', 1, 20, 3 );
def
 sentence => seq( \'uc_letter', \'word' ),
 rep( seq( ' ', \'word' ), 0, 10, 3 ), '.';
def var_char => opt( [ 26, \'letter' ], [ 10, \'digit' ] );
def var_name => \'letter', rep( \'var_char', 0, 10, 3 );
def digit => opt( '0' .. '9' );
def one_to_nine => opt( '1' .. '9' );
def number =>
 opt( '0', seq( \'one_to_nine', rep( \'digit', 0, 9, 3 ) ) );
def assign => opt( 'LET ', '' ), \'var_name', ' = ', \'num_expr';
def
 for_stmt => 'FOR ',
 \'var_name', ' = ', \'num_expr', ' TO ', \'num_expr';
def next_stmt => 'NEXT';
def for_next => \'for_stmt', "\n", \'program', \'next_stmt';
def atom => opt( \'number', \'var_name' );
def
 oper => \'num_expr',
 ' ', opt( '+', '-', '*', '/' ), ' ', \'num_expr';
def paren => '(', \'num_expr', ')';
def num_expr => opt( [ 5, \'atom' ], \'paren', \'oper' );
def
 print_stmt => 'PRINT ',
 \'num_expr', rep( seq( opt( ', ', '; ' ), \'num_expr' ), 0, 3 );
def statement =>
 opt( [ 5, \'assign' ], [ 5, \'print_stmt' ], \'for_next' );
def line => \'statement', "\n";
def program => rep( \'line', 0, 8 );

print rule( 'program' )->();
print rule( 'sentence' )->(), "\n";

# Accepts a list of options of this form:
#
# [ probability, action ]
#
# Probability is an integer - no upper bound is defined
#
# action is one of
#
#   * a scalar          - the action returns that value
#   * a coderef         - the action is invoked and its return value
#                         used

sub def(@) {
  my ( $name, @code ) = @_;
  $Rule{$name} = seq( @code );
}

sub limit {
  my $cb = shift;
  my $limiter ||= do {
    my $depth = 0;
    sub {
      my $cb = shift;
      ++$depth;
      if ( $depth >= MAX_DEPTH ) {
        --$depth;
        warn "DEPTH LIMIT\n";
        return '';
      }
      my $rv = $cb->();
      --$depth;
      return $rv;
    };
  };
  return $cb if refaddr $cb == refaddr $limiter;
  return sub { $limiter->( $cb ) };
}

sub norm {
  my $opt = shift;
  return norm( [ 1, $opt ] ) unless 'ARRAY' eq ref $opt;
  if ( ref $opt->[1] ) {
    if ( 'SCALAR' eq ref $opt->[1] ) {
      my $v = ${ $opt->[1] };
      $opt->[1] = rule( $v );
    }
    elsif ( 'CODE' ne ref $opt->[1] ) {
      die "Not a code or scalar reference";
    }
  }
  else {
    my $v = $opt->[1];
    $opt->[1] = sub { $v };
  }
  $opt->[1] = limit( $opt->[1] );
  return $opt;
}

sub opt {
  my @opt = map { norm( $_ ) } @_;
  die "No options to switch between" if @opt == 0;
  return $opt[0][1] if @opt == 1;

  my $prob = sum( map { $_->[0] } @opt );
  if ( $prob < MAX_LIN_PROB ) {
    my @flat = map { ( $_->[1] ) x $_->[0] } @opt;
    return sub { $flat[ rand $prob ]->() };
  }
  else {
    die "Oops!\n";
  }
}

sub seq {
  my @seq = map { opt( $_ ) } @_;
  return sub { '' }
   if @seq == 0;
  return $seq[0] if @seq == 1;
  return sub {
    join '', map { $_->() } @seq;
  };
}

sub pow_rand {
  my ( $limit, $power ) = @_;
  rand( $limit**( 1 / $power ) )**$power;
}

sub rep {
  my $cb = opt( shift );
  my ( $min, $max, $pow ) = @_;
  $pow = 1 unless defined $pow;
  return sub {
    join '',
     map { $cb->() } 1 .. $min + pow_rand( $max + 1 - $min, $pow );
  };
}

sub rule {
  my $name = shift;
  return sub {
    ( $Rule{$name} || die "Rule $name not defined\n" )->();
  };
}

#####
#
# Build a sort of word based Markov model from a corpus of text
#
#####

use constant ORDER => 2;

sub at_depth {
  my ( $cb, $nd, $depth, @c ) = @_;
  print Dumper( { nd => $nd, depth => $depth, c => \@c } );
  my $word = @c ? shift @c : '';
  if ( $depth > 1 ) {
    at_depth( $cb, $nd->{$word} ||= {}, $depth - 1, @c );
  }
  else {
    $cb->( $nd->{$word} ||= [ 0, {} ], @c );
  }
}

sub words {
  my ( $nd, @c ) = @_;
  print 'words: ', Dumper( \@c );
  if ( @c ) {
    at_depth sub {
      my ( $rec, @words ) = @_;
      $rec->[0]++;
      words( $rec->[1], @words );
    }, $nd, ORDER, @c;
  }
}

sub sentence {
  my ( $root, $sentence ) = @_;
  words( $root, split /\s+/, $sentence );
}

sub as_opt {
  my $root = shift;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl
