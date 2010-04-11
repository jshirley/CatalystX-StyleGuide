package StyleGuide::Widget;

use Moose;

has 'template' => (
    is => 'ro',
    isa => 'Str',
);

has 'app' => (
    is => 'rw',
    isa => 'Catalyst',
);

has 'classes' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [ ] },
    lazy    => 1
);

sub run { 
    die('Virtual Method: ' . __PACKAGE__ . ' must implement a run method');
}

1;

