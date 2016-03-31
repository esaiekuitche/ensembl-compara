
=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=cut

package Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::ClusterTagging;

use strict;
use warnings;

use Data::Dumper;

use base ('Bio::EnsEMBL::Compara::RunnableDB::BaseRunnable');

sub fetch_input {
    my $self         = shift @_;
    my $gene_tree_id = $self->param_required('gene_tree_id');
    $self->param( 'tree_adaptor', $self->compara_dba->get_GeneTreeAdaptor );
    my $gene_tree = $self->param('tree_adaptor')->fetch_by_dbID($gene_tree_id) or die "Could not fetch gene_tree with gene_tree_id='$gene_tree_id'";
    my $species_tree = $self->compara_dba->get_SpeciesTreeAdaptor->fetch_by_method_link_species_set_id_label( $self->param('mlss_id'), 'default' ) || die "Could not fetch species tree";

    #print Dumper $gene_tree;
    $self->param( 'gene_tree', $gene_tree );
    $self->param( 'species_tree', $species_tree);
}

sub run {
    my $self = shift @_;

    #get LCA (lowest common ancestor)
    my $lca = $self->_get_lca();
    $self->param( 'lca', $lca );

    #get taxonomic coverage
    my $taxonomic_coverage = $self->_get_taxonomic_coverage();
    $self->param( 'taxonomic_coverage', $taxonomic_coverage );

    #get ratio #genes/#species
    my $ratio_gene_species = $self->_get_ratio_gene_species();
    $self->param( 'ratio_gene_species', $ratio_gene_species );
}

sub write_output {
    my $self = shift;
    $self->param('gene_tree')->store_tag( 'lca',                $self->param('lca') );
    $self->param('gene_tree')->store_tag( 'taxonomic_coverage', $self->param('taxonomic_coverage') );
    $self->param('gene_tree')->store_tag( 'ratio_gene_species', $self->param('ratio_gene_species') );
}

##########################################
#
# internal methods
#
##########################################

#Get the latest
sub _get_lca {
    my $self = shift;
    my $genomes_list;

    my $leaves = $self->param('gene_tree')->get_all_Members() || die "Could not get_all_Members for genetree: " . $self->param_required('gene_tree_id');

    #get all the genomes in the tree, store in a hash to avoid duplications.
    foreach my $leaf (@{$leaves}) {
        my $genomeDbId = $leaf->genome_db_id();
        $genomes_list->{$genomeDbId} = 1;
    }

    #storing refences in order to avoid multiple calls of the same functions.
    $self->param('genomes_list',$genomes_list);
    $self->param('gene_tree_leaves',$gene_tree_leaves);

    #store the list of species_tree nodes, in order to get the mrca.
    my @species_tree_node_list;
    foreach my $genomeDbId (keys %{$genomes_list}) {
        my $species_tree_node = $self->param('species_tree')->root->find_leaves_by_field( 'genome_db_id', $genomeDbId )->[0];
        push( @species_tree_node_list, $species_tree_node);
    }

    my $lca = $self->param('species_tree')->Bio::EnsEMBL::Compara::NestedSet::find_first_shared_ancestor_from_leaves( [@species_tree_node_list] );

    return $lca;
}

sub _get_taxonomic_coverage {
    my $self = shift;

    #get all genomes
    my $genomes_list = scalar($self->param('genomes_list'));

    #get all leaves from MRCA
    my @leaves_ancestral = @{ $self->param('lca')->get_all_leaves() };
    $self->param('leaves_ancestral',\@leaves_ancestral);

    my $taxonomic_coverage = sprintf( "%.5f", ( keys(%{$genomes_list})/scalar(@leaves_ancestral) ) );

    return $taxonomic_coverage;
}

sub _get_ratio_species_genes {
    my $self = shift;

    my $ratio_species_genes = sprintf( "%.5f", scalar(@{$self->param('leaves_ancestral')})/scalar(@{$self->param('gene_tree_leaves')}) );

    return $ratio_species_genes;
}

1;