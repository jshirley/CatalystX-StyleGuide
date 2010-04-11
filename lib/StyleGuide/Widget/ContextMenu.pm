package StyleGuide::Widget::ContextMenu;

use Moose;

use Catalyst::Utils;

extends 'EMS::Widget';

has '+template' => ( default => 'context_menu.tt' );
has '+classes'  => ( default => sub { [ 'context-menu' ] } );

has 'menus' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 1
);

sub _process_item {
    my ( $self, $c, $i ) = @_;

    my $item = { %$i }; # shallow copy;

    # If we have an action, forward and merge the result into our current
    # item.
    if ( $item->{action} ) {
        $c->log->debug("Forwarding to update current menu: $item->{action}")
            if $c->debug;
        my $ret = $c->forward( $item->{action} );
        $item = Catalyst::Utils::merge_hashes( $item, $ret )
            if ref $ret eq 'HASH';
    }

    # Let the item itself determine if it should be expanded.  This can be done
    # in one of three ways:
    #  1 - The item has 'expand => 1' in the config.
    #  2 - The item has an 'action', which does it
    #  3 - There is a 'match' parameter (regex) that matches the current
    #      action.
    my $expand = 0;
    if ( $item->{expand} ) {
        $expand = 1;
    }
    elsif ( $item->{match} and $c->action->reverse =~ $item->{match} ) {
        $expand = 1;
    }
    # ignore this one
    elsif ( $item->{namespace} and $c->action->namespace eq $item->{namespace} ) {
        $expand = 1;
    }

    # Now, to href interpolation to determine if we have a link or not, and
    # then how to render that link
    if ( $item->{href} ) {
        if ( ref $item->{href} eq 'CODE' ) {
            $item->{href} = $item->{href}->($c, $item)
        }
        elsif ( not ref $item->{href} ) {
            if ( $item->{href} =~ /^(#|http)/ ) {
                # If we just want to anchor to a point on the page, this will
                # bypass the uri_for_action... just a quicker lookup I suppose
            } else {
                # Call out for this, with an href_params.  In the case of
                # captures or whatever, it is probably better to define
                # an 'action' to populate the href directly.
                $item->{href} = $c->uri_for_action(
                    $item->{href},
                    @{ $item->{href_params} || [] }
                );
            }
        }
    }

    # If we're going to expand, then iterate through the children and add
    # them in accordingly.
    if ( $expand and $item->{children} and ref $item->{children} eq 'ARRAY') {
        my @final;
        $item->{expand} = 1;
        foreach my $child ( @{ $item->{children} } ) {
            my $ret = $self->_process_item($c, $child);
            push @final, $ret if defined $ret;
        }
        $item->{children} = \@final;
    }
    return $item;
}

sub run {
    my ( $self, $args ) = @_;
    $args = {} unless $args and ref $args eq 'HASH';

    my $c = $self->app;

    my $menus = $self->menus;
    my @final = ();

    foreach my $item ( @{ $self->menus } ) {
        my $ret = $self->_process_item($c, $item);
        push @final, $ret if defined $ret;
    }
    $args->{action}     = $c->action;
    $args->{controller} = $c->controller;
    $args->{menu}       = \@final;

    return $args;
}


1;

