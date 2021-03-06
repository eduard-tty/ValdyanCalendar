package ValdyanCalendar;
use Dancer ':syntax';

use Data::Dumper;

our $VERSION = '0.1';

=head1 TODO

- all data files in dir
- default values for template arguments
- inprecise date

=cut

use YAML qw(LoadFile);

my $DATA_DIR = 'data';
my @DATA_FILES = glob("$DATA_DIR/*.yaml");

my @days    = qw( Dochein Nanei Anshein Naighei Mizrein Timoinei nafur );
my @seasons = qw( Timoine Anshen Mizran Naigha );

my $events = init($DATA_DIR);
my $event_tree = make_tree($events);

sub ok { defined($_[0]) and length($_[0]) };

sub init  {
    my ($dir) = @_;

    my @events = ();
    for my $filename ( @DATA_FILES ) {
        push @events, init_file($filename);
    };
    
    @events = sort by_date @events;
        
    return \@events;
};

sub init_file {
    my ($filename) = @_;
    my ($autotags, $events) = LoadFile($filename);
    my $autotag_re_text = '(' . join('|', @$autotags) . ')';
    my $autotag_re = qr/$autotag_re_text/i;
    for my $e ( @$events )  {
        $e->{'tags'} = '' unless ok($e->{'tags'});
        $e->{'tags'} = get_tags($e, $autotag_re);
        $e->{'text'} = '' unless ok($e->{'text'});
        my $name = substr( $e->{'text'}, 0, 30);
        $name =~ s/\s\S*$//;
        $e->{'name'} =  $name.'...';
        my ($year, $season, $week, $day) = split('/',$e->{'date'});
        $e->{'year'} = $year; 
        $e->{'season'} = $season; 
        $e->{'week'} = $week; 
        $e->{'day'} = $day; 
    };
    return @$events;
};

sub get_tags  {
    my ($e, $autotag_re) = @_;
    my $tags = [ split(/,\s*/, $e->{'tags'}) ];
    my $text = $e->{'name'} . ' ' . $e->{'text'};
    while ( $text =~ m/$autotag_re/g ) {
        push @$tags, $1 if $1;
    }

    return $tags; #uniq
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
    my ($events) = @_;
    
    my $event_tree = {};
    for my $e ( @$events ) {
        push @{
            $event_tree->{ $e->{'year'} }{ $e->{'season'} -1 }{ $e->{'week'} }{ $e->{'day'} }
        }, $e;
    }

    return $event_tree;
};

before_template sub {
    my ($tokens) = @_;
    my $year   = $tokens->{'year'};
    $tokens->{'leap_year'} = 0 == $year % 4 if defined $year;
    $tokens->{'events'} = $event_tree unless $tokens->{'events'};
    $tokens->{'days'} = \@days;
    $tokens->{'seasons'} = \@seasons;

    return;
};

get '/' => sub {
    return template 'index', {
        data_dir  => $DATA_DIR,
        data_files => [ map { s{$DATA_DIR/}{}; $_ } @DATA_FILES ],
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
