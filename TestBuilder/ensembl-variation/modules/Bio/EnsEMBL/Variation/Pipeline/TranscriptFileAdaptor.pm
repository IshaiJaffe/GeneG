package Bio::EnsEMBL::Variation::Pipeline::TranscriptFileAdaptor;

use strict;

use Digest::MD5 qw(md5_hex);

sub new {
    my $class = shift;

    my %args = @_;

    my $self = bless {}, $class;

    if ($args{fasta_file}) {
        $self->{fasta_file} = $args{fasta_file};
    }
    
    if ($args{transcripts}) {
        $self->_dump_translations($args{transcripts});
    }
    
    return $self;
}

sub get_translation_seq {
    my ($self, $translation_stable_id) = @_;

    my $fasta = $self->get_translation_fasta($translation_stable_id);

    $fasta =~ s/>.*\n//m;
    $fasta =~ s/\s//mg;

    return $fasta;
}

sub get_translation_fasta {
    my ($self, $translation_stable_id) = @_;
    
    my $file = $self->{fasta_file};
    
    my $fasta = `samtools faidx $file $translation_stable_id`;

    return $fasta;
}

sub get_translation_md5 {
    my ($self, $translation_stable_id) = @_;

    return md5_hex($self->get_translation_seq($translation_stable_id));
}

sub get_all_translation_stable_ids {
    my $self = shift;

    my $fasta = $self->{fasta_file};

    my @ids = map {/>(.+)\n/; $1} `grep '>' $fasta`;

    return \@ids;
}

sub _dump_translations {

    my ($self, $transcripts) = @_;

    # dump the translations out to the FASTA file

    my $fasta = $self->{fasta_file};

    open my $FASTA, ">$fasta" or die "Failed to open $fasta for writing";

    # get rid of any existing index file

    if (-e "$fasta.fai") {
        unlink "$fasta.fai" or die "Failed to delete fasta index file";
    }

    for my $transcript (@$transcripts) {

        my $tl = $transcript->translation;
    
        next unless $tl;

        my $protein = $tl->seq;

        $protein =~ s/(.{80})/$1\n/g;

        # get rid of any trailing newline
        chomp $protein;

        my $hdr = $tl->stable_id;

        print $FASTA ">$hdr\n$protein\n";
    }

    close $FASTA;

    # index the file

    `samtools faidx $fasta`;
}
 

1;
