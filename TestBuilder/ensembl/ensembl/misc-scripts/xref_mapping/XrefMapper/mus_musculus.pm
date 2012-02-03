package XrefMapper::mus_musculus;

use  XrefMapper::BasicMapper;

use vars '@ISA';

@ISA = qw{ XrefMapper::BasicMapper };
use strict;

#sub get_set_lists {
#
#  return [["ExonerateGappedBest1", ["mus_musculus","*"]]];
#
#}

sub set_display_xrefs{
  my $self = shift;
  my $display = XrefMapper::DisplayXrefs->new($self);
  $display->set_display_xrefs_from_stable_table();
 
}

sub set_gene_descriptions(){
  my $self = shift;
  my $display = XrefMapper::DisplayXrefs->new($self);
  $display->set_gene_descriptions_from_display_xref()
}

sub get_official_name{
   return "MGI";
}

sub get_canonical_name{
   return "MGI";
}

sub species_specific_pre_attributes_set{
  my $self  = shift;
  $self->official_naming();
}

sub species_specific_cleanup{
  my $self = shift;
  my $dbname = $self->get_canonical_name;

  print "Removing all $dbname from object_xref not on a Gene\n";
  my $remove_old_ones = (<<JSQL);
delete ox 
  from object_xref ox, xref x, external_db e
    where e.db_name like "$dbname" and 
          ox.ensembl_object_type != "Gene" and
          ox.xref_id = x.xref_id and
	  x.external_db_id = e.external_db_id;
JSQL

  #
  # First Delete all the hgnc object_xrefs not on a gene. (i.e these are copys).
  #

  my $sth = $self->core->dbc->prepare($remove_old_ones);

  $sth->execute() || die "Could not execute: \n$remove_old_ones \n";

  $sth->finish;

}

sub gene_description_sources {

  return ("miRBase",
	  "RFAM", 
          "IMGT/GENE_DB",
	  "MGI_curated_gene",
	  "MGI_curated_transcript",
	  "MGI",
	  "Uniprot/SWISSPROT", 
	  "Uniprot/Varsplic", 
	  "RefSeq_peptide", 
	  "RefSeq_dna", 	  
	  "Uniprot/SPTREMBL" );

}

sub special_filter {

  return ('\(?[0-9A-Z]{10}RIK PROTEIN\)?[ \.]',
	  'RIKEN CDNA [0-9A-Z]{10} GENE',
	  '.*RIKEN FULL-LENGTH ENRICHED LIBRARY.*PRODUCT:',
	  '.*RIKEN FULL-LENGTH ENRICHED LIBRARY.*',
	  '\(*HYPOTHETICAL\s+.*',
	  '^UNKNOWN\s+.*',
	  'CDNA SEQUENCE\s?,? [A-Z]+\d+[ \.;]',
	  'CLONE MGC:\d+[ \.;]',
	  ' MGC:\s*\d+[ \.;]',
	  'HYPOTHETICAL PROTEIN,',
	  'HYPOTHETICAL PROTEIN \S+[\.;]',
	  'DNA SEGMENT, CHR.*',
	  'PROTEIN \S+ HOMOLOG\.?',
	  '^SIMILAR TO GENE.*',
	  'SIMILAR TO PUTATIVE[ \.]',
	  '^SIMILAR TO HYPOTHETICAL.*',
	  'SIMILAR TO (KIAA|LOC|RIKEN).*',
	  'SIMILAR TO GENBANK ACCESSION NUMBER\s+\S+',
	  'SIMILAR TO\s+$',
          'EXPRESSED SEQUENCE [A-Z]+\d+[ \.;]',
          'EST [A-Z]+\d+[ \.;]',
          '^\s*\(FRAGMENT\)\.?\s*$',
	  '^\s*\(?GENE\)?\.?;?\s*$',
          '\s*\(?GENE\)?\.?;?',
          '\s*\(?PRECURSOR\)?\.?;?',
          '^\s*\(\s*\)\s*$',
	  '^\s*\(\d*\)\s*[ \.]$',
          '^\s+\(?\s*$');
}


sub gene_description_filter_regexps {

  return ('\(*HYPOTHETICAL\s+.*',
	  '^UNKNOWN\s+.*',
	  'CDNA SEQUENCE\s?,? [A-Z]+\d+[ \.;]',
	  'CLONE MGC:\d+[ \.;]',
	  ' MGC:\s*\d+[ \.;]',
	  'HYPOTHETICAL PROTEIN,',
	  'HYPOTHETICAL PROTEIN \S+[\.;]',
	  'DNA SEGMENT, CHR.*',
	  'PROTEIN \S+ HOMOLOG\.?',
	  '^SIMILAR TO GENE.*',
	  'SIMILAR TO PUTATIVE[ \.]',
	  '^SIMILAR TO HYPOTHETICAL.*',
	  'SIMILAR TO (KIAA|LOC|RIKEN).*',
	  'SIMILAR TO GENBANK ACCESSION NUMBER\s+\S+',
	  'SIMILAR TO\s+$',
          'EXPRESSED SEQUENCE [A-Z]+\d+[ \.;]',
          'EST [A-Z]+\d+[ \.;]',
          '^\s*\(FRAGMENT\)\.?\s*$',
	  '^\s*\(?GENE\)?\.?;?\s*$',
          '\s*\(?GENE\)?\.?;?',
          '\s*\(?PRECURSOR\)?\.?;?',
          '^\s*\(\s*\)\s*$',
	  '^\s*\(\d*\)\s*[ \.]$',
          '^\s+\(?\s*$');

}

#sub get_list_of_sources_for_one_max_per_transcript{
#  my $self = shift;

#  my @list = qw(MGI);

#  return @list;
#}

1;
