package StyleGuide::Plugin::Static;

use Moose::Role;

with 'Catalyst::Plugin::Static::Simple' => { -excludes => [ '_locate_static_file' ] };

# Search through all included directories for the static file
# Based on Template Toolkit INCLUDE_PATH code
sub _locate_static_file {
    my ( $c, $path, $in_static_dir ) = @_;

    my $cookie = $c->req->cookie('design');
    my $design = defined $cookie ? $cookie->value : undef;

    if ( $design ) {
        $design = $c->view('StyleGuide')->get_design($design);
    } else {
        ( $design ) = keys %{ $c->view('StyleGuide')->designs };
        $design = $c->view('StyleGuide')->get_design($design);
        $c->log->debug("Picking random design ($design->{static}), yeehaw!") if $c->debug;
    }

    my $static_path = $design->{static};
    $static_path =~ s/\/static$//g;

    $path = File::Spec->catdir(
        File::Spec->no_upwards( File::Spec->splitdir( $path ) )
    );

    my $config = $c->config->{static};
    my @ipaths = ( $static_path, @{ $config->{include_path} } );
    my $dpaths;
    my $count = 64; # maximum number of directories to search

    DIR_CHECK:
    while ( @ipaths && --$count) {
        my $dir = shift @ipaths || next DIR_CHECK;

        if ( ref $dir eq 'CODE' ) {
            eval { $dpaths = &$dir( $c ) };
            if ($@) {
                $c->log->error( 'Static::Simple: include_path error: ' . $@ );
            } else {
                unshift @ipaths, @$dpaths;
                next DIR_CHECK;
            }
        } else {
$c->log->debug("Checking path: $dir/$path");
            $dir =~ s/(\/|\\)$//xms;
            if ( -d $dir && -f $dir . '/' . $path ) {

                # Don't ignore any files in static dirs defined with 'dirs'
                unless ( $in_static_dir ) {
                    # do we need to ignore the file?
                    for my $ignore ( @{ $config->{ignore_dirs} } ) {
                        $ignore =~ s{(/|\\)$}{};
                        if ( $path =~ /^$ignore(\/|\\)/ ) {
                            $c->_debug_msg( "Ignoring directory `$ignore`" )
                                if $config->{debug};
                            next DIR_CHECK;
                        }
                    }

                    # do we need to ignore based on extension?
                    for my $ignore_ext ( @{ $config->{ignore_extensions} } ) {
                        if ( $path =~ /.*\.${ignore_ext}$/ixms ) {
                            $c->_debug_msg( "Ignoring extension `$ignore_ext`" )
                                if $config->{debug};
                            next DIR_CHECK;
                        }
                    }
                }

                $c->_debug_msg( 'Serving ' . $dir . '/' . $path )
                    if $config->{debug};
                return $c->_static_file( $dir . '/' . $path );
            }
        }
    }

    return;
}

no Moose;
1;
