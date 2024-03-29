package XrefMapper::UniParcMapper;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw(throw);

use base qw(XrefMapper::BasicMapper);

my $DEFAULT_METHOD = 'XrefMapper::Methods::OracleUniParc';

sub new {
  my($class, $mapper) = @_;
  my $self = bless {}, $class;
  $self->core($mapper->core);
  $self->xref($mapper->xref);
  $self->uniparc($mapper->uniparc());
  $self->mapper($mapper);
  $self->method($self->uniparc()->method() || $DEFAULT_METHOD);
  return $self;
}

sub _xref_helper {
  my ($self) = @_;
  return $self->xref()->dbc()->sql_helper();
}

sub logic_name {
  my ($self) = @_;
  return 'XrefChecksum';
}

sub external_db_name {
  my ($self) = @_;
  return 'UniParc';
}

sub mapper {
  my ($self, $mapper) = @_;
  $self->{mapper} = $mapper if defined $mapper;
  return $self->{mapper};
}

sub method {
  my ($self, $method) = @_;
  $self->{method} = $method if defined $method;
  return $self->{method};
}

sub verbose {
  my ($self) = @_;
  return $self->mapper()->verbose();
}

sub process {
  my ($self, $do_upload) = @_;
  
  $self->_update_status('checksum_xrefs_started');
  
  my $method = $self->get_method();
  my $results = $method->run();

  if($do_upload) {
    $self->log_progress('Starting upload');
    $self->upload($results);
  }
  
  $self->_update_status('checksum_xrefs_finished');
  return;
}

sub upload {
  my ($self, $results) = @_;
  
  #The elements come in as an array looking like
  #  [ { id => 1, upi => 'UPI00000A', object_type => 'Translation' } ]
  
  my $insert_xref = <<'SQL';
INSERT INTO xref (source_id, accession, label, version, species_id, info_type)
values (?,?,?,?,?,?)
SQL
  my $insert_object_xref = <<'SQL';
INSERT INTO object_xref (ensembl_id, ensembl_object_type, xref_id, linkage_type, ox_status)
values (?,?,?,?,?)
SQL
  
  my $h = $self->_xref_helper();
  my $source_id = $self->source_id();
  my $species_id = $self->species_id();
   
  $h->transaction(-CALLBACK => sub {
    
    $self->log_progress('Starting xref insertion');
    #Record UPIs to make sure we do not insert a UPI in more than once
    my %upi_xref_id;
    $h->batch(-SQL => $insert_xref, -CALLBACK => sub {
      my ($sth) = @_;
      foreach my $e (@{$results}) {
        my $upi = $e->{upi};
        if(exists $upi_xref_id{$upi}) {
          $e->{xref_id} = $upi_xref_id{$upi};
        }
        else {
          $sth->execute($source_id, $e->{upi}, $e->{upi}, 1, $species_id, 'CHECKSUM');
          my $id = $sth->{'mysql_insertid'};
          $e->{xref_id} = $id;
          $upi_xref_id{$upi} = $id;
        }
      }
      return;
    });
    
    $self->log_progress('Starting object_xref insertion');
    $h->batch(-SQL => $insert_object_xref, -CALLBACK => sub {
      my ($sth) = @_;
      foreach my $e (@{$results}) {
        $sth->execute($e->{id}, $e->{object_type}, $e->{xref_id}, 'CHECKSUM', 'DUMP_OUT');
      }
      return;
    });
  });
  
  $self->log_progress('Finished insertions');
  
  return;
}

sub source_id {
  my ($self) = @_;
  return $self->_xref_helper()->execute_single_result(
    -SQL => 'select source_id from source where name=?',
    -PARAMS => [$self->external_db_name()]
  );
}

sub species_id {
  my ($self) = @_;
  my $species_id = $self->SUPER::species_id();
  if(! defined $species_id) {
    $species_id = $self->get_id_from_species_name($self->core()->species());
    $self->SUPER::species_id($species_id);
  }
  return $species_id;
}

sub get_method {
  my ($self) = @_;
  my $method_class = $self->method();
  eval "require ${method_class};";
  if($@) {
    throw "Cannot require the class ${method_class}. Make sure your PERL5LIB is correct: $@";
  }
  return $method_class->new( -MAPPER => $self );
}

############# INTERNAL METHODS

sub _update_status {
  my ($self, $status) = @_;
  if($self->xref()) {
    my $h = $self->_xref_helper();
    my $sql = q{insert into process_status (status, date) values(?,now())};
    $h->execute_update(-SQL => $sql, -PARAMS => [$status]);
  }
  else {
    my $time = localtime();
    $self->log_progress(q{Status Update '%s' @ %s}."\n", $status, $time);
  }
  return;
}

sub log_progress {
  my ( $self, $fmt, @params ) = @_;
  return if (!$self->verbose);
  printf( STDERR "CHKSM==> %s", sprintf( $fmt, @params ) );
}

1;