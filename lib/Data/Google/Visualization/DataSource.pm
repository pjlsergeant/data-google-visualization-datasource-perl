package Data::Google::Visualization::DataSource;

use strict;
use warnings;

use Moose;

=head1 NAME

Data::Google::Visualization::DataSource - Google Chart Datasources

=head1 DESCRIPTION

Helper class for implementing the Google Chart Tools Datasource Protocol (V0.6)

=head1 SYNOPSIS

 # Step 1: Create the container based on the HTTP request
 my $datasource = Data::Google::Visualization::DataSource->new({
    tqx => $q->param('tqx'),
    xda => ($q->header('X-DataSource-Auth') || undef)
 });

 # Step 2: Add data
 $datasource->datatable( Data::Google::Visualiation::DataSource object );

 # Step 3: Show the user...
 my ( $headers, $body ) = $datasource->serialize;

 printf("%s: %s\n", @$_) for $headers;
 print "\n" . $body . "\n";

=head1 OVERVIEW

The L<Google Visualization API|http://code.google.com/apis/visualization/documentation/reference.html#dataparam>
is a nifty bit of kit for generating pretty pictures from your data. By design
it has a fair amount of Google-cruft, such as non-standard JSON and stuffing
configuration options in to a single CGI query parameter. It's also got somewhat
confusing documentation, and some non-obvious rules for generating certain
message classes.

L<Data::Google::Visualization::DataTable> takes care of preparing data for the
API, but this module implements the I<Google Chart Tools Datasource Protocol>,
or I<Google Visualization API wire protocol>, or whatever it is they've decided
to call it this week.

B<This documentation is not laid out like standard Perl documentation, because
it needs extra explanation. You should read this whole document sequentially if
you wish to make use of it.>

=head1 THREE SIMPLE STEPS

There's quite a bit of logic around how to craft a response, how to throw
errors, how to throw warnings, etc. After some thought, I have discovered an
interface that hopefully won't make you want to throw yourself off a cliff.

=head2 Container Creation

At its essence, Google Datasources allow querying clients to specify a I<lot>
about what they want the response to look like. This information is specified
in the C<tqx> parameter
(L<Request Format|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#requestformat>)
and also somewhat implied by the existence of an C<X-DataSource-Auth> header.

Our first job is to specify what the response container will look like, and the
easiest way to do this is to pass C<new()> the contents of the C<tqx> parameter
and the C<X-DataSource-Auth> header.

C<new()> will set the following object attributes based on this, all based on
the I<Request Format> linked above:

=over 4

=item C<reqID> - allegedy required, and required to be an int. In fact, the
documentation reveals that if you leave it blank, it should default to 0.

=item C<version> - allows the calling client to specify the version of the API
it wishes to use. Please note this module currently ONLY CLAIMS TO support
C<0.06>. If any other version is passed, a C<warning> message will be added, but
we will try to continue anyway - see L<Adding Messages> below.

=item C<sig> - allows the client to specify an identifier for the last request
retrieved, so it's not redownloaded. If the C<sig> matches the data we were
about to send, we'll follow the documentation, and add an C<error> message, as
per L<Adding Messages> below.

=item C<out> - output format. This defaults to C<json>, although whether JSON or
JSONP is returned depends on if C<X-DataSource-Auth> has been included - see the
Google docs. Other formats are theoretically provided for, but this version of
the software doesn't support them, and will add an C<error> message if they're
specified.

=item C<responseHandler> - in the case of our outputting JSONP, we wrap our
payload in a function call to this method name. It defaults to
C<google.visualization.Query.setResponse>. An effort is made to strip out
unsafe characters.

=item C<outFileName> - certain output formats allow us to specify that the data
should be returned as a named file. This is simply ignored in this version.

=item C<datasource_auth> - this does NOT correspond to the normal request object
- instead it's used to capture the C<X-DataSource-Auth> header, whose presence
will cause us to output JSON instead of using the C<responseHandler>.

=back

=head2 Adding Messages

Having created our container, we then need to put data in it. There are two
types of data - messages, and the DataTable.

Messages are errors or warnings that need to be passed back to the client, but
they also have potential to change the rest of the data payload. The following
algorithm is used:

 1. Have any error messages been added? If so, discard all but the first, set
    the response status to 'error', and discard the DataTable and all warning
    messages. We discard all the other messages (error and warning) to prevent
    malicious data discovery.

 2. An integrity check is run on the attributes that have been set. We check the
    attributes listed above, and generate any needed messages from those. If we
    generate any error messages, step 1 is rerun.

 2. Have any warning messages been added? If so, set the response status to
    'warning'. Include all warning messages and the DataTable in the response.

 3. If there are no warning or error messages, set the response status to 'ok',
    and include the DataTable in the response.

Messages are added using the C<add_message> method:

 $datasource->add_message({
    type    => 'error',         # Required. Can also be 'warning'
    reason  => 'access_denied', # Required. See Google Docs for allowed options
    message => 'Unauthorized User', # Optional
    detailed_message => 'Please login to use the service' # Optional
 });

The datatable is added via the C<datatable> method:

 $datasource->datatable( $datatable_object );

and must be a L<Data::Google::Visualization::DataTable> object. If you know
you've already added an C<error> message, you don't need to set this - it won't
be checked.

=head2 Generating Output

ADD STUFF HERE ABOUT THE DIFFERENT HEADERS WE MIGHT ADD.












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

A L<Data::Google::Visualization::DataTable> object. You don't actually need to
specify this, but if you don't, it won't get sent to the user. The only use for
not specifying this is if you're intending to add an error status.

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

If you specify this AND one of the parameters below, then the one you've
specified by hand will 'win'.

=head2 reqID

Required, and required to be an int. As specified in
L<Request Format|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#requestformat>).
The dirty secret here is that actually, according to all the examples on the
linked page, it isn't really required at all. So it defaults to 0 if you don't
specify it.

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

# Inputs
has 'datatable' => ( is => 'ro', isa => 'Data::Google::Visualization::DataTable' );
has 'datasource_auth' => ( is => 'ro', isa => 'Str', required => 0 );
has 'reqID' => ( is => 'ro', isa => 'Int', default => 0 );
has 'version' => ( is => 'ro', isa => 'Str', required => 0 );
has 'sig' => ( is => 'ro', isa => 'Str', required => 0 );
has 'out' => ( is => 'ro', isa => 'Str', default => 'json' );
has 'responseHandler' => ( is => 'ro', isa => 'Str', default => 'google.visualization.Query.setResponse' );
has 'outFileName' => ( is => 'ro', isa => 'Str', required => 0 );

=head1 OUTPUTS

=head2 body_data

This is the Perl data structure which will be serialized when you call C<body>.
It corresponds to the response format specified in:
L<Response Format (JSON)|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#jsondatatable>.
You can actually mess with it if you like before calling C<body()>, but no
error checking of this is done.

=cut


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $options = shift;
    my $tqx = delete $options->{'tqx'} || '';
    for my $option ( split(/;/, $tqx ) ) {
        my ( $key, $value ) = split(/;/, $option);
        $options->{ $key } = $value;
    }

    $class->$orig( $options );
};

sub BUILD {
    use Data::Printer;

}

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