package StyleGuide::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

StyleGuide::Controller::Root - Root Controller for StyleGuide

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub setup : Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    my $design = $c->req->cookie('design');
    if ( not $design ) {
        $design = $c->view('StyleGuide')->default_style
    } else {
        $c->stash->{design} = $design->value;
    }
}

sub index : Chained('setup') PathPart('') Args(0) { 
    my ( $self, $c ) = @_;
}

sub guide : Chained('setup') Args {
    my ( $self, $c, $layout ) = @_;

    if ( $layout ) {
        if ( -f $c->path_to("root/guide", "$layout.tt") ) {
            $c->stash->{template} = "guide/$layout.tt";
        }
    }
}

sub switch : Chained('setup') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{designs} = $c->view('StyleGuide')->designs;
    $c->log->_dump($c->stash->{designs}) if $c->debug;
    if ( $c->req->method eq 'POST' and my $design = $c->req->params->{design} ) {
        if ( $c->view('StyleGuide')->get_design($design) ) {
            $c->res->cookies->{design} = { value => $design };
        }
        $c->res->redirect($c->req->uri);
    }
    $c->forward( $c->view('TT') );
}

=head2 default

Standard 404 error page

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    my $design = $c->req->cookie('design');
    if ( not $design ) {
        $design = $c->view('StyleGuide')->default_style
    } else {
        $design = $c->view('StyleGuide')->get_design($design->value);
    }
    if ( $design ) {
        my $path = $c->req->uri->path;
            $path =~ s/^\///;
        if ( -f "$design->{root}/$path.tt" ) {
            $c->stash->{template} = "$path.tt";
            return;
        }
    }
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Jay Shirley

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
