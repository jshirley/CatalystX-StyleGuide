package StyleGuide::Model::Widget;

use Try::Tiny;
use Moose;

use Carp;

with 'Catalyst::Component::InstancePerContext';

extends 'Catalyst::Model';

has 'app' => (
    is  => 'rw',
    isa => 'Catalyst',
    handles => {
        'log' => 'log'
    }
);

sub build_per_context_instance {
    my ($self, $c) = @_;

    $self->app($c);
    return $self;
}

sub load {
    my ($self, $name) = @_;

    my $aname = $self->app->context_class;
    my $class = "$aname\::Widget\::$name";
    try {
        Class::MOP::load_class( $class )
    } catch {
        $self->log->error("Can't load widget $class: $_");
        return undef;
    };
    $self->log->debug("Successfully loaded widget: $class")
        if $self->app->debug;

    my %options = ();
    if ( exists $self->{$name} and ref $self->{$name} eq 'HASH' ) {
        %options = %{ $self->{$name} };
    }

    my $widget;
    try {
        $widget = $class->new( %options );
        $widget->app( $self->app );
    } catch {
        $self->log->error("Error loading widget: $name: $_");
    };
    return $widget;
}

1;

