#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Modules::FET;
use Carp qw/croak carp/;
use Config::Simple;
use DBIx::Class::ResultSet;
use DBIx::Class::Row;
use IO::File;
use File::Temp;
use JSON;

#All logging to STDERR to the file specified
open(STDERR, ">>/home/genodo/logs/group_wise_comparisons.log") || die "Error stderr: $!";

my ($CONFIG, $DBNAME, $DBUSER, $DBHOST, $DBPASS, $DBPORT, $DBI);
my ($USERCONFIG, $USERNAME, $USERREMOTEADDR, $USERSESSIONID, $USERJOBID, $USERGP1STRAINIDS, $USERGP2STRAINIDS, $USERGP1STRAINNAMES, $USERGP2STRAINNAMES, $GEOSPATIAL);

GetOptions('config=s' => \$CONFIG, 'user_config=s' => \$USERCONFIG) or (exit -1);
croak "Missing db config file\n" unless $CONFIG;
croak "Missing user specific config file\n" unless $USERCONFIG;

if(my $db_conf = new Config::Simple($CONFIG)) {
	$DBNAME = $db_conf->param('db.name');
	$DBUSER = $db_conf->param('db.user');
	$DBPASS = $db_conf->param('db.pass');
	$DBHOST = $db_conf->param('db.host');
	$DBPORT = $db_conf->param('db.port');
	$DBI = $db_conf->param('db.dbi');
}
else {
	die Config::Simple->error();
}

#Set user config params here
if (my $user_conf = new Config::Simple($USERCONFIG)) {
	$USERNAME = $user_conf->param('user.username');
	$USERREMOTEADDR = $user_conf->param('user.remote_addr');
	$USERSESSIONID = $user_conf->param('user.session_id');
	$USERJOBID = $user_conf->param('user.job_id');
	$USERGP1STRAINIDS = $user_conf->param('user.gp1IDs');
	$USERGP2STRAINIDS = $user_conf->param('user.gp2IDs');
	$USERGP1STRAINNAMES = $user_conf->param('user.gp1Names');
	$USERGP2STRAINNAMES = $user_conf->param('user.gp2Names');
	$GEOSPATIAL = $user_conf->param('user.geospatial');
}
else {
	die Config::Simple->error();
}

my $dbsource = 'dbi:' . $DBI . ':dbname=' . $DBNAME . ';host=' . $DBHOST;
$dbsource . ';port=' . $DBPORT if $DBPORT;

my $schema = Database::Chado::Schema->connect($dbsource, $DBUSER, $DBPASS);

if (!$schema) {
	die "Could not connect to database: $!\n";
}

print STDERR "New comparison for user $USERNAME : $USERSESSIONID\n";

my $binaryFETResults = getBinaryData($USERGP1STRAINIDS, $USERGP2STRAINIDS, $USERGP1STRAINNAMES, $USERGP2STRAINNAMES);
my $snpFETResults = getSnpData($USERGP1STRAINIDS, $USERGP2STRAINIDS, $USERGP1STRAINNAMES, $USERGP2STRAINNAMES);

print STDERR "Writing out html file\n";

#Writes out new temp HTML file and returns temp file name to update job status in db
my $tempHTMLFileID = writeOutHtml($binaryFETResults, $snpFETResults, $GEOSPATIAL, $USERGP1STRAINIDS, $USERGP2STRAINIDS);

print STDERR "Writing completed job to db\n";

#Updates job status in the db
my $default_job_rs = $schema->resultset('Job')->find({job_id => $USERJOBID});
die "Job ID: $USERJOBID does not exist in database.\n" unless $default_job_rs;
$default_job_rs->update({status => "$tempHTMLFileID"});

sub getBinaryData {
	my $group1GenomeIds = shift;
	my $group2GenomeIds = shift;
	my $group1GenomeNames = shift;
	my $group2GenomeNames = shift;

	my $group1lociDataTable = $schema->resultset('Feature')->search(
		{'loci_genotypes.genome_id' => $group1GenomeIds, 'type.name' => 'pangenome'},
		{
			join => ['loci_genotypes', 'type', 'featureprops'],
			select => ['me.feature_id', 'me.uniquename', 'featureprops.value', {sum => 'loci_genotypes.locus_genotype'}],
			as => ['feature_id', 'id', 'function', 'locus_count'],
			group_by => [qw/me.feature_id me.uniquename me.name featureprops.value/]
		}
		);

	my $group2lociDataTable = $schema->resultset('Feature')->search(
		{'loci_genotypes.genome_id' => $group2GenomeIds, 'type.name' => 'pangenome'},
		{
			join => ['loci_genotypes', 'type', 'featureprops'],
			select => ['me.feature_id', 'me.uniquename', 'featureprops.value', {sum => 'loci_genotypes.locus_genotype'}],
			as => ['feature_id', 'id', 'function', 'locus_count'],
			group_by => [qw/me.feature_id me.uniquename me.name featureprops.value/]
		}
		);

	my @group1Loci = $group1lociDataTable->all;
	my @group2Loci = $group2lociDataTable->all;

	my $fet = Modules::FET->new();
	$fet->group1($group1GenomeIds);
	$fet->group2($group2GenomeIds);
	$fet->group1Markers(\@group1Loci);
	$fet->group2Markers(\@group2Loci);
	$fet->testChar('1');
	#Returns hash ref of results
	my $results = $fet->run('locus_count');

	# #Print results to file
	my $tmp = File::Temp->new(	TEMPLATE => 'tempXXXXXXXXXX',
		DIR => '/home/genodo/group_wise_data_temp/',
		UNLINK => 0);

	print $tmp "Group 1: " . join(", ", @{$group1GenomeNames}) . "\n" . "Group 2: " . join(", ", @{$group2GenomeNames}) . "\n";   

	print $tmp "Locus ID \t Group 1 Present \t Group 1 Absent \t Group 2 Present \t Group 2 Absent \t p-value \n";

	my $allResultArray =  $results->[0]{'all_results'};
	foreach my $allResultRow (@{$allResultArray}) {
		print $tmp $allResultRow->{'marker_id'} . "\t" . $allResultRow->{'group1Present'} . "\t" . $allResultRow->{'group1Absent'} . "\t" . $allResultRow->{'group2Present'} . "\t" . $allResultRow->{'group2Absent'} . "\t" . $allResultRow->{'pvalue'} . "\n";
	}

	my $temp_file_name = $tmp->filename;
	$temp_file_name =~ s/\/home\/genodo\/group_wise_data_temp\///g;

	push($results, {'file_name' => $temp_file_name});
	push($results, {'gp1_names' => $group1GenomeNames});
	push($results, {'gp2_names' => $group2GenomeNames});

	return $results;
}

sub getSnpData {
	my $group1GenomeIds = shift;
	my $group2GenomeIds = shift;
	my $group1GenomeNames = shift;
	my $group2GenomeNames = shift;

	my $group1SnpDataTable = $schema->resultset('Feature')->search(
		{'snps_genotypes.genome_id' => $group1GenomeIds, 'type.name' => 'pangenome'},
		{
			join => ['snps_genotypes', 'type', 'featureprops'],
			select => ['me.feature_id', 'me.uniquename', 'featureprops.value', {sum => 'snps_genotypes.snp_a'}, {sum => 'snps_genotypes.snp_t'}, {sum => 'snps_genotypes.snp_c'}, {sum => 'snps_genotypes.snp_g'}],
			as => ['feature_id', 'id', 'function', 'a_count', 't_count', 'c_count', 'g_count'],
			group_by => [qw/me.feature_id me.uniquename me.name featureprops.value/]
		}
		);

	my $group2SnpDataTable = $schema->resultset('Feature')->search(
		{'snps_genotypes.genome_id' => $group2GenomeIds, 'type.name' => 'pangenome'},
		{
			join => ['snps_genotypes' , 'type', 'featureprops'],
			select => ['me.feature_id', 'me.uniquename','featureprops.value', {sum => 'snps_genotypes.snp_a'}, {sum => 'snps_genotypes.snp_t'}, {sum => 'snps_genotypes.snp_c'}, {sum => 'snps_genotypes.snp_g'}],
			as => ['feature_id', 'id', 'function', 'a_count', 't_count', 'c_count', 'g_count'],
			group_by => [qw/me.feature_id me.uniquename me.name featureprops.value/]
		}
		);

	my @group1Snps = $group1SnpDataTable->all;
	my @group2Snps = $group2SnpDataTable->all;

	my $fet = Modules::FET->new();
	$fet->group1($group1GenomeIds);
	$fet->group2($group2GenomeIds);
	$fet->group1Markers(\@group1Snps);
	$fet->group2Markers(\@group2Snps);

	my @results;
	#Returns hash ref of results
	$fet->testChar('A');
	my $a_results = $fet->run('a_count');
	$fet->testChar('T');
	my $t_results = $fet->run('t_count');
	$fet->testChar('C');
	my $c_results = $fet->run('c_count');
	$fet->testChar('G');
	my $g_results = $fet->run('g_count');

	#Merge all results and resort them
	my @combineAllResults = (@{$a_results->[0]{'all_results'}}, @{$t_results->[0]{'all_results'}}, @{$c_results->[0]{'all_results'}}, @{$g_results->[0]{'all_results'}});
	my @combineSigResults = (@{$a_results->[1]{'sig_results'}}, @{$t_results->[1]{'sig_results'}}, @{$c_results->[1]{'sig_results'}}, @{$g_results->[1]{'sig_results'}});
	my $combineSigCount = $a_results->[2]{'sig_count'} + $t_results->[2]{'sig_count'} + $c_results->[2]{'sig_count'} + $g_results->[2]{'sig_count'};	
	my $combineTotalComparisons = $a_results->[3]{'total_comparisons'} + $t_results->[3]{'total_comparisons'} + $c_results->[3]{'total_comparisons'} + $g_results->[3]{'total_comparisons'};

	my @sortedAllResults = sort({$a->{'pvalue'} <=> $b->{'pvalue'}} @combineAllResults);
	my @sortedSigResults = sort({$a->{'pvalue'} <=> $b->{'pvalue'}} @combineSigResults);

	push(@results, {'all_results' => \@sortedAllResults}, {'sig_results' => \@sortedSigResults}, {'sig_count' => $combineSigCount}, {'total_comparisons' => $combineTotalComparisons});

	# #Print results to file
	my $tmp = File::Temp->new(	TEMPLATE => 'tempXXXXXXXXXX',
		DIR => '/home/genodo/group_wise_data_temp/',
		UNLINK => 0);

	print $tmp "Group 1: " . join(", ", @{$group1GenomeNames}) . "\n" . "Group 2: " . join(", ", @{$group2GenomeNames}) . "\n";   

	print $tmp "SNP ID \t Nucleotide \t Group 1 Present \t Group 1 Absent \t Group 2 Present \t Group 2 Absent \t p-value \n";

	foreach my $sortedAllResultRow (@sortedAllResults) {
		print $tmp $sortedAllResultRow->{'marker_id'} . "\t" . $sortedAllResultRow->{'test_char'} . "\t" . $sortedAllResultRow->{'group1Present'} . "\t" . $sortedAllResultRow->{'group1Absent'} . "\t" . $sortedAllResultRow->{'group2Present'} . "\t" . $sortedAllResultRow->{'group2Absent'} . "\t" . $sortedAllResultRow->{'pvalue'} . "\n";
	}

	my $temp_file_name = $tmp->filename;
	$temp_file_name =~ s/\/home\/genodo\/group_wise_data_temp\///g;
	
	push(@results, {'file_name' => $temp_file_name});
	push(@results, {'gp1_names' => $group1GenomeNames});
	push(@results, {'gp2_names' => $group2GenomeNames});

	return \@results;
}

sub writeOutHtml {
	my ($_binaryResults, $_snpResults, $_geospatial, $_strain1IDs, $_strain2IDs) = @_;

	for (my $i = 0; $i < scalar(@{$_snpResults}); $i++) {
		print STDERR $_ . "\t" foreach(keys %{$_snpResults->[$i]});
		print STDERR "at index $i\n";
	}

	# #Print results to file
	my $tmp = File::Temp->new(	TEMPLATE => 'tempXXXXXXXXXX',
		DIR => '/home/genodo/group_wise_data_temp/',
		SUFFIX => '.html',
		UNLINK => 0);

	my $tempFileName = $tmp->filename;
	$tempFileName =~ s/\/home\/genodo\/group_wise_data_temp\///g;

	#Print HTML output START
	my $HTML = '<div class="span12" style="margin-bottom:20px">';
	$HTML .= '<h1>GROUPWISE RESULTS PAGE</h1>';
	$HTML .= '<span class="help-block">';
	$HTML .= '</span>';
	$HTML .= '</div>';

	$HTML .= '<div class="tabbable">';

	$HTML .= '<ul class="nav nav-tabs">';
	$HTML .= '<li class="active"><a href="#loci_table" id="loci_results_button" data-toggle="tab">Loci Presence Absence</a></li>';
	$HTML .= '<li><a href="#snps_table" id="snp_results_button" data-toggle="tab">SNP Presence Absence</a></li>';
	$HTML .= '<li id="geo-spatial-tab" style="display:none"><a href="#geo-spatial" id="geospatial_results_button" data-toggle="tab">Geospatial Results</a></li>';
	$HTML .= '</ul>';

	$HTML .= '<div class="tab-content">';
	
	$HTML .= '<div class="tab-pane active" id="loci_table" style="padding:5px">';
	$HTML .= '<caption><h3>Binary FET Results</h3></caption>';
	$HTML .= '<span class="help-block">There were a total of '.$_binaryResults->[2]->{'sig_count'}.' significant difference(s) detected from '.$_binaryResults->[3]->{'total_comparisons'}.' total comaprisons.</span>';
	$HTML .= '<p>The following table outputs only comparisons with <strong>significant</strong> differences between your selected groups (to view all comparisons made, download the .txt file provided in the link below). You can filter through the data table displayed on this page by providing search criteria in the input boxes above each column. For example, to only show significant differences with a p-value of less than 0.01, simply type in &lt;0.01 in the input box above the p-value column and hit enter.</p>';
	$HTML .= '<p><a href="/temp/'.$_binaryResults->[4]->{'file_name'}.'" download="loci_presence_absence.txt">Click here</a> to download a tab-delimited .txt file of all comparisons made.</p>';

	$HTML .= '<div class="row-fluid">';
	$HTML .= '<div class="span6" style="border:solid;border-width:1px;border-color:#d3d3d3;padding:10px;height:200px">';
	$HTML .= '<div style="max-height:150px;overflow:auto">';
	$HTML .= '<span class="help-block">Group 1: </span>';
	$HTML .= '<ul>';

	foreach my $name (@{$_binaryResults->[5]->{'gp1_names'}}) {
		$HTML .= '<li>'.$name.'</li>';
	}

	$HTML .= '</ul>';
	$HTML .= '</div>';
	$HTML .= '</div>';
	$HTML .= '<div class="span6" style="border:solid;border-width:1px;border-color:#d3d3d3;padding:10px;height:200px">';
	$HTML .= '<div style="max-height:150px;overflow:auto">';
	$HTML .= '<span class="help-block">Group 2: </span>';
	$HTML .= '<ul>';

	foreach my $name (@{$_binaryResults->[6]->{'gp2_names'}}) {
		$HTML .= '<li>'.$name.'</li>';
	}

	$HTML .= '</ul>';
	$HTML .= '</div>';
	$HTML .= '</div>';
	$HTML .= '</div>';

	$HTML .= '<table id="table1" class="table table-condensed">';
	$HTML .= '<thead>';
	$HTML .= '<tr>';
	$HTML .= '<th>Locus ID</th>';
	$HTML .= '<th>Function</th>';
	$HTML .= '<th>Group 1 Present</th>';
	$HTML .= '<th>Group 1 Absent </th>';
	$HTML .= '<th>Group 2 Present</th>';
	$HTML .= '<th>Group 2 Absent</th>';
	$HTML .= '<th>p-value</th>';
	$HTML .= '</tr>';
	$HTML .= '</thead>';
	$HTML .= '<tbody>';

	foreach my $sigResult (@{$_binaryResults->[1]->{'sig_results'}}) {
		$HTML .= '<tr>';
		$HTML .= '<td id="'.$sigResult->{'marker_id'}.'" feature_id="'.$sigResult->{'marker_feature_id'}.'" type="locus_marker">'.$sigResult->{'marker_id'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'marker_function'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'group1Present'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'group1Absent'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'group2Present'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'group2Absent'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'pvalue'}.'</td>';
		$HTML .= '</tr>';
	}

	$HTML .= '</tbody>';
	$HTML .= '</table>';
	$HTML .= '</div>';
	
	$HTML .= '<div class="tab-pane" id="snps_table" style="padding:5px">';
	$HTML .= '<caption><h3>SNP FET Results</h3></caption>';
	$HTML .= '<span class="help-block">There were a total of '.$_snpResults->[2]->{'sig_count'}.' significant difference(s) detected from '.$_snpResults->[3]->{'total_comparisons'}.' total comaprisons.</span>';
	$HTML .= '<p>The following table outputs only comparisons with <strong>significant</strong> differences between your selected groups (to view all comparisons made, download the .txt file provided in the link below). You can filter through the data table displayed on this page by providing search criteria in the input boxes above each column. For example, to only show significant differences with a p-value of less than 0.01, simply type in &lt;0.01 in the input box above the p-value column and hit enter.</p>';
	$HTML .= '<p><a href="/temp/'.$_snpResults->[4]->{'file_name'}.'" download="snp_presence_absence.txt">Click here</a> to download a tab-delimited .txt file of all comparisons made.</p>';
	$HTML .= '<div class="row-fluid">';
	$HTML .= '<div class="span6" style="border:solid;border-width:1px;border-color:#d3d3d3;padding:10px;height:200px">';
	$HTML .= '<div style="max-height:150px;overflow:auto">';
	$HTML .= '<span class="help-block">Group 1: </span>';
	$HTML .= '<ul>';
	
	foreach my $name (@{$_snpResults->[5]->{'gp1_names'}}) {
		$HTML .= '<li>'.$name.'</li>';
	}

	$HTML .= '</ul>';
	$HTML .= '</div>';
	$HTML .= '</div>';

	$HTML .= '<div class="span6" style="border:solid;border-width:1px;border-color:#d3d3d3;padding:10px;height:200px">';
	$HTML .= '<div style="max-height:150px;overflow:auto">';
	$HTML .= '<span class="help-block">Group 2: </span>';
	$HTML .= '<ul>';

	foreach my $name (@{$_snpResults->[6]->{'gp2_names'}}) {
		$HTML .= '<li>'.$name.'</li>';
	}

	$HTML .= '</ul>';
	$HTML .= '</div>';
	$HTML .= '</div>';
	$HTML .= '</div>';

	$HTML .= '<table id="tableSNP" class="table table-condensed">';
	$HTML .= '<thead>';
	$HTML .= '<tr>';
	$HTML .= '<th>SNP ID</th>';
	$HTML .= '<th>Function</th>';
	$HTML .= '<th>Nucleotide</th>';
	$HTML .= '<th>Group 1 Present</th>';
	$HTML .= '<th>Group 1 Absent</th>';
	$HTML .= '<th>Group 2 Present</th>';
	$HTML .= '<th>Group 2 Absent</th>';
	$HTML .= '<th>p-value</th>';
	$HTML .= '</tr>';
	$HTML .= '</thead>';
	$HTML .= '<tbody>';

	foreach my $sigResult (@{$_snpResults->[1]->{'sig_results'}}) {
		$HTML .= '<tr>';
		$HTML .= '<td id="'.$sigResult->{'marker_id'}.'" feature_id="'.$sigResult->{'marker_feature_id'}.'" type="snp_marker">'.$sigResult->{'marker_id'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'marker_function'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'test_char'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'group1Present'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'group1Absent'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'group2Present'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'group2Absent'}.'</td>';
		$HTML .= '<td>'.$sigResult->{'pvalue'}.'</td>';
		$HTML .= '</tr>';
	}

	$HTML .= '</tbody>';
	$HTML .= '</table>';
	$HTML .= '</div>';

	# if ($_geospatial eq "true") {

	# 	$HTML .= '<div class="tab-pane active" id="geo-spatial" style="padding:5px">';
	# 	$HTML .= '<span class="help-block">Note: The map only shows strains with a location. Not all selected strains will appear on the map.</span>';
	# 	$HTML .= '<div class="row-fluid">';
	# 	$HTML .= '<!--div class="span6" style="height:400px;border-style:solid;border-width:1px;border-color:#d3d3d3">';
	# 	$HTML .= '<p>Tree goes here</p>';
	# 	$HTML .= '</div-->';
	# 	$HTML .= '<div class="span6">';
	# 	$HTML .= '<table>';
	# 	$HTML .= '<tr>';
	# 	$HTML .= '<div id="map-canvas" style="height:400px;border-style:solid;border-width:1px;border-color:#d3d3d3"></div>';
	# 	$HTML .= '<div class="row-fluid">';
	# 	$HTML .= '<div class="span6"><img src="/App/Pictures/genodo_measle_red.png"> Group 1</div>';
	# 	$HTML .= '<div class="span6"><img src="/App/Pictures/genodo_measle_blue.png"> Group 2</div>';
	# 	$HTML .= '</div>';
	# 	$HTML .= '</tr>';
	# 	$HTML .= '</table>';
	# 	$HTML .= '</div>';
	# 	$HTML .= '</div>';
	# 	$HTML .= '</div>';

	# }

	$HTML .= '</div>';
	$HTML .= '</div>';

	print $tmp $HTML or die "Could not print out HTML file: $!\n";
	#Print HTML output END

	print STDERR "New temp HTML file created : $tempFileName.\n";
	return $tempFileName;
}