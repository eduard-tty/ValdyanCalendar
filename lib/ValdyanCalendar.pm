package ValdyanCalendar;
use Dancer ':syntax';

our $VERSION = '0.1';

=head1 TODO

autotags
more then one event per day

=cut

use YAML qw(LoadFile);

my $FILENAME = 'data/data.yaml';
my $AUTOTAG_MIN = 2;

my @days    = qw( Dochein Nanei Anshein Naighei Mizrein Timoinei nafur );
my @seasons = qw( Timoine Anshen Mizran Naigha );

my ($event_tree, @autotags) = mold_data($FILENAME);

use Data::Dumper;
warn Dumper(\@autotags);


sub mold_data  {
    my ($path) = @_;

    my $events = LoadFile($path);
    my $stash = {};
    my %autotags = ();
    while ( my($date, $event) = each(%$events) )  {
        my ($year, $season, $week, $day ) = split('/', $date);
        next unless $day;
        $stash->{$year}{$season-1}{$week}{$day} = $event;
        $autotags{$_}++ for split(/\W+/, $event);
    }

    return ( $stash, grep { $autotags{$_} >= $AUTOTAG_MIN } keys(%autotags) );
};

before_template sub {
    my ($tokens) = @_;
    my $year   = $tokens->{'year'};
    $tokens->{'leap_year'} = 0 == $year % 4 if defined $year;
    $tokens->{'events'} = $event_tree;
    $tokens->{'days'} = \@days;
    $tokens->{'seasons'} = \@seasons;

    return;
};

get '/' => sub {
    return template 'index', {
        filename  => $FILENAME,
    };
};

get '/list' => sub {
    return template 'list';
};


get qr{^/(\d+)$} => sub {
    my ($year) = splat;
    my @jumps = grep { $_ >= 0 } ( 0, $year-1000, $year-100, $year-10, $year-1, $year+1, $year+10, $year+100, $year+1000);
    return template 'year', {
        year => $year,
        jumps => \@jumps,
    };
};

get qr{^/(\d+)/([1-4])$} => sub {
    my ($year, $season) = splat;
    return template 'season', {
        year => $year,
        season => $season-1,
    };
};

get qr{^/(\d+)/([1-4])/([0-9]|1[1-3])$} => sub {
    my ($year, $season, $week) = splat;
    return template 'week', {
        year => $year,
        season => $season-1,
        week => $week,
    };
};

get qr{^/(\d+)/([1-4])/([0-9]|1[1-3])/([1-7])$} => sub {
    my ($year, $season, $week, $day) = splat;
    return template 'day', {
        year => $year,
        season => $season-1,
        week => $week,
        day => $day,
    };
};


true;
