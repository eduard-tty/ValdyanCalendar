package ValdyanCalendar;
use Dancer ':syntax';

our $VERSION = '0.1';

=head1 TODO

autotags
more then one event per day

=cut

use YAML qw(LoadFile);

my $FILENAME = 'data/timeline.yaml';

my @days    = qw( Dochein Nanei Anshein Naighei Mizrein Timoinei nafur );
my @seasons = qw( Timoine Anshen Mizran Naigha );

my ($autotags, $events) = init($FILENAME);

sub ok { defined($_[0]) and length($_[0]) };

sub init {
    my ($filename) = @_;
    my ($autotags, $events) = LoadFile($filename);
    for my $e ( @$events )  {
        $e->{'tags'} = '' unless ok($e->{'tags'});
        $e->{'tags'} = [ split(/,\s*/, $e->{'tags'}) ];
        $e->{'text'} = '' unless ok($e->{'text'});
        $e->{'name'} = substr( $e->{'text'}, 0, 20) . '...';
        my ($year, $season, $week, $day) = split('/',$e->{'date'});
        $e->{'year'} = $year; 
        $e->{'season'} = $season; 
        $e->{'week'} = $week; 
        $e->{'day'} = $day; 
    };
    my @events = sort by_date @$events;
    return ( $autotags, \@events );
};

sub by_date {
    return
        $a->{'year'}   <=> $b->{'year'}
        ||
        $a->{'season'} <=> $b->{'season'}
        ||
        $a->{'week'}   <=> $b->{'week'}
        ||
        $a->{'day'}    <=> $b->{'day'};
};

sub make_tree  {
    my ($date, $events) = @_;
    
    my $one_year_later = $date;
    $one_year_later->{'year'} += 1;
    my $event_tree = {};
    for my $e ( $events ) {      
        next unless after($e, $date);
        last if after($e, $one_year_later); 
        $event_tree->{ $e->{'year'} }{ $e->{'season'} -1 }{ $e->{'week'} }{ $e->{'day'} } = $e;
    }

    return $event_tree;
};

before_template sub {
    my ($tokens) = @_;
    my $year   = $tokens->{'year'};
    $tokens->{'leap_year'} = 0 == $year % 4 if defined $year;
    $tokens->{'events'} = make_tree($tokens, $events) unless $tokens->{'events'};
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
    return template 'list', {
        events => $events,
    };
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
