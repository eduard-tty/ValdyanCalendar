package ValdyanCalendar;
use Dancer ':syntax';

use YAML qw(LoadFile);

our $VERSION = '0.1';

my @days    = qw( Dochein Nanei Anshein Naighei Mizrein Timoinei nafur );
my @seasons = qw( Timoine Anshen Mizran Naigha );

my $events = mold_data('data/data.yaml');

sub mold_data  {
    my ($path) = @_;

    my $events = LoadFile($path);
    my $stash = {};
    while ( my($date, $event) = each(%$events) )  {
        my ($year, $season, $week, $day ) = split('/', $date);
        next unless $day;
        $stash->{$year}{$season-1}{$week}{$day} = $event;
    }

    return $stash;
};

before_template sub {
    my ($tokens) = @_;
    my $year   = $tokens->{'year'};
    $tokens->{'leap_year'} = 0 == $year % 4 if defined $year;
    $tokens->{'data'} = $events;
    $tokens->{'days'} = \@days;
    $tokens->{'seasons'} = \@seasons;

    return;
};

get '/' => sub { template 'index'; };

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

get qr{^/(\d+)/([1-4])/([1-9]|1[1-3])$} => sub {
    my ($year, $season, $week) = splat;
    return template 'week', {
        year => $year,
        season => $season-1,
        week => $week,
    };
};



true;
