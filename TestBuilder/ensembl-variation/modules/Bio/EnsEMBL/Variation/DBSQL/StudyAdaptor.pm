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

#
# Ensembl module for Bio::EnsEMBL::Variation::DBSQL::StudyAdaptor
#
# Copyright (c) 2011 Ensembl
#
# You may distribute this module under the same terms as perl itself
#
#

=head1 NAME

Bio::EnsEMBL::Variation::DBSQL::StudyAdaptor

=head1 SYNOPSIS
  $reg = 'Bio::EnsEMBL::Registry';
  
  $reg->load_registry_from_db(-host => 'ensembldb.ensembl.org',-user => 'anonymous');
  
  $sta = $reg->get_adaptor("human","variation","study");

  # fetch a study by its name
  $study = $sta->fetch_by_name('estd1'); 

  # fetch all study for a source
  $sta = $reg->get_adaptor("human","variation","study");
  $st = $sta->fetch_all_by_source('NHGRI_GWAS_catalog');
  foreach $study (@{$sta->fetch_all_by_source('NHGRI_GWAS_catalog')}){
  	print $study->dbID, " - ", $study->external_reference ,"\n"; 
  }
  

=head1 DESCRIPTION

This adaptor provides database connectivity for Study objects.

=head1 METHODS

=cut

use strict;
use warnings;

package Bio::EnsEMBL::Variation::DBSQL::StudyAdaptor;

use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::Utils::Exception qw(throw warning);
use Bio::EnsEMBL::Variation::Study;

use base qw{Bio::EnsEMBL::DBSQL::BaseAdaptor};


=head2 fetch_by_name

  Arg [1]    : string $name
  Example    : $study = $study_adaptor->fetch_by_name('estd1');
  Description: Retrieves a study object via its name
  Returntype : Bio::EnsEMBL::Variation::Study
  Exceptions : throw if name argument is not defined
  Caller     : general
  Status     : At Risk

=cut

sub fetch_by_name {
  my $self = shift;
  my $name = shift;

  throw('name argument expected') if(!defined($name));

  my $result = $self->generic_fetch("st.name='$name'");

  return ($result ? $result->[0] : undef);
}


=head2 fetch_by_dbID

  Arg [1]    : int $dbID
  Example    : $study = $study_adaptor->fetch_by_dbID(254);
  Description: Retrieves a Study object via its internal identifier.
               If no such study exists undef is returned.
  Returntype : Bio::EnsEMBL::Variation::Study
  Exceptions : throw if dbID arg is not defined
  Caller     : general
  Status     : Stable

=cut

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;

  throw('dbID argument expected') if(!defined($dbID));
	
	my $result = $self->generic_fetch("st.study_id=$dbID");

  return ($result ? $result->[0] : undef);
}

	
=head2 fetch_all_by_dbID_list

  Arg [1]    : listref $list
  Example    : $study = $study_adaptor->fetch_all_by_dbID_list([907,1132]);
  Description: Retrieves a listref of study objects via a list of internal
               dbID identifiers
  Returntype : listref of Bio::EnsEMBL::Variation::Study objects
  Exceptions : throw if list argument is not defined
  Caller     : general
  Status     : At Risk

=cut

sub fetch_all_by_dbID_list {
  my $self = shift;
  my $list = shift;

  if(!defined($list) || ref($list) ne 'ARRAY') {
    throw("list reference argument is required");
  }
  
  my $id_str = (@$list > 1)  ? " IN (".join(',',@$list).")"   :   ' = \''.$list->[0].'\'';
	
	my $result = $self->generic_fetch("st.study_id $id_str");

  return ($result ? $result : undef);
}


=head2 fetch_all_by_source

  Arg [1]     : string $source_name
  Example     : my $study = $study_adaptor->fetch_by_name('EGAS00000000001');
  Description : Retrieves all Study objects associated with a source.
	Returntype : listref of Bio::EnsEMBL::Variation::Study
  Exceptions : thrown if source_name not provided
  Caller     : general
  Status     : Stable

=cut

sub fetch_all_by_source{
	my $self = shift;
	my $source_name = shift;

	throw('source_name argument expected') if(!defined($source_name));
		
	my $result = $self->generic_fetch("s.name='$source_name'");

	return ($result ? $result : undef);
}


sub _fetch_all_associate_study_id {
		my $self = shift;
    my $study_id = shift;

	  my $a_study;
		my @study_list;
		
		my $sth = $self->prepare(qq{(SELECT DISTINCT study1_id FROM associate_study WHERE study2_id=?)
																 UNION
																(SELECT DISTINCT study2_id FROM associate_study WHERE study1_id=?)});
		$sth->bind_param(1,$study_id,SQL_INTEGER);
		$sth->bind_param(2,$study_id,SQL_INTEGER);
    $sth->execute();
		$sth->bind_columns(\$a_study);

  	while($sth->fetch()) {
			push(@study_list,$a_study);
		}
		return \@study_list;
}


sub _columns {
  return qw(st.study_id st.name st.description st.url st.external_reference st.study_type s.name);
}

sub _tables { return (['study', 'st'],['source', 's']); }

sub _default_where_clause {
  my $self = shift;
  return 'st.source_id = s.source_id';
}

#
# private method, creates study objects from an executed statement handle
# ordering of columns must be consistant
#
sub _objs_from_sth {
  my $self = shift;
  my $sth  = shift;

  my @study;

  my ($study_id,$study_name,$study_description,$study_url,$external_reference,$study_type,$source_name,$associate);

  $sth->bind_columns(\$study_id, \$study_name, \$study_description, \$study_url, 
	                   \$external_reference, \$study_type, \$source_name);

  while($sth->fetch()) {
		
		$associate = $self->_fetch_all_associate_study_id($study_id);
		
    push @study, Bio::EnsEMBL::Variation::Study->new
      (-dbID => $study_id,
       -ADAPTOR => $self,
       -NAME => $study_name,
       -DESCRIPTION => $study_description,
			 -URL => $study_url,
			 -EXTERNAL_REFERENCE => $external_reference,
			 -TYPE => $study_type,
			 -SOURCE => $source_name,
			 -ASSOCIATE => $associate);
  }

  return \@study;
}


1;
