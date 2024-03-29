=head1 LICENSE

 Copyright (c) 1999-2011 The European Bioinformatics Institute and
 Genome Research Limited.  All rights reserved.

 This software is distributed under a modified Apache license.
 For license details, please see

   http://www.ensembl.org/info/about/code_licence.html

=head1 CONTACT

 Please email comments or questions to the public Ensembl
 developers list at <dev@ensembl.org>.

 Questions may also be sent to the Ensembl help desk at
 <helpdesk@ensembl.org>.

=cut

# Ensembl module for Bio::EnsEMBL::Variation::StructuralVariation
#
# Copyright (c) 2004 Ensembl
#


=head1 NAME

Bio::EnsEMBL::Variation::StructuralVariation - Ensembl representation of a structural variation.

=head1 SYNOPSIS

    # Structural variation representing a CNV
    $sv = Bio::EnsEMBL::Variation::StructuralVariation->new
       (-variation_name => 'esv25480',
				-class_so_term => 'structural_variant',
				-source => 'DGVa',
				-source_description => 'Database of Genomic Variants Archive',
				-study_name => 'estd20',
				-study_description => 'Conrad 2009 "Origins and functional impact of copy number variation in the human genome." PMID:19812545 [remapped from build NCBI36]',
				-study_url => 'ftp://ftp.ebi.ac.uk/pub/databases/dgva/estd20_Conrad_et_al_2009',
				-external_reference => 'pubmed/19812545');

    ...

    print $sv->name(), ":", $sv->var_class();

=head1 DESCRIPTION

This is a class representing a structural variation from the
ensembl-variation database. A structural variant may have a copy number variation, a tandem duplication, 
an inversion of the sequence or others structural variations. 

The position of a StructuralVariation object on the Genome is represented
by the <Bio::EnsEMBL::Variation::StructuralVariationFeature> class.

=head1 METHODS

=cut

use strict;
use warnings;

package Bio::EnsEMBL::Variation::StructuralVariation;

use Bio::EnsEMBL::Variation::BaseStructuralVariation;

our @ISA = ('Bio::EnsEMBL::Variation::BaseStructuralVariation');


sub new {
	my $caller = shift;
	my $class = ref($caller) || $caller;
	
	my $self = Bio::EnsEMBL::Variation::BaseStructuralVariation->new(@_);
	return(bless($self, $class));
}

=head2 get_all_SupportingStructuralVariants

  Example     : $sv->get_all_SupportingStructuralVariants();
  Description : Retrieves all SupportingStructuralVariation associated with this structural variation.
                Return empty list if there are none.
  Returntype  : reference to list of Bio::EnsEMBL::Variation::SupportingStructuralVariation objects
  Exceptions  : None
  Caller      : general
  Status      : At Risk

=cut

sub get_all_SupportingStructuralVariants {
	my $self = shift;
	
	if (defined ($self->{'adaptor'})){
		my $ssv_adaptor = $self->{'adaptor'}->db()->get_SupportingStructuralVariationAdaptor();
		return $ssv_adaptor->fetch_all_by_StructuralVariation($self);
  }
	warn("No variation database attached");
  return [];
}


=head2 summary_as_hash

  Example       : $sv_summary = $sv->summary_as_hash();
  Description   : Retrieves a textual summary of this StructuralVariation object.
  Returns       : hashref of descriptive strings

=cut

sub summary_as_hash {
	my $self = shift;
	my %summary;
	$summary{'display_id'} = $self->display_id;
	$summary{'study_name'} = $self->study_name;
	$summary{'study_description'} = $self->study_description;
	$summary{'class'} = $self->var_class;
	return \%summary;

}

1;
