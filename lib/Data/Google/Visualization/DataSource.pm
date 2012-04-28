package Data::Google::Visualization::DataSource;

use strict;
use warnings;

use Moose;

=head1 NAME

Data::Google::Visualization::DataSource - Google Chart Datasources

=head1 DESCRIPTION

Helper class for implementing the Google Chart Tools Datasource Protocol (V0.6)

=head1 SYNOPSIS

 # Create a datatable some place else
 # For that, see Data::Google::Visualization::DataTable instead
 my $datatable = something();

 # Then create your datasource
 my $datasource = Data::Google::Visualization::DataSource->new({

	datatable       => $datatable,
	datasource_auth => $q->param('X-DataSource-Auth'),

	# While you can specify the incoming attributes by hand, you should just
	# let this module do it by passing it whatever the user sent in as tqx
	tqx             => $q->param('tqx')

 });

 # You're ready to go!

 # HTTP Status will be 200 or 400. This example only prints something for 400
 # as any sensible webserver defaults to 200 if nothing's included
 print "Status: 400 Bad Request\n" if $datasource->http_status == 400;

 print "Content-type: text/javascript\n";

 # Print whatever it was the user wanted anyway...
 print "\n" . $datasource->body;

=head1 OVERVIEW

The L<Google Visualization API|http://code.google.com/apis/visualization/documentation/reference.html#dataparam>
is a nifty bit of kit for generating pretty pictures from your data. By design
it has a fair amount of Google-cruft, such as non-standard JSON and stuffing
configuration options in to a single CGI query parameter.

While you'll want to use L<Data::Google::Visualization::DataTable> for creating
the datatables that power the API, if you want to make your data available as a
generic data source for charts, you need to implement the I<Google Chart Tools
Datasource Protocol>, or I<Google Visualization API wire protocol>, or whatever
it is they've decided to call it today!

This attempts to make that whole process as painless as possible.

This module implement a single one-shot class, that does all of its magic at
instantiation time based on the attributes you provide. It then makes available
for you to return with whatever you're using to serve HTTP requests. Good luck,
commander.

=head1 INPUTS

=head2 datatable

A L<Data::Google::Visualization::DataTable> object.

=head2 datasource_auth

Defaults to 0. According to the documentation, when this has been set then
requests for JSON should come back as actual JSON, but when it hasn't been, they
should come back as JSONP using the C<responseHandler> attribute below. Even
having read the docs a few times, this seems a little strange to me, so try
reading it yourself, and see what you think.

=head2 tqx

If you pass in whatever the user sent you as the C<tqx> string (see:
L<Request Format|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#requestformat>)
then we'll unpack the rest of the parameters. Otherwise, you'll need to pass
everything else below in by hand, and that'd be boring...

=head2 reqID

Required, and required to be an int. As specified in
L<Request Format|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#requestformat>)

=head2 version

As of this version, we save this, but DO NOT ACT ON IT. This module does not
guarantee to support anything other than version 0.6. Patches welcome.

=head2 sig

As specified in
L<Request Format|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#requestformat>)

=head2 out

As specified in
L<Request Format|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#requestformat>).
This module supports C<json> only.

=head2 responseHandler

As specified in
L<Request Format|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#requestformat>)

=head2 outFileName

Ignored for now, as we only support JSON output types currently.

=cut

has 'datatable' => ( is => 'ro', isa => 'Data::Google::Visualization::DataTable', required => 1 );
has 'datasource_auth' => ( is => 'ro', isa => 'Str', required => 0 );
has 'reqID' => ( is => 'ro', isa => 'Int', required => 1 );
has 'version' => ( is => 'ro', isa => 'Str', required => 0 );
has 'sig' => ( is => 'ro', isa => 'Str', required => 0 );
has 'out' => ( is => 'ro', isa => 'Str', default => 'json' );
has 'responseHandler' => ( is => 'ro', isa => 'Str', default => 'google.visualization.Query.setResponse' );
has 'outFileName' => ( is => 'ro', isa => 'Str', required => 0 );

# TODO!!!
around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;

      if ( @_ == 1 && !ref $_[0] ) {
          return $class->$orig( ssn => $_[0] );
      }
      else {
          return $class->$orig(@_);
      }
  };

=head1 OUTPUTS

=head2 http_status

Either C<200> or C<400>, depending on if the caller's request was reasonable.

=head2 body

The JSON response body, as per
L<Response Format (JSON)|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#jsondatatable>.

=head1 BUGS, TODO

It'd be nice to support the other data types, but currently
L<Data::Google::Visualization::DataTable> serializes its data a little too early
which makes this impracticle. I tend to do hassle-related development, so if you
are in desparate need of this feature, I recommend emailing me.

=head1 SUPPORT

If you find a bug, please use
L<this modules page on the CPAN bug tracker|https://rt.cpan.org/Ticket/Create.html?Queue=Data-Google-Visualization-DataSource>
to raise it, or I might never see.

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com> on behalf of
L<Investor Dynamics|http://www.investor-dynamics.com/> - I<Letting you know what
your market is thinking>.

=head1 SEE ALSO

L<Data::Google::Visualization::DataTable> - for preparing your data

L<Python library that does the same thing|http://code.google.com/p/google-visualization-python/>

L<Google Visualization API|http://code.google.com/apis/visualization/documentation/reference.html#dataparam>.

L<Github Page for this code|https://github.com/sheriff/data-google-visualization-datatable-perl>

=head1 COPYRIGHT

Copyright 2012 Investor Dynamics Ltd, some rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;