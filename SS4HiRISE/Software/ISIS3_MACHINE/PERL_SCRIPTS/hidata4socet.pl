#!/usr/bin/perl -s

################################################################################
# NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE
#
#      This script is not supported by ISIS.
#      If you have problems please contact the Astrogeology Photogrammetry group
#      at PlanetaryPhotogrammetry@usgs.gov
#
# NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE
################################################################################

use File::Copy;
use File::Basename;
use Cwd;

my ($progname) = ($0 =~ m#([^/]+)$#);  # get the name of this program

################################################################################
#
# Location-dependent paths, fix for your system:

$MOLA_DB_path = "/archive/projects/SOCET_SET/DATABASES/MOLA/";
$PEDR2TABPRM_path = "/archive/projects/SOCET_SET/DATABASES/MOLA/";
$PEDR_DB_path = "/archive/projects/mola/";
$pedr2tab_path = "/home/thare/bin/linux/";
$pedrTAB2SHP_path = "/usgs/cdev/contrib/bin/";
$isis3arc_dd_path = "/home/thare/bin/";

# End of Location-dependent paths
################################################################################

$email = "PlanetaryPhotogrammetry\@usgs.gov";

#####################################################################
# remove static define for recommended ISIS version
# $isisversion = "isis3.9.1";

$isisversion = `printenv ISIS_VERSION`;
chomp ($isisversion);
$len = length($isisversion);
if ($len == 0)
{
  print "\nISIS_VERSION not set in your environment\n";
  print "there are no longer checks for version, trying to continue.\n\n";
}

#####################################################################

my $usage = "

**************************************************************************
*** NOTE: $progname currently running under isis version: $isisversion ***
**************************************************************************

Command:  $progname project_name noproj_img1 noproj_img2

Where:
       project_name = Name of SS project
       noproj_img1 = First noproj'ed image of a stereopair
       noproj_img2 = Second noproj'ed image of a stereopair

Description:

       $progname will run ISIS3 and PEDR programs to generate the needed
       MOLA DEM, MOLA track data, and statistics files needed for the
       creation of <project_name> in Socet Set.  Specifically, based on
       the stereo-overlap of the input noproj'ed images:
          1) A MOLA DEM will be generated as an ISIS3 cube and an ascii
             ARG grid file.  The MOLA DEM will be stored in folder/directory
             ./MOLA_DEM.  Note that folder/directory
             ./MOLA_DEM will be created by this script for you.
          2) The MOLA track data will be generated as an shapefile.  The
             track data will be stored in ./MOLA_TRACKS.  Note that folder/
             directory ./MOLA_TRACKS will be created by this script for you.
          3) A file listing the geographic reference point and Z-range
             of the stereo-overlap area will be created.  This file will
             be named ./<project_name>_SS_statistics.lis
          4) A campt listing for noproj_img1 and noproj_img2 will also
             be generated (named campt_<noproj_img>.prt) and placed in
             the same directory(ies) that the noproj'ed images are stored in
       
       A report of errors encountered in the processing goes to file:
       \"hidata4socet.err\" and \"hidata4socet.prt\".

       Note that any errors with ISIS programs will cause this script to abort.


**************************************************************************
**************************************************************************
NOTICE:
       $progname currently running under isis version: $isisversion
       This script is not supported by ISIS.
       If you have problems please contact the Astrogeology Planetary
       Photogrammetry Lab (APPL Lab) at $email
**************************************************************************
**************************************************************************
";

#####################################################################
#  MAIN APPLICATION SECTION
#  Author: Elpitha Howington-Kraus
#  Version: 2.0
#  History: JAN 28 2009 - E Howington-Kraus, USGS, Flagstaff Original Version
#           Jun  9 2009 - EHK, made script more portable by checking
#                         if this script was being run on an Astro
#                         machine (by verifying GROUP=flagstaff), before
#                         checking for the ISIS version.
#                         Also, switched to using pedrTAB2SHP_og.pl instead
#                         of pedrTAB2SHP.pl.  (Same code, but more
#                         descriptive program name.)
#           Jun 25 2009 - EHK, corrected bug/typo
#           Aug 25 2010 - EHK, modified for isis3.2.0
#           Aug 12 2011 - EHK, updated new path names for PEDR files transfered
#                         from the farms to the SAN.
#           Dec  6 2011 - EHK, updated new path names for MOLA files transfered
#                         from the farms to the SAN, and added isisversion
#                         that script runs under.
#           May 02 2012 - EHK, added Location-dependent paths for easier
#                         portability outside of astrogeology center,
#                         and updated isisversion to isis3.3.1
#           May 22 2012 - EHK, Changed error message to print failed
#                         command to the string....this is more diagnositic,
#                         and updated isisversion to isis3.4.0
#           Jul 13 2012 - EHK, added isis3arc_dd_path
#           Mar 20 2013 - EHK,
#                         1) made changes for isis3.4.3
#                         2) added explicit path to getkey so that
#                            this script is portable to external
#                            users that have installed the unix 
#                            version of getkey on their systems
#                         3) moved location-dependent paths to top
#                            of script for ease of editing by external
#                            users
#           Jul 10 2013 - EHK, insured script runs under isis3.4.4
#           Jun 12 2015 - EHK, insured script runs under isis3.4.9, and
#                         for script portability:
#                           1) added $PEDR2TABPRM_path
#                           2) Updated contact to PlanetaryPhotogrammetry
#           Jun 25 2020 - TMH 1) updated to support new APPL env.
#                         /usgs/cdev/contrib/bin/.bashrc.APPL
#                         This is where the current version of
#                         ISIS is defined within the environment
#                         variable $ISIS_VERSION
#                         2) removed setisis test for dpw-user group
#
#####################################################################

#--------------------------------------------------------------------
# Forces a buffer flush after every print, printf, and write on the
# currently selected output handle.  Let's you see output as it's
# happening.
#---------------------------------------------------------------------
   $| = 1;

#--------------------------------------------------------------------
# First make sure setisis or conda activate for ISIS3 was run
#--------------------------------------------------------------------
   $ISISexists = `command -v getkey`;
   chomp ($ISISexists);
   $len = length($ISISexists);
   if ($len == 0)
   {
      print "\nISIS IS NOT IN THE PATH ...ENTER:\n";

      print "setisis $isisversion\n";
      print "or\nconda actvate isis$isisversion\n\n";
      exit 1;
   }
   # Check to make sure getkey in run from the ISIS environment
   if (index($ISISexists, "isis") == -1) {
      print "\ngetkey from this path: $ISISexists\n";
      print "    does not appear to the required version from ISIS.\n";
      print "    Please make sure the ISIS path is set such that\n";
      print "    getkey from the ISIS installation is called first.\n";
      exit 1;
   }

#---------------------------------------------------------------------
# Check the argument list
#---------------------------------------------------------------------
   if ($#ARGV != 2)
      {
      print "\n\nRun $progname as follows:";
      print "$usage\n";
      exit 1;
      }

#---------------------------------------------------------------------
# Obtain the input parameters
#---------------------------------------------------------------------

   $project_name = $ARGV[0];
   $noproj_img1 = $ARGV[1];
   $noproj_img2 = $ARGV[2];

#---------------------------------------------------------------------
# If the "hidata4socet.prt" & "hidata4socet.err" files exist,
# delete them
#---------------------------------------------------------------------

   if (-e "hidata4socet.prt") {unlink("hidata4socet.prt");}
   if (-e "hidata4socet.err") {unlink("hidata4socet.err");}

#---------------------------------------------------------------------
# Make sure input images exist
#---------------------------------------------------------------------

   if (!(-e $noproj_img1))
      {
      print "*** ERROR *** Input image does not exist: $noproj_img1\n";
      print "$progname terminating...\n";
      exit 1;
      }

   if (!(-e $noproj_img2))
      {
      print "*** ERROR *** Input image does not exist: $noproj_img2\n";
      print "$progname terminating...\n";
      exit 1;
      }

#---------------------------------------------------------------------
# Create output filenames
#---------------------------------------------------------------------

  $cwd = getcwd();

  $project_mola_dem_dir = "MOLA_DEM";
  $project_mola_cub =  "./MOLA_DEM/". $project_name . "_mola.cub";
  $project_mola_asc = "./MOLA_DEM/" . $project_name . "_mola.asc";

  $project_mola_track_dir = "./MOLA_TRACKS";
  $project_mola_pedr = "./MOLA_TRACKS/PEDR2TAB.PRM";

  $project_stats = "./" . $project_name . "_SS_statistics.lis";

#---------------------------------------------------------------------
# Open LOG file
#---------------------------------------------------------------------

   $log = $cwd . "/hidata4socet.err";
   open (LOG,">$log") or die "\n Cannot open $log\n";

#---------------------------------------------------------------------
# Determine the ographic and ocentric mbr of the footprint of each image
# Note that the for both the ographic and ocentric mbr, longitudes are
# +East.  However the ographic mbr is in the +/- 180 degree system,
# and the ocentric mbr is in the 360 degree system.
#---------------------------------------------------------------------

  ographic_mbr ($noproj_img1, $ul_lat_og1, $ul_lon_og1, $lr_lat_og1, $lr_lon_og1);
  ographic_mbr ($noproj_img2, $ul_lat_og2, $ul_lon_og2, $lr_lat_og2, $lr_lon_og2);

  ocentric_mbr ($noproj_img1, $ul_lat_oc1, $ul_lon_oc1, $lr_lat_oc1, $lr_lon_oc1);
  ocentric_mbr ($noproj_img2, $ul_lat_oc2, $ul_lon_oc2, $lr_lat_oc2, $lr_lon_oc2);

#---------------------------------------------------------------------
# Now determine the ographic and ocentric mbr of the stereocoverage
#---------------------------------------------------------------------

  stereo_mbr ($ul_lat_og1, $ul_lon_og1, $lr_lat_og1, $lr_lon_og1,
              $ul_lat_og2, $ul_lon_og2, $lr_lat_og2, $lr_lon_og2,
              $ul_lat_stereo_og, $ul_lon_stereo_og, $lr_lat_stereo_og,
              $lr_lon_stereo_og);

  stereo_mbr ($ul_lat_oc1, $ul_lon_oc1, $lr_lat_oc1, $lr_lon_oc1,
              $ul_lat_oc2, $ul_lon_oc2, $lr_lat_oc2, $lr_lon_oc2,
              $ul_lat_stereo_oc, $ul_lon_stereo_oc, $lr_lat_stereo_oc,
              $lr_lon_stereo_oc);

#---------------------------------------------------------------------
# Get the MOLA DEM with a 0.5 degree pad around the ographic
# stereocoverage mbr
#---------------------------------------------------------------------

   $mola_map = "./mola.map";

  #///////////////////////////////////////////////////////////////////
  # pad mbr range of ographic stereocoverage by .5 degrees, and round 
  # round to nearest tenth of a degree
  #///////////////////////////////////////////////////////////////////

   pad_range (0.5, $ul_lat_stereo_og, $ul_lon_stereo_og, $lr_lat_stereo_og,
              $lr_lon_stereo_og, $minlat, $maxlat, $minlon, $maxlon);

   mkdir ($project_mola_dem_dir);

   if ($ul_lat_stereo_og > 0)
     { $mola_cub = "$MOLA_DB_path/mola_128ppd_north_simp_88lat.isis3.cub"; }
   else
     { $mola_cub = "$MOLA_DB_path/mola_128ppd_south_simp_88lat.isis3.cub"; }

   $cmd = "maptemplate map=$mola_map projection=simplecylindrical clon=0.0 targopt=user targetname=mars lattype=planetographic londom=180 rngopt=user minlat=$minlat maxlat=$maxlat minlon=$minlon maxlon=$maxlon resopt=ppd resolution=256";
   system($cmd) == 0 || ReportErrAndDie ("maptemplate failed on command:\n$cmd");

   $cmd = "map2map from=$mola_cub map=$mola_map to=$project_mola_cub+BandSequential pixres=map defaultrange=map interp=bilinear";
   system($cmd) == 0 || ReportErrAndDie ("map2map failed on command:\n$cmd");

   $cmd = "$isis3arc_dd_path/isis3arc_dd $project_mola_cub $project_mola_asc";
   system($cmd);

   unlink ($mola_map);

#---------------------------------------------------------------------
# Generate the <project_name>_SS_statistics.lis file
#---------------------------------------------------------------------

  $temp_pvl = "./temp_stats.pvl";

  #/////////////////////////////////////////////////////////////////////
  # Calculate the SS reference point at the center of the ographic
  # stereo converage.  Round the values to the nearest tenth of a degree
  # (i.e., 6 minutes)
  #/////////////////////////////////////////////////////////////////////

  $SS_ref_lat = $lr_lat_stereo_og + ($ul_lat_stereo_og-$lr_lat_stereo_og)/2;
  $SS_ref_lon = $lr_lon_stereo_og + ($ul_lon_stereo_og-$lr_lon_stereo_og)/2;

  $sign = 1;
  if ($SS_ref_lat < 0) {$sign = -1;}
  $SS_ref_lat = (int(($SS_ref_lat + $sign*0.05) * 10))/10;
  $sign = 1;
  if ($SS_ref_lon < 0) {$sign = -1;}
  $SS_ref_lon = (int(($SS_ref_lon + $sign*0.05) * 10))/10;

  #/////////////////////////////////////////////////////////////////////////
  # Convert decimal degrees to DMS format for Socet Set
  # (Note there is no need to calculate seconds since we rounded to .1 deg)
  #/////////////////////////////////////////////////////////////////////////

  dd2dm ($SS_ref_lat, $SS_ref_lat_deg, $SS_ref_lat_min);
  dd2dm ($SS_ref_lon, $SS_ref_lon_deg, $SS_ref_lon_min);

  #////////////////////////////////////////////////////////////////////////////
  # Because $project_mola_cub is well beyond the extents of the stereocoverage
  # mbr, extract a subarea of $project_mola_cub corresponding to the
  # stereocoverage mbr with a pad of 0.1 degrees (call the new cube $temp_mola.)
  # Get the elevation range from $temp_mola and round to the nearest
  # 100 meters.  If $temp_mola is 'flat', add 100 meters to $maxZ
  #////////////////////////////////////////////////////////////////////////////

  $temp_mola = "temp_mola.cub";
  $temp_map = "temp.map";

  pad_range (0.1, $ul_lat_stereo_og, $ul_lon_stereo_og, $lr_lat_stereo_og,
             $lr_lon_stereo_og, $minlat, $maxlat, $minlon, $maxlon);

   $cmd = "maptemplate map=$temp_map projection=simplecylindrical clon=0.0 targopt=user targetname=mars lattype=planetographic londom=180 rngopt=user minlat=$minlat maxlat=$maxlat minlon=$minlon maxlon=$maxlon resopt=ppd resolution=256";
   system($cmd) == 0 || ReportErrAndDie ("maptemplate failed on command:\n$cmd");

   $cmd = "map2map from=$project_mola_cub map=$temp_map to=$temp_mola pixres=map defaultrange=map interp=bilinear";
   system($cmd) == 0 || ReportErrAndDie ("map2map failed on command:\n$cmd");

  $cmd = "stats from=$temp_mola to=$temp_pvl";
  system($cmd) == 0 || ReportErrAndDie ("stats failed on command:\n$cmd");

  $minZ = `getkey from=$temp_pvl grpname=Results keyword=Minimum`;
  $maxZ = `getkey from=$temp_pvl grpname=Results keyword=Maximum`;
  chomp($minZ);
  chomp($maxZ);

  $minZ = int($minZ/100 + 0.5) * 100;
  $maxZ = int($maxZ/100 + 0.5) * 100;

  if ($minZ == $maxZ) {$maxZ = $maxZ + 100;}

  #/////////////////////////////////////
  # Now write to the SS statistics file
  #/////////////////////////////////////

  open (STATS,">$project_stats") or die "\n Cannot open $project_stats\n";

  print STATS "SOCET Set project: $project_name\n\n";

  if ($SS_ref_lat_min > 9)
    {print STATS "Geographic reference point:  Latitude  = $SS_ref_lat_deg\:$SS_ref_lat_min\:00.0\n";}
  else
    {print STATS "Geographic reference point:  Latitude  = $SS_ref_lat_deg\:0$SS_ref_lat_min\:00.0\n";}

  if ($SS_ref_lon_min > 9)
    {print STATS "                             Longitude = $SS_ref_lon_deg\:$SS_ref_lon_min\:00.000\n\n";}
  else
    {print STATS "                             Longitude = $SS_ref_lon_deg\:0$SS_ref_lon_min\:00.000\n\n";}

  print STATS "Minimum Elevation: $minZ\n";
  print STATS "Maximum Elevation: $maxZ\n";

  close (STATS);

  unlink ($temp_pvl);
  unlink ($temp_mola);
  unlink ($temp_map);

#---------------------------------------------------------------------
# Now generate the campt statistics files for each input image
# NOTE: The line/sample parameters of campt default to the image
#       center, which is what we want
#---------------------------------------------------------------------

  $img_dir = dirname($noproj_img1);
  $basename = basename($noproj_img1,@suffixlist);
  $img_name = substr($basename,0,15);
  $campt_name = $img_dir . "/campt_" . $img_name . ".prt";
  $cmd = "campt from=$noproj_img1 to=$campt_name append=no";
  system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");

  $img_dir = dirname($noproj_img2);
  $basename = basename($noproj_img2,@suffixlist);
  $img_name = substr($basename,0,15);
  $campt_name = $img_dir . "/campt_" . $img_name . ".prt";
  $cmd = "campt from=$noproj_img2 to=$campt_name append=no";
  system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");

#---------------------------------------------------------------------
# We are done with all isis processing, so rename print.prt file
#---------------------------------------------------------------------

   rename ("print.prt","hidata4socet.prt");

#---------------------------------------------------------------------
# Finally get the MOLA track data with a 0.5 degree pad around the
# ocentric stereocoverage mbr (this will take hours)
#---------------------------------------------------------------------

  #/////////////////////////////////////////////////////////////
  # pad mbr range of ocentric stereocoverage by .5 degrees, and 
  # round to nearest tenth of a degree
  #/////////////////////////////////////////////////////////////

  pad_range (0.5, $ul_lat_stereo_oc, $ul_lon_stereo_oc, $lr_lat_stereo_oc,
             $lr_lon_stereo_oc, $minlat, $maxlat, $minlon, $maxlon);

  #//////////////////////
  # create PEDR2TAB file
  #//////////////////////

  mkdir ($project_mola_track_dir);

  $master_PEDR2TAB = "$PEDR2TABPRM_path/PEDR2TAB.PRM";

  $pedr_tab_file = $project_name . ".tab";

  open (IN,$master_PEDR2TAB) || ReportErrAndDie ("[Error] Problem opening input file: $master_PEDR2TAB!\n");

  @master_lines = <IN>;
  close IN;

  open (OUT,">$project_mola_pedr") || ReportErrAndDie ("[Error] Problem opening output file: $project_mola_pedr!\n");

  for ($i=0; $i<=11; $i++)
    { print OUT @master_lines[$i]; }

  print OUT "T \"$pedr_tab_file\" \# OneBigFile, output file template(must be enclosed in quotes).\n\n";
  print OUT "$minlon   \# ground_longitude_min\n";
  print OUT "$maxlon   \# ground_longitude_max\n";
  print OUT "$minlat  \# ground_latitude_min\n";
  print OUT "$maxlat  \# ground_latitude_max\n\n";

  print OUT @master_lines[19];

  close (OUT);

  chdir $project_mola_track_dir;

  $cmd = "$pedr2tab_path/pedr2tab.PCLINUX $PEDR_DB_path/mola_files.txt";
  system($cmd) == 0 || ReportErrAndDie ("pedr2tab.PCLINUX failed on command:\n$cmd");

  $cmd = "$pedrTAB2SHP_path/pedrTAB2SHP_og.pl $pedr_tab_file 2";
  system($cmd) == 0 || ReportErrAndDie ("pedrTAB2SHP_og.pl failed on command:\n$cmd");

  chdir $cwd;

#---------------------------------------------------------------------
# Close the LOG file.
# If an error was detected, print out the log file
#---------------------------------------------------------------------

   close (LOG);

   @lines = `cat $log`;
   if (scalar(@lines) > 0)
      {
      print "\n*** Errors detected in processing ***\n\n";
      print @lines;
      print "\n";
      print "\n*** See hidata4socet.prt for details ***\n\n";
      }
   else
      {
      unlink ($log);
      }

   exit;

##############################################################################
#  Subroutine ographic_mbr:  Determines the ul and lr footprint coordinates
#                            (i.e., mbr) of an input cube in ogrphic
#                            coordinates, in the -180 to 180 degree lon domain 
##############################################################################
sub ographic_mbr #cube ul_lat ul_lon lr_lat lr_lon
                 #@_[0] $_[1]  $_[2]  $_[3]  $_[4]
   {

     $ns = `getkey from=@_[0] grpname=Dimensions keyword=Samples`;
     $nl = `getkey from=@_[0] grpname=Dimensions keyword=Lines`;
     chomp($ns);
     chomp($n1);

     $temp_pvl = "./temp_og.pvl";

     $cmd = "campt from=@_[0] to=$temp_pvl append=no sample=1 line=1";
     system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");
     $ul_lat = `getkey from=$temp_pvl grpname=GroundPoint keyword=PlanetographicLatitude`;
     $ul_lon = `getkey from=$temp_pvl grpname=GroundPoint keyword=PositiveEast180Longitude`;
     chomp ($ul_lat);
     chomp ($ul_lon);

     $cmd = "campt from=@_[0] to=$temp_pvl append=no sample=$ns line=1";
     system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");
     $ur_lat = `getkey from=$temp_pvl grpname=GroundPoint keyword=PlanetographicLatitude`;
     $ur_lon = `getkey from=$temp_pvl grpname=GroundPoint keyword=PositiveEast180Longitude`;
     chomp($ur_lat);
     chomp($ur_lon);

     $cmd = "campt from=@_[0] to=$temp_pvl append=no sample=1 line=$nl";
     system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");
     $ll_lat = `getkey from=$temp_pvl grpname=GroundPoint keyword=PlanetographicLatitude`;
     $ll_lon = `getkey from=$temp_pvl grpname=GroundPoint keyword=PositiveEast180Longitude`;
     chomp($ll_lat);
     chomp($ll_lon);

     $cmd = "campt from=@_[0] to=$temp_pvl append=no sample=$ns line=$nl";
     system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");
     $lr_lat = `getkey from=$temp_pvl grpname=GroundPoint keyword=PlanetographicLatitude`;
     $lr_lon = `getkey from=$temp_pvl grpname=GroundPoint keyword=PositiveEast180Longitude`;
     chomp($lr_lat);
     chomp($lr_lon);

     unlink ($temp_pvl);

     #ul_lat of mbr:
     $_[1] = max ($ul_lat, $ur_lat, $ll_lat, $lr_lat);

     #ul_lon of mbr:
     $_[2] = min ($ul_lon, $ur_lon, $ll_lon, $lr_lon);

     #lr_lat of mbr:
     $_[3] = min ($ul_lat, $ur_lat, $ll_lat, $lr_lat);

     #lr_lon of mbr:
     $_[4] = max ($ul_lon, $ur_lon, $ll_lon, $lr_lon);

   }

##############################################################################
#  Subroutine ocentric_mbr:  Determines the ul and lr footprint coordinates
#                            (i.e., mbr) of an input cube in ocentric
#                            coordinates, and the 0 to 360 degree lon domain 
##############################################################################
sub ocentric_mbr #cube ul_lat ul_lon lr_lat lr_lon
                 #@_[0] $_[1]  $_[2]  $_[3]  $_[4]
   {

     $ns = `getkey from=@_[0] grpname=Dimensions keyword=Samples`;
     $nl = `getkey from=@_[0] grpname=Dimensions keyword=Lines`;
     chomp($ns);
     chomp($n1);

     $temp_pvl = "./temp_oc.pvl";

     $cmd = "campt from=@_[0] to=$temp_pvl append=no sample=1 line=1";
     system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");
     $ul_lat = `getkey from=$temp_pvl grpname=GroundPoint keyword=PlanetocentricLatitude`;
     $ul_lon = `getkey from=$temp_pvl grpname=GroundPoint keyword=PositiveEast360Longitude`;
     chomp ($ul_lat);
     chomp ($ul_lon);

     $cmd = "campt from=@_[0] to=$temp_pvl append=no sample=$ns line=1";
     system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");
     $ur_lat = `getkey from=$temp_pvl grpname=GroundPoint keyword=PlanetocentricLatitude`;
     $ur_lon = `getkey from=$temp_pvl grpname=GroundPoint keyword=PositiveEast360Longitude`;
     chomp($ur_lat);
     chomp($ur_lon);

     $cmd = "campt from=@_[0] to=$temp_pvl append=no sample=1 line=$nl";
     system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");
     $ll_lat = `getkey from=$temp_pvl grpname=GroundPoint keyword=PlanetocentricLatitude`;
     $ll_lon = `getkey from=$temp_pvl grpname=GroundPoint keyword=PositiveEast360Longitude`;
     chomp($ll_lat);
     chomp($ll_lon);

     $cmd = "campt from=@_[0] to=$temp_pvl append=no sample=$ns line=$nl";
     system($cmd) == 0 || ReportErrAndDie ("campt failed on command:\n$cmd");
     $lr_lat = `getkey from=$temp_pvl grpname=GroundPoint keyword=PlanetocentricLatitude`;
     $lr_lon = `getkey from=$temp_pvl grpname=GroundPoint keyword=PositiveEast360Longitude`;
     chomp($lr_lat);
     chomp($lr_lon);

     unlink ($temp_pvl);

     #ul_lat of mbr:
     $_[1] = max ($ul_lat, $ur_lat, $ll_lat, $lr_lat);

     #ul_lon of mbr:
     $_[2] = min ($ul_lon, $ur_lon, $ll_lon, $lr_lon);

     #lr_lat of mbr:
     $_[3] = min ($ul_lat, $ur_lat, $ll_lat, $lr_lat);

     #lr_lon of mbr:
     $_[4] = max ($ul_lon, $ur_lon, $ll_lon, $lr_lon);
   }

##############################################################################
#  Subroutine stereo_mbr:  Determines the ul and lr footprint coordinates
#                          (i.e., mbr) of the stereocoverage of a stereopair
##############################################################################
sub stereo_mbr #ul_lat_1, ul_lon_1, lr_lat_1, lr_lon_1,
               # @_[0]     @_[1]     @_[2]     @_[3]
               #ul_lat_2, ul_lon_2, lr_lat_2, lr_lon_2,
               # @_[4]     @_[5]     @_[6]     @_[7]
               #ul_lat_stereo, ul_lon_stereo, lr_lat_stereo, lr_lon_stereo
               #    $_[8]        $_[9]          $_[10]         $_[11]
  {
    #ul_lat_stereo
    $_[8] = min(@_[0], @_[4]);

    #ul_lon_stereo
    $_[9] = max(@_[1], @_[5]);

    #lr_lat_stereo
    $_[10] = max(@_[2], @_[6]);

    #lr_lon_stereo
    $_[11] = min(@_[3], @_[7]);
  }

##############################################################################
#  Subroutine pad_range:  Pads the input mbr by a given amount to generate
#                         min/max lat/lon coordinates needed for map2map, etc.
##############################################################################
sub pad_range # pad_amount, ul_lat_stereo, ul_lon_stereo, lr_lat_stereo,
              #    @_[0]       @_[1]           @_[2]          @_[3]
              # lr_lon_stereo, minlat, maxlat, minlon, maxlon
              #    @_[4]        $_[5]   $_[6]   $_[7]   $_[8]
  {
    $pad = @_[0];

    #minlat - let it round down
    $_[5] = int((@_[3] - $pad)*10) / 10;

    #maxlat - let it round up
    $_[6] = int((@_[1] + $pad)*10 + 0.5) / 10;

    #minlon - let it round down
    $_[7] = int((@_[2] - $pad)*10) / 10;

    #maxlon - let it round up
    $_[8] = int((@_[4] + $pad)*10 + 0.5) / 10;
   
  }

##############################################################################
#  Subroutine dd2dm: Converts decimal degrees to degrees and minutes
#                    (seconds are not computed for our cuurent needs)
##############################################################################
sub dd2dm #$decimal_deg,   deg,  min
          #  @_[0]       $_[1]  $_[2]
  {
    $sign = 1.0;
    $dd = @_[0];

    if($dd < 0.0) 
      { 
        $sign = -1.0;
        $dd = -1.0 * $dd;
      }

    $_[1] = int($dd);  #NOTE: this is the absolute value of the degrees
    $_[2] = int(($dd - $_[1])*60);

    $_[1] = $sign * $_[1];  #Now change the sign of the degrees if needed
  }

##############################################################################
#  Subroutine max: Return the maximum value stored in a scalar array
##############################################################################
sub max
 {
   my $max = $_[0];
   for ( @_[ 1..$#_ ] ) {
   $max = $_ if $_ > $max;
   }
   $max
 }

##############################################################################
#  Subroutine min: Return the maximum value stored in a scalar array
##############################################################################
sub min 
 {
   my $min = $_[0];
   for ( @_[ 1..$#_ ] ) {
   $min = $_ if $_ < $min;
   }
   $min
 }

##############################################################################
#  Error Handling Subroutine
##############################################################################
sub ReportErrAndDie
    {
    my $ERROR=shift;

    print "$ERROR\n";
    print "$progname aborted\n";

    print LOG "$ERROR\n";
    close(LOG);

    chdir $cwd;

    rename ("print.prt","hidata4socet.prt");
    exit 1;

    }

