package Dancer::Plugin::Validation;
BEGIN {
  $Dancer::Plugin::Validation::VERSION = '0.02';
}
# ABSTRACT: Simple data validation for Dancer applications using Oogly!

use Dancer ':syntax';
use Dancer::Plugin;
use Oogly  qw(Oogly);

my $settings = plugin_setting;

register validate => sub {
    my $fields = shift || [];
    
    # nasty little hack for turning defined yaml validation directives into coderefs
    foreach my $field (keys %{$settings->{fields}}) {
        if (defined $settings->{fields}->{$field}->{validation}) {
            $settings->{fields}->{$field}->{validation} = 
                eval $settings->{fields}->{$field}->{validation};
        }
    }
    
    my $i = Oogly( mixins => $settings->{mixins}, fields => $settings->{fields} );
    my $p = request->params;
    my $o = $i->new($p);
    
    if ($o->validate(@{$fields})) {
        var( validation => $o );
        true;
    }
    else {
        var( validation => $o );
        false;
    }
};


register_plugin;

1;

__END__
=pod

=head1 NAME

Dancer::Plugin::Validation - Simple data validation for Dancer applications using Oogly!

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Validation;
    
    # Call the validation keyword and pass it an arrayref of params to validate
    post '/login' => sub {
        
        if ( validate [qw/login password/] ) {
            redirect '...';
        }
        else {
            # errors are stored as an arrayref at vars->{validation}->errors
            # see cpan module Oogly for more insight
            template '...' => { errors => vars->{validation}->errors };
        }
    }

=head1 DESCRIPTION

Provides an easy way of validating data via the Oogly data validation framework. This
plugin allows you to define data validation rules and filters in your Dancer YAML
configuration file, then validate parameters against those specifications easily.

=head1 CONFIGURATION

Connection details will be taken from your Dancer application config file, and
should be specified as, for example: 

    plugins:
      Validation:
        mixins:
          default:
            required: 1
            min_length: 1
            max_length: 255
            filters:
              - trim
              - strip
              - lowercase
        fields:
          login:
            mixin: default
            label: 'user login'
            validation: sub { $_[0]->error($_[1], "user login is required bitch") if $value !~ /[a-zA-Z]/ && $value !~ /[0-9]/ }
          password:
            mixin_field: login
            label: 'user password'

Important Note! When using the validation directive of a field, its must be an
anonymous subroutine and due to the YAML specification, it must all appear on a
single line. This is not optimal for complex routines but its all we got right now :(

=head1 AUTHOR

  Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

