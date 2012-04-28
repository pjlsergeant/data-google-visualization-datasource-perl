#!perl

use strict;
use warnings;
use Test::More;

use Data::Google::Visualization::DataTable;
use Data::Google::Visualization::DataSource;

# Create a simple datatable for testing
my $datatable = Data::Google::Visualization::DataTable->new();
$datatable->add_columns(
    { id => 'person', label => "Person", type => 'string', },
    { id => 'dob',    label => "Born",   type => 'date',   },
);
$datatable->add_rows(
	{ person => "Steve Jobs", dob => [1995, 2 -1, 24]},
	{ person => "Lou Reed",   dob => [1942, 3 -1,  2]},
);

# Check various inputs do something sane
for my $test (
	{
		name => "All the defaults",
		input => {
			datatable => $datatable,
		},
		expected => {
			reqID => 0,
		}
	}
) {
	my $datasource = Data::Google::Visualization::DataSource->new(
		$test->{'input'}
	);
}
