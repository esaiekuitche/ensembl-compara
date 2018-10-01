=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

=head1 NAME

Bio::EnsEMBL::Compara::PipeConfig::EBI::Ensembl::LoadMembers_conf

=head1 DESCRIPTION

    Specialized version of the LoadMembers pipeline for Ensembl

=head1 AUTHORSHIP

Ensembl Team. Individual contributions can be found in the GIT log.

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with an underscore (_)

=cut

package Bio::EnsEMBL::Compara::PipeConfig::EBI::Ensembl::LoadMembers_conf;

use strict;
use warnings;


use base ('Bio::EnsEMBL::Compara::PipeConfig::LoadMembers_conf');


sub default_options {
    my ($self) = @_;

    return {
        %{$self->SUPER::default_options},   # inherit the generic ones

    # parameters inherited from EnsemblGeneric_conf and very unlikely to be redefined:
        # It defaults to Bio::EnsEMBL::ApiVersion::software_version()
        # 'ensembl_release'       => 68,

    # parameters that are likely to change from execution to another:
        # It is very important to check that this value is current (commented out to make it obligatory to specify)
        # Change this one to allow multiple runs
        #'rel_suffix'            => 'b',
        #'collection'            => 'ensembl',

    # custom pipeline name, in case you don't like the default one
        # 'rel_with_suffix' is the concatenation of 'ensembl_release' and 'rel_suffix'
        #'pipeline_name'        => 'load_members'.$self->o('rel_with_suffix'),

        # names of species we don't want to reuse this time
        #'do_not_reuse_list'     => [ 'homo_sapiens', 'mus_musculus', 'rattus_norvegicus', 'mus_spretus_spreteij', 'danio_rerio', 'sus_scrofa' ],
        'do_not_reuse_list'     => [ ],

    # "Member" parameters:
        # Store protein-coding genes
        'store_coding'              => 1,
        # Store ncRNA genes
        'store_ncrna'               => 1,
        # Store other genes
        'store_others'              => 1,

    #load uniprot members for family pipeline
        'load_uniprot_members'      => 1,
        'family_mlss_id'            => 30055,    

    # connection parameters to various databases:

        # Uncomment and update the database locations

        # the production database itself (will be created)
        # it inherits most of the properties from HiveGeneric, we usually only need to redefine the host, but you may want to also redefine 'port'
        'host'  => 'mysql-ens-compara-prod-2.ebi.ac.uk',
        'port'  => 4522,

        # the master database for synchronization of various ids (use undef if you don't have a master database)
        'master_db' => 'mysql://ensro@mysql-ens-compara-prod-1:4485/ensembl_compara_master',

        # Ensembl-specific databases
        'staging_loc' => {
            -host   => 'mysql-ensembl-mirror',
            -port   => 4240,
            -user   => 'ensro',
            -pass   => '',
            -db_version => 94,
        },

        'livemirror_loc' => {
            -host   => 'mysql-ensembl-mirror.ebi.ac.uk',
            -port   => 4240,
            -user   => 'ensro',
            -pass   => '',
            -db_version => 93,
        },

        # NOTE: The databases referenced in the following arrays have to be hashes (not URLs)
        # Add the database entries for the current core databases and link 'curr_core_sources_locs' to them
        'curr_core_sources_locs'    => [ $self->o('staging_loc') ],
        #'curr_core_sources_locs'    => [ $self->o('livemirror_loc') ],
        #'curr_core_registry'        => "registry.conf",
        #'curr_file_sources_locs'    => [  ],    # It can be a list of JSON files defining an additionnal set of species

        # Add the database entries for the core databases of the previous release
        'prev_core_sources_locs'   => [ $self->o('livemirror_loc') ],
        #'prev_core_sources_locs'   => [ $self->o('staging_loc1'), $self->o('staging_loc2') ],
        #'prev_core_sources_locs'   => [ ],

        # Add the database location of the previous Compara release. Use "undef" if running the pipeline without reuse
        #'reuse_member_db' => '',
        'reuse_member_db' => 'mysql://ensro@mysql-ens-compara-prod-1:4485/ensembl_compara_93',
    };
}


1;

