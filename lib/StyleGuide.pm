package StyleGuide;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader

    I18N

    +StyleGuide::Plugin::Static
/;

extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

# Configure the application.
#
# Note that settings in styleguide.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'StyleGuide',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

# Start the application
__PACKAGE__->setup();

sub static_uri {
    my ( $c, $asset, $query ) = @_;
    my $static_path = $c->stash->{page}->{static_root} ||
                        $c->view('TT')->config->{static_root} || '/static';
    my $uri;
    if ( $static_path =~ /^https?/ ) {
        $static_path =~ s/\/$//;
        $uri = URI->new( "$static_path/$asset" );
        if ( ref $query eq 'HASH' ) {
            $uri->query_form( $query );
        }
    } else {
        if ( $query and $query eq 'HASH' ) {
            $uri = $c->uri_for( $static_path, $asset, $query );
        } else {
            $uri = $c->uri_for( $static_path, $asset );
        }
    }
    return $uri;
}

=head1 NAME

StyleGuide - Catalyst based application

=head1 SYNOPSIS

    script/styleguide_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<StyleGuide::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Jay Shirley

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
