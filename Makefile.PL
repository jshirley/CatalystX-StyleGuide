#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'StyleGuide';
all_from 'lib/StyleGuide.pm';

requires 'Catalyst::Runtime' => '5.80021';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';

requires 'Catalyst::View::TT';

requires 'Moose';
requires 'namespace::autoclean';
requires 'YAML::Syck';

requires 'Template::Plugin::Digest::MD5';

test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
