use strict;
use lib 'ensembl/ensembl/modules';
use lib 'ensembl/ensembl/modules/Bio/EnsEMBL/DBSQL';
use lib 'ensembl-variation/modules';
use Bio::EnsEMBL::Registry;
use JSON;
use LWP;
use WWW::Mechanize;


unless ($#ARGV == 0){
	getAllVariants();
}

getPhenotypeByVarient(@ARGV);

sub getAllVariants {
	my $registry = registry();

	# Get the variation set for the phenotype-associated variants.
	my $vs_adaptor =
	  $registry->get_adaptor( 'human', 'variation', 'variationset' );
	my $vs = $vs_adaptor->fetch_by_short_name('ph_variants');
	my $varient_url =
'http://geneg.herokuapp.com/api/gluz/variant/?format=json&username=admin&api_key=2974a4b896fdfc7316b03d0c452ed48675aeed01';
	my $phenotypes_url =
'http://geneg.herokuapp.com/api/gluz/phenotype/?format=json&username=admin&api_key=2974a4b896fdfc7316b03d0c452ed48675aeed01';
	my $limit   = 100;
	my $fetched = 0;
	my $it      = $vs->get_Variation_Iterator();

	# Get the first 100 examples and print some data from them
	while ( $fetched < $limit && $it->has_next() ) {

		my $var = $it->next();
		my $annotations = $var->get_all_VariationAnnotations();

		# Loop over the annotations and print the phenotypes
		foreach my $annotation ( @{$annotations} ) {

			#check if the phenotype already exists
			my $phenotype_description = $annotation->phenotype_description;
			my $phenotype_url =
			    $phenotypes_url
			  . '&username=admin&name='
			  . $phenotype_description;
			my $phenotype_json = get_data($phenotype_url);
			my $phenotype_id =
			  get_id( $phenotype_json, $phenotype_description );
			my $phenotypeJson;
			if ( !defined $phenotype_id ) {
				my %phenotypeJsonStruct = ();
				$phenotypeJsonStruct{name} = $phenotype_description;
				$phenotypeJson = encode_json \%phenotypeJsonStruct;
				postData($phenotypeJson, $phenotypes_url);
				my $phenotype_json = get_data($phenotype_url);
				$phenotype_id = get_id( $phenotype_json, $phenotype_description );
			}
			else {
				$phenotypeJson = '"/api/gluz/phenotype/' . $phenotype_id . '/"';
			}

			#check if the variant already exists
			my $curr_variant_url =
			    $varient_url
			  . '&username=admin&name='
			  . $var->name()
			  . '&phenotype='
			  . $phenotype_id;
			my $variantJson = get_data($curr_variant_url);
			my $variant_id = get_id( $variantJson, $var->name() );

			my $external_reference = $annotation->external_reference();
			$external_reference =~ s/\// ID:/;
			my $risk_allele;
			if ( defined $annotation->associated_variant_risk_allele() ) {
				$risk_allele =
				  ( split /\-/, $annotation->associated_variant_risk_allele )
				  [1];
			}
			
			my $json = createJson( $var->name(), $external_reference,
					$annotation, $varient_url, $phenotypeJson, $risk_allele );
			if ( defined $variant_id ) {
				my $variant_to_update = 'http://geneg.herokuapp.com/api/gluz/variant/'.$variant_id.'/?format=json&api_key=2974a4b896fdfc7316b03d0c452ed48675aeed01&username=admin';
				updateData($json, $variant_to_update);
			}
			else {
				postData( $json, $varient_url );
			}
		}
		$fetched++;
	}
}

#register to Ensembel data base
sub registry {
	my $registry = 'Bio::EnsEMBL::Registry';

	$registry->load_registry_from_db(
		-host => 'ensembldb.ensembl.org',
		-user => 'anonymous'
	);

	return $registry;
}

#The function recieves varients as arguments, finds their phonotypes and update the DB
sub getPhenotypeByVarient {
	my @varients = @_;
	my $registry = registry();

	# Fetch a variation object
	my $var_adaptor =
	  $registry->get_adaptor( 'human', 'variation', 'variation' );
	my %found_phenotypes;
	my $phenotype_url =
'http://geneg.herokuapp.com/api/gluz/phenotype/?format=json&username=admin&api_key=2974a4b896fdfc7316b03d0c452ed48675aeed01';

	foreach my $varient (@varients) {
		my $var = $var_adaptor->fetch_by_name($varient);

		# Fetch all the variation annotations associated with the variation
		my $va_adaptor = $registry->get_adaptor( 'homo_sapiens', 'variation',
			'variationannotation' );

		foreach my $va ( @{ $va_adaptor->fetch_all_by_Variation($var) } ) {
			my $phenotype_description = $va->phenotype_description;

			#check if phenotype already exists
			my $url =
			  $phenotype_url . '&username=admin&name=' . $phenotype_description;
			my $json_text = get_data($url);
			my $phenotype_id = get_id( $json_text, $phenotype_description );
			if ( !defined $phenotype_id ) {

				#create json
				my %jsonStructure = ();
				$jsonStructure{name} = $phenotype_description;
				my $json = encode_json \%jsonStructure;
				my $res = postData( $json, $phenotype_url );
				my $url =
				    $phenotype_url
				  . '&username=admin&name='
				  . $phenotype_description;
				my $json_text = get_data($url);
				 $phenotype_id = get_id( $json_text, $phenotype_description );
			}
			getVarientByPhenotype( $phenotype_description, $va->source_name,
				$registry, $varient, $phenotype_id );
		}
	}
}

#The function recieves phenotype of varient finds all the varients which associated with this
#phenotype and update the DB with all the varients and info about them
sub getVarientByPhenotype {
	my ( $phenotype, $source_name, $registry, $variat_name, $phenotype_id) =
	  @_;
	my $va_adaptor = $registry->get_adaptor( 'homo_sapiens', 'variation',
		'variationannotation' );
	my $pubmedID;
	my $varient_url =
'http://geneg.herokuapp.com/api/gluz/variant/?format=json&username=admin&api_key=2974a4b896fdfc7316b03d0c452ed48675aeed01';

	foreach my $va (
		@{
			$va_adaptor->fetch_all_by_phenotype_description_source_name(
				$phenotype, $source_name )
		}
	  )
	{
		#check if the variant already exists
			my $curr_variant_url =
			    $varient_url
			  . '&username=admin&name='
			  . $va->variation_names
			  . '&phenotype='
			  . $phenotype_id;
			my $variantJson = get_data($curr_variant_url);
			my $variant_id = get_id( $variantJson, $va->variation_names);
		
		my $external_reference = $va->external_reference;
		$external_reference =~ s/\//ID: /;
		my $risk_allele;
		if ( defined $va->associated_variant_risk_allele ) {
			$risk_allele =
			  ( split /\-/, $va->associated_variant_risk_allele )[1];
		}
		my $phenotypeToSend = '"/api/gluz/phenotype/' . $phenotype_id . '/"';
		my $json = createJson( $va->variation_names, $external_reference, $va,
			$varient_url, $phenotypeToSend, $risk_allele );
			if ( defined $variant_id ) {
				my $variant_to_update = 'http://geneg.herokuapp.com/api/gluz/variant/'.$variant_id.'/?format=json&api_key=2974a4b896fdfc7316b03d0c452ed48675aeed01&username=admin';
				updateData($json, $variant_to_update);
			}
			else {
				postData( $json, $varient_url );
			}	
	}
}

#The function insert data to the DB
sub postData {
	my ( $json, $url ) = @_;
	my $req = HTTP::Request->new( POST => $url );
	$req->content_type('application/json');
	$req->content($json);

	my $ua  = LWP::UserAgent->new;
	my $res = $ua->request($req);
}

sub updateData {
	my ( $json, $url) = @_;
	my $req = HTTP::Request->new( PUT => $url );
	$req->content_type('application/json');
	$req->content($json);

	my $ua  = LWP::UserAgent->new;
	my $res = $ua->request($req);
	print $res->content;
	print "\n";

}

sub get_data {
	my ($json_url) = $_[0];
	my $browser = WWW::Mechanize->new();
	$browser->get($json_url);
	my $content   = $browser->content();
	my $json      = new JSON;
	my $json_text = $json->allow_nonref->utf8->relaxed->decode($content);

	return $json_text;
}

#The function recieve phenotype, look for it in the DB and returns the phenotype's id
sub get_id {
	my ( $json_text, $name ) = @_;
	my $id;

	# iterate over each object in the JSON structure:
	foreach my $episode ( @{ $json_text->{objects} } ) {
		if ( $episode->{name} eq $name ) {
			$id = $episode->{id};
		}
	}

	return $id;
}

sub createJson {
	my $name               = shift;
	my $external_reference = shift;
	my $annotation         = shift;
	my $varient_url        = shift;
	my $phenotype          = shift;
	my $risk_allele        = shift;

	my $json =
	    '{"name":"' 
	  . $name
	  . '","phenotype":'
	  . $phenotype
	  . ',"source":"'
	  . $annotation->source_name();
	if ( defined $annotation->p_value() ) {
		$json .= '","p_value":"' . $annotation->p_value();
	}

	if ( defined $risk_allele ) {
		$json .= '","risk_allel":"' . $risk_allele;
	}
	if ( defined $external_reference ) {
		$json .= '","pubmed_id":"' . $external_reference;
	}
	$json .= '"}';
	return $json;
}
