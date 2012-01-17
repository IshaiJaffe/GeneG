package XrefMapper::ornithorhynchus_anatinus;

use  XrefMapper::BasicMapper;

use vars '@ISA';

@ISA = qw{ XrefMapper::BasicMapper };

# Same as in BasicMapper but Genoscope order reversed.

sub transcript_display_xref_sources {
  my @list = qw(Platypus_olfactory_receptor
		Oxford_FGU_Oa_tscript
		Oxford_FGU_Oa_gene
		RFAM
		miRBase
		IMGT/GENE_DB
		HUGO
		SGD
		MGI
		flybase_symbol
		Anopheles_symbol
		Genoscope_annotated_gene
		Uniprot/SWISSPROT
		Uniprot/Varsplic
		RefSeq_peptide
		RefSeq_dna
		Uniprot/SPTREMBL
		EntrezGene);

  my %ignore;

  $ignore{"EntrezGene"} =(<<'IEG');
SELECT DISTINCT ox.object_xref_id
  FROM object_xref ox, dependent_xref dx, 
       xref xmas, xref xdep, 
       source smas, source sdep
    WHERE ox.xref_id = dx.dependent_xref_id AND
          dx.dependent_xref_id = xdep.xref_id AND
          dx.master_xref_id = xmas.xref_id AND
          xmas.source_id = smas.source_id AND
          xdep.source_id = sdep.source_id AND
          smas.name like "Refseq%predicted" AND
          sdep.name like "EntrezGene" AND
          ox.ox_status = "DUMP_OUT"
IEG

  $ignore{"Uniprot/SPTREMBL"} =(<<BIGN);
SELECT object_xref_id
    FROM object_xref JOIN xref USING(xref_id) JOIN source USING(source_id)
     WHERE ox_status = 'DUMP_OUT' AND name = 'Uniprot/SPTREMBL' 
      AND priority_description = 'protein_evidence_gt_3'
BIGN

  return [\@list,\%ignore];
}

sub gene_description_sources {

 return ("RFAM",
         "miRBase",
         "IMGT/GENE_DB",
         "Uniprot/SWISSPROT",
         "RefSeq_peptide",
         "RefSeq_dna",
         "Uniprot/Varsplic",
         "Uniprot/SPTREMBL");

}




1;
