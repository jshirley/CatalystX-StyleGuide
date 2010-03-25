package StyleGuide::View::StyleGuide;

use Moose;
use Template;

use namespace::autoclean;

extends 'Catalyst::View';

__PACKAGE__->config({
    PRE_PROCESS        => 'site/shared/base.tt',
    WRAPPER            => 'site/wrapper.tt',
    TEMPLATE_EXTENSION => '.tt',
    TIMER              => 0,
});

has 'default_style' => (
    is  => 'rw',
    isa => 'Str'
);

has 'renderers' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    lazy    => 1,
    default => sub { { } },
    handles => {
        'get_renderer' => 'get',
        'set_renderer' => 'set',
    }
);

has 'shared_root' => (
    is => 'rw',
    isa => 'Str'
);

has 'designs' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    lazy    => 1,
    default => sub { { } },
    handles => {
        'get_design' => 'get',
    }
);

sub process {
    my ( $self, $c ) = @_;

    my $design = $c->stash->{design};
    if ( not $design ) { 
        my $cookie = $c->req->cookie('design');
        $design = $cookie->value if defined $cookie;
        $c->log->debug("Design from cookie ($cookie) => $design");
    }

    unless ( $design ) {
        ( $design ) = keys %{ $self->designs };
    }
    my $renderer = $self->get_renderer($design);
    unless ( defined $renderer ) {
        $c->log->debug("Building renderer for design: $design");
        $renderer = $self->_build_renderer( $c, $design );
        $self->set_renderer( $design, $renderer );
    }

    my $template = $c->stash->{template}
      ||  $c->action . $self->{TEMPLATE_EXTENSION};

    unless (defined $template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my $output;
    #try {
        $output = $self->render($renderer, $c, $template);
    #} catch {
if ( 0 ) {
        my $error = qq/Couldn't render template "$template": / . $renderer->error;
        $c->log->error($error);
        $c->error($error);
        return 0;
    };

    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }

    $c->response->body($output);

    return 1;
}

sub render {
    my ($self, $renderer, $c, $template, $args) = @_;

    $c->log->debug(qq/Rendering template "$template"/) if $c && $c->debug;

    my $output;
    my $vars = {
        (ref $args eq 'HASH' ? %$args : %{ $c->stash() }),
        $self->template_vars($c)
    };

    local $self->{include_path} =
        [ @{ $vars->{additional_template_paths} }, @{ $self->{include_path} } ]
        if ref $vars->{additional_template_paths};

    unless ( $renderer->process( $template, $vars, \$output ) ) {
        die $renderer->error;
    }
    return $output;
}

sub template_vars {
    my ( $self, $c ) = @_;

    return  () unless $c;
    my $cvar = $self->config->{CATALYST_VAR};

    defined $cvar
      ? ( $cvar => $c )
      : (
        c    => $c,
        base => $c->req->base,
        name => $c->config->{name}
      )
}

sub _build_renderer {
    my ( $self, $c, $design ) = @_;

    my $config = {
        EVAL_PERL          => 0,
        TEMPLATE_EXTENSION => '',
        %{ $self->config }, 
        INCLUDE_PATH => [
            $self->get_design($design)->{root},
            $self->shared_root,
        ]
    };

$c->log->_dump($config);

    return Template->new($config) || do {
        my $error = Template->error();
        $c->log->error($error);
        $c->error($error);
        return undef;
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;
