## Bioperl Test Harness Script for Modules
##
# CVS Version
# $Id: mapper.t,v 1.14 2011/01/28 11:35:59 ak4 Exp $


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

#-----------------------------------------------------------------------
## perl test harness expects the following output syntax only!
## 1..3
## ok 1  [not ok 1 (if test fails)]
## 2..3
## ok 2  [not ok 2 (if test fails)]
## 3..3
## ok 3  [not ok 3 (if test fails)]
##
## etc. etc. etc. (continue on for each tested function in the .t file)
#-----------------------------------------------------------------------


# This test script heavily edited by ihh@fruitfly.org

## We start with some black magic to print on failure.
BEGIN { $| = 1;
	use Test;
	plan tests => 14;   # 5 tests total
	use vars qw($loaded); }
END { print "not ok 1\n" unless $loaded; }


$loaded = 1;
# $n_test = 0;
ok( 1 );

use Bio::EnsEMBL::Mapper;


$mapper = Bio::EnsEMBL::Mapper->new( "rawcontig", "virtualcontig" );
load_sgp_dump( $mapper, undef );

# loading done successfully
ok( 1 );

# transform a segment entirely within the first rawcontig
test_transform ($mapper,
		[627012, 2, 5, -1, "rawcontig"],
		["chr1", 2, 5, -1]);

# now a split coord
test_transform ($mapper,
		["chr1", 383700, 444000, +1, "virtualcontig"],
		[314696, 31917, 31937, -1],
		[341, 126, 59773, -1],
		[315843, 5332, 5963, +1]);

# now a simple gap
test_transform ($mapper,
		["chr1", 273701, 273781, +1, "virtualcontig"],
		[627011, 7447, 7507, +1],
		["chr1", 273762, 273781, 0]);



#
# check if the mapper can do merging
#

$mapper = Bio::EnsEMBL::Mapper->new( "asm1", "asm2" );

$mapper->add_map_coordinates( "1", 1, 10, 1, "1", 101, 110 );
$mapper->add_map_coordinates( "1", 21, 30, 1, "1", 121, 130 );
$mapper->add_map_coordinates( "1", 11, 20, 1, "1", 111, 120 );

test_transform( $mapper, 
		[ "1", 5, 25, 1, "asm1" ],
		[ "1", 105, 125, 1 ] );



#
# Slightly differnt merge case
#
$mapper = Bio::EnsEMBL::Mapper->new( "asm1", "asm2" );

$mapper->add_map_coordinates( "1", 1, 10, 1, "1", 101, 110 );
$mapper->add_map_coordinates( "1", 21, 30, 1, "1", 121, 130 );
$mapper->add_map_coordinates( "1", 12, 20, 1, "1", 112, 120 );

test_transform( $mapper, 
		[ "1", 5, 25, 1, "asm1" ],
		[ "1", 105, 110, 1 ],
		[ "1", 11, 11, 0 ],
		[ "1", 112, 125, 1 ] );



#
# dont merge on wrong orientation
#

$mapper = Bio::EnsEMBL::Mapper->new( "asm1", "asm2" );

$mapper->add_map_coordinates( "1", 1, 10, 1, "1", 101, 110 );
$mapper->add_map_coordinates( "1", 21, 30, 1, "1", 121, 130 );
$mapper->add_map_coordinates( "1", 11, 20, -1, "1", 111, 120 );

test_transform( $mapper, 
		[ "1", 5, 25, 1, "asm1" ],
		[ "1", 105, 110, 1 ],
		[ "1", 111, 120, -1 ],
		[ "1", 121, 125, 1 ] );

#
# can reverse strands merge?
#

$mapper = Bio::EnsEMBL::Mapper->new( "asm1", "asm2" );

$mapper->add_map_coordinates( "1", 1, 10, -1, "1", 121, 130 );
$mapper->add_map_coordinates( "1", 21, 30, -1, "1", 101, 110 );
$mapper->add_map_coordinates( "1", 11, 20, -1, "1", 111, 120 );

test_transform( $mapper, 
		[ "1", 5, 25, 1, "asm1" ],
		[ "1", 106, 126, -1 ] );


#
# normal merge, not three
#

$mapper = Bio::EnsEMBL::Mapper->new( "asm1", "asm2" );

$mapper->add_map_coordinates( "1", 1, 10, 1, "1", 101, 110 );
$mapper->add_map_coordinates( "1", 11, 20, 1, "1", 111, 120 );
$mapper->add_map_coordinates( "1", 22, 30, 1, "1", 132, 140 );
$mapper->add_map_coordinates( "1", 51, 70, 1, "1", 161, 180 );
$mapper->add_map_coordinates( "1", 31, 35, 1, "1", 141, 145 );


test_transform( $mapper, 
		[ "1", 5, 45, 1, "asm1" ],
		[ "1", 105, 120, 1 ],
		[ "1", 21, 21, 0 ],
		[ "1", 132, 145, 1 ],
		[ "1", 36, 45, 0 ]
	      );


#
# test tranformation of 'insertion' coordinates where end = start -1
#

$mapper = Bio::EnsEMBL::Mapper->new('asm1', 'asm2');

$mapper->add_map_coordinates('1', 1, 10, 1, 'X', 101, 110);
$mapper->add_map_coordinates('1', 11, 20, -1, 'Y', 1, 10);

# boundary insert, expect 2 edge inserts back
test_transform($mapper, ['1', 11, 10, 1, 'asm1'],
               ['X', 111, 110, 1],
               ['Y', 11,  10, -1]);

# edge insert, negative strand, expect edge insert negative strand
test_transform($mapper, ['1', 1, 0, -1, 'asm1'],
               ['X', 101, 100, -1]);

# normal case, expect single insert in middle
test_transform($mapper, ['1', 2, 1, 1, 'asm1'],
               ['X', 102, 101, 1]);

# expect a gap
test_transform($mapper, ['1', 100, 200, 1, 'asm1'],
               ['1', 100, 200, 0]);



# the following subroutine tests that a given source co-ordinate range
# transforms into a given set of destination co-ordinates
#
# args: $src  = [$srcid, $srcstart, $srcend, $srcstrand, $srctype]
#       @dest = ([$id1, $start1, $end1, $strand1],
#                [$id2, $start2, $end2, $strand2] ... )
#
# for @dest array, $strand=0 indicates gap.
# for @dest array, $id=$srcid for gaps.


sub test_transform {
    my ($mapper, $src, @dest) = @_;
    if (@$src != 5) { warn "Bad source coords: (@$src)\n"; printnotok(); return }
    my ($srcid, $srcstart, $srcend, $srcstrand, $srctype) = @$src;
    my @coord = $mapper->map_coordinates ($srcid, $srcstart, $srcend, $srcstrand, $srctype);
    @coord = map ([isgap($_) ? $srcid : $_->id,  # Gap object should do this, but currently doesn't.
		   $_->start,
		   $_->end,
		   isgap($_) ? 0 : $_->strand],  # strand zero indicates a gap, within this subroutine
		  @coord);
    if (@coord != @dest) {
	warn "Source:\n(", join(",",@$src), ")\n";
	warn "Dest:\n", map ("(".join(",",@$_).")\n", @coord);
	warn "Expected:\n", map ("(".join(",",@$_).")\n", @dest);
	warn "Wrong number of segments\n";
	ok( 0 );
	return;
    }
    for (my $i = 0; $i < @coord; ++$i) {
	for (my $n = 0; $n < 4; ++$n) {
	    if ($n == 0
		? ($coord[$i]->[$n] ne $dest[$i]->[$n])
		: ($coord[$i]->[$n] != $dest[$i]->[$n])) {
		warn "Source:\n(", join(",",@$src), ")\n";
		warn "Dest:\n", map ("(".join(",",@$_).")\n", @coord);
		warn "Expected:\n", map ("(".join(",",@$_).")\n", @dest);
		warn "Error in segment ", $i+1, " field ", $n+1, "\n";
		ok( 0 );
		return;
	    }
	}
    }
    ok( 1 );
    return;
}



sub load_sgp_dump {
 	my ($map, $reverse) = @_;

#chr_name	raw_id	chr_start	chr_end	raw_start	raw_end	raw_ori
	my @sgp_dump = split ( /\n/, qq {
chr1	627012	1	31276	1	31276	1
chr1	627010	31377	42949	72250	83822	-1
chr1	2768	42950	180950	251	138251	1
chr1	10423	180951	266154	1	85204	-1
chr1	627011	266255	273761	1	7507	1
chr1	314698	273862	283122	1	9261	-1
chr1	627009	283223	331394	251	48422	-1
chr1	314695	331395	352162	1	20768	-1
chr1	314697	352263	359444	1	7182	-1
chr1	314696	359545	383720	31917	56092	-1
chr1	341	383721	443368	126	59773	-1
chr1	315843	443369	444727	5332	6690	1
chr1	315844	444828	453463	1	8636	-1
chr1	315834	453564	456692	1	3129	1
chr1	315831	456793	458919	1	2127	1
chr1	315827	459020	468965	251	10196	-1
chr1	544782	468966	469955	1	990	-1
chr1	315837	470056	473446	186	3576	-1
chr1	544807	473447	474456	1	1010	-1
chr1	315832	474557	477289	1	2733	1
chr1	544806	477390	477601	1086	1297	-1
chr1	315840	477602	482655	21	5074	1
chr1	544802	482656	483460	1	805	-1
chr1	544811	483561	484162	6599	7200	-1
chr1	315829	484163	498439	15	14291	-1
chr1	544813	498440	500980	1	2541	-1
chr1	544773	501081	502190	1217	2326	-1
chr1	315828	502191	513296	72	11177	1
chr1	544815	513297	517276	2179	6158	1
chr1	315836	517277	517662	2958	3343	1
chr1	544805	517663	520643	299	3279	1
chr1	315835	520744	521682	2462	3400	-1
chr1	544784	521683	526369	54	4740	1
chr1	544796	526470	527698	1	1229	1
chr1	315833	527799	528303	2530	3034	-1
chr1	544803	528304	531476	1	3173	-1
chr1	544821	531577	532691	1	1115	1
chr1	544810	532792	533843	1	1052	1
chr1	544800	533944	535249	1	1306	1
chr1	544786	535350	536652	1	1303	1
chr1	544814	536753	538358	1	1606	1
chr1	544812	538459	540004	1	1546	1
chr1	544818	540105	541505	1	1401	1
chr1	544816	541606	542693	1	1088	1
chr1	544778	542794	544023	1	1230	1
chr1	544779	544124	545709	1	1586	1
chr1	544804	545810	547660	1	1851	1
chr1	544774	547761	550105	1	2345	1
chr1	544817	550206	552105	1	1900	1
chr1	544781	552206	553640	1	1435	1
chr1	315830	553741	555769	1	2029	-1
chr1	544819	555870	558904	1	3035	-1
chr1	544777	559005	560670	1	1666	1
chr1	544795	560771	563092	1	2322	1
chr1	544809	563193	565523	1	2331	1
chr1	544808	565624	568113	1	2490	1
chr1	544798	568214	570324	1	2111	1
chr1	544783	570425	574640	1	4216	1
chr1	544824	574741	578101	1	3361	1
chr1	544775	578202	580180	1	1979	-1
chr1	544825	580281	581858	1	1578	-1
chr1	544772	581959	585312	1	3354	1
chr1	544793	585413	588740	1	3328	1
chr1	544785	588841	591656	1	2816	-1
chr1	544791	591757	594687	1	2931	1
chr1	544820	594788	597671	1	2884	1
chr1	544790	597772	601587	1	3816	1
chr1	544794	601688	603324	1	1637	-1
chr1	544823	603425	607433	1	4009	1
chr1	544789	607534	610856	1	3323	1
chr1	544799	610957	614618	1	3662	1
chr1	544776	614719	618674	1	3956	-1
chr1	544797	618775	624522	1	5748	-1
chr1	544787	624623	629720	1	5098	-1
chr1	544792	629821	637065	1	7245	1
chr1	622020	837066	851064	1	13999	-1
chr1	622021	851165	854101	1	2937	-1
chr1	622016	854202	856489	1	2288	-1
chr1	625275	856590	888524	420	32354	-1
chr1	622015	888525	891483	1	2959	-1
chr1	622024	891584	896208	8871	13495	-1
chr1	625537	896209	952170	1	55962	-1
chr1	625538	952271	1051812	251	99792	-1
chr1	625277	1051813	1055193	1	3381	-1
chr1	625266	1055294	1062471	1	7178	-1
chr1	598266	1062572	1086504	11	23943	-1
chr1	625271	1086505	1096571	3943	14009	1
chr1	625265	1096572	1100161	2436	6025	-1
chr1	173125	1100162	1106067	3329	9234	-1
chr1	598265	1106068	1112101	286	6319	1
chr1	625360	1112102	1172572	251	60721	1
chr1	173111	1172573	1172716	1	144	-1
chr1	173103	1172817	1173945	1	1129	1
chr1	170531	1174046	1174188	8791	8933	-1
chr1	625363	1174189	1183590	67	9468	1
chr1	173120	1183591	1183929	153	491	-1
chr1	170509	1183930	1184112	864	1046	1
chr1	173119	1184213	1189703	1	5491	-1
chr1	625357	1189804	1213915	1	24112	1
chr1	625359	1214016	1216330	1	2315	1
} );
	@sgp_dump = reverse (@sgp_dump) if defined $reverse;   # test the auto-sorting feature

	my $first = 1;
	for $line ( @sgp_dump ) {
	  if( $first ) { $first = 0; next; }
	  my ( $chr_name, $contig_id, $chr_start, 
	       $chr_end, $contig_start, $contig_end, $contig_ori ) = split ( /\t/, $line );

# new argument order:
	  $map->add_map_coordinates( $contig_id, $contig_start, $contig_end, $contig_ori,  
				     $chr_name, $chr_start, $chr_end );
	  
	}
}




# Define a subroutine to say whether an object is a Coordinate or a Gap.
# This should be in the Gap/Coordinate object itself but isn't.
# It might change in future so it's abstracted out here in this test.
#
# this is damn ugly
#
sub isgap { my ($obj) = @_; return !$obj->can ('strand') }


