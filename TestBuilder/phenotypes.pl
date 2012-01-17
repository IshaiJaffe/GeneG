use strict;
use lib 'C:/src/ensembl/ensembl/modules';
use lib 'C:/src/ensembl/ensembl/modules/Bio/EnsEMBL/DBSQL';
use lib 'C:/src/ensembl-variation/modules';
use Bio::EnsEMBL::Registry;
use JSON;
use LWP;
use WWW::Mechanize;



getPhenotypeByVarient('rs1421085','rs17636733', 'rs10506410');

#register to Ensembel data base
sub registry{
my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous'
);	

return $registry;
}

#The function recieves varients as arguments, finds their phonotypes and update the DB
sub getPhenotypeByVarient{
	my @varients = @_;
	my $registry = registry();

	# Fetch a variation object
	my $var_adaptor = $registry->get_adaptor('human', 'variation', 'variation');
	my %found_phenotypes;
	my $phenotype_url = 'http://geneg.herokuapp.com/api/gluz/phenotype/?format=json&username=admin&api_key=2974a4b896fdfc7316b03d0c452ed48675aeed01';
	
	foreach my $varient (@varients){
	my $var = $var_adaptor->fetch_by_name($varient);	
	# Fetch all the variation annotations associated with the variation
	my $va_adaptor = $registry->get_adaptor('homo_sapiens', 'variation', 'variationannotation');
	
	foreach my $va (@{$va_adaptor->fetch_all_by_Variation($var)}) {
	my $phenotype_description = $va->phenotype_description;
	
	if (!exists ($found_phenotypes{$phenotype_description})) {
		$found_phenotypes{$phenotype_description}=$varient;
		 #create json
		 my %jsonStructure= ();
		$jsonStructure{name} = $phenotype_description;
		my $json = encode_json \%jsonStructure;
		my $res = postData($json, $phenotype_url);
		my $phenotype_id = get_phenotype_id($phenotype_url, $phenotype_description);
		getVarientByPhenotype($phenotype_description, $va->source_name, $registry, $varient, $phenotype_id);
				
	}

	}
	
	
}
}

#The function recieves phenotype of varient finds all the varients which associated with this
#phenotype and update the DB with all the varients and info about them
sub getVarientByPhenotype{
	my ($phenotype, $source_name, $registry, $variat_name, $phenotype_id)= @_;
	my $va_adaptor = $registry->get_adaptor('homo_sapiens', 'variation', 'variationannotation');
	my $pubmedID;
	my $varient_url = 'http://geneg.herokuapp.com/api/gluz/variant/?format=json&username=admin&api_key=2974a4b896fdfc7316b03d0c452ed48675aeed01';
		foreach my $va (@{$va_adaptor->fetch_all_by_phenotype_description_source_name($phenotype,$source_name)}) {
		my $external_reference = $va->external_reference;
		$external_reference =~ s/\// ID: /;
		 
		print "Variation ", $va->variation_names, " is associated with the phenotype '", $phenotype,
	      "' in the source ", $source_name;
		print " with a p-value of ",$va->p_value if (defined($va->p_value));
		print ".\n";
		my $risk_allele;	
		if (defined $va->associated_variant_risk_allele) {
			$risk_allele = (split /\-/, $va->associated_variant_risk_allele)[1];
			print "The risk allele is ", $risk_allele;
		}
		print " External reference: ", $external_reference, ".\n", "\n";
		
		# Create a basic JSON hash
		my %jsonStructure= ();
		$jsonStructure{name} = $va->variation_names;
		$jsonStructure{phenotype_id} = $phenotype_id;
		$jsonStructure{source} = $va->source_name;
		$jsonStructure{p_value} = $va->p_value;
		$jsonStructure{risk_allel} = $risk_allele;
		$jsonStructure{pubmed_id} = $external_reference;
	
	my $json = encode_json \%jsonStructure;
	postData($json, $varient_url);
	}
		print "\n";
	

}

#The function insert data to the DB
sub postData{
	my ($json, $url) = @_;
 	my $req = HTTP::Request->new(POST => $url);
	$req->content_type('application/json');
	$req->content($json);

	my $ua = LWP::UserAgent->new; 
	my $res = $ua->request($req);
	print $res->content;
}

#The function recieve phenotype, look for it in the DB and returns the phenotype's id
sub get_phenotype_id
{
  my ($json_url, $phenotype) = @_;
  my $browser = WWW::Mechanize->new();
  my $phenotype_id; 
  eval{
    # download the json page:
    print "Getting json $json_url\n";
    $browser->get( $json_url );
    my $content = $browser->content();
    my $json = new JSON;
 
    # these are some nice json options to relax restrictions a bit:
    my $json_text = $json->allow_nonref->utf8->relaxed->decode($content);
 
    # iterate over each object in the JSON structure:
    foreach my $episode(@{$json_text->{objects}}){
      if($episode->{name} eq $phenotype){
      	$phenotype_id = $episode->{id};
      }
    }
  };
  # catch crashes:
  if($@){
    print "[[JSON ERROR]] JSON parser crashed! $@\n";
  }
  return $phenotype_id;
}		