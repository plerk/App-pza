use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );

package
  Mock {
  
  our %uage;  
}

package
  Pod::Usage {

  use Carp qw( croak );
  use base qw( Exporter );
  our @EXPORT_OK = qw( pod2usage );

  sub pod2usage
  {
    croak "mock pod2usage only takes a hash argument (not hash ref)"
      if @_ % 2;
    my %args = @_;
    
    %Mock::usage = %args;
    
    my $exit = delete $args{'-exitval'} // 2;
    
    exit $exit;
  }

}

1;
