use warnings;
use XML::LibXML;
use constant TRUE => 1;
use constant FALSE => 0;

#my $dom = XML::LibXML->load_xml(location => 'mo.xml');
#my $xpc = XML::LibXML::XPathContext->new($dom);
#$xpc->registerNs('ns', 'raml21.xsd');

#create a hash that corrolates decimal notation to slash notation
	%ipSlashform = ("128.0.0.0", 1,"192.0.0.0", 2,"224.0.0.0", 3,"240.0.0.0", 4,"248.0.0.0", 5,"252.0.0.0", 6,"254.0.0.0", 7,"255.0.0.0", 8,"255.128.0.0", 9,"255.192.0.0", 10,"255.224.0.0", 11,"255.240.0.0", 12,"255.248.0.0", 13,"255.252.0.0", 14,"255.254.0.0", 15,"255.255.0.0", 16,"255.255.128.0", 17,"255.255.192.0", 18,"255.255.224.0", 19,"255.255.240.0", 20,"255.255.248.0", 21,"255.255.252.0", 22,"255.255.254.0", 23,"255.255.255.0", 24,"255.255.255.128", 25,"255.255.255.192", 26,"255.255.255.224", 27,"255.255.255.240", 28,"255.255.255.248", 29,"255.255.255.252", 30,"255.255.255.254", 31,"255.255.255.255", 32,); 

#create a hash that corrolates slash notation to decimal notation
#	%ipDecimalform = (1, "128.0.0.0",2, "192.0.0.0",3, "224.0.0.0",4, "240.0.0.0",5, "248.0.0.0",6, "252.0.0.0",7, "254.0.0.0",8, "255.0.0.0",9, "255.128.0.0",10, "255.192.0.0",11, "255.224.0.0",12, "255.240.0.0",13, "255.248.0.0",14, "255.252.0.0",15, "255.254.0.0",16, "255.255.0.0",17, "255.255.128.0",18, "255.255.192.0",19, "255.255.224.0",20, "255.255.240.0",21, "255.255.248.0",22, "255.255.252.0",23, "255.255.254.0",24, "255.255.255.0",25, "255.255.255.128",26, "255.255.255.192",27, "255.255.255.224",28, "255.255.255.240",29, "255.255.255.248",30, "255.255.255.252",31, "255.255.255.254",32,"255.255.255.255",);

#create redrt groupId => parameters => redrtId => para value
	%redrt = ( 	1 => {	"csFallBPrio" => {1 => 1, 2 => 1, 3 => 2, } ,
						"emerCallPrio" => {1 => 1, 2 => 2, 3 => 3, } ,
						"redirectPrio" => {1 => 1, 2 => 1, 3 => 2, } ,
					},
				2 => {	"csFallBPrio" => {1 => 1, 2 => 1, 3 => 1, } ,
						"emerCallPrio" => {1 => 1, 2 => 2, 3 => 3, } ,
						"redirectPrio" => {1 => 1, 2 => 1, 3 => 1, } ,
					},					
				3 => {	"csFallBPrio" => {1 => 2, 2 => 2, 3 => 1, } ,
						"emerCallPrio" => {1 => 2, 2 => 3, 3 => 1, } ,
						"redirectPrio" => {1 => 2, 2 => 2, 3 => 1, } ,
					},
			);
my $VersionSwitch; my $genTemplate = FALSE;
my $VERSION = '20211121';
if (@ARGV)
{
	ExtractFileAndSwitchList (); 
	if ($VersionSwitch)
	{
		print "Current ver.: $VERSION\n";
		print "Ver. 20211121 	Adding LNCEL , ipaddr verification; Can update for each needed cell from template.\n";
		exit;
	}

	if ($HelpSwitch)
	{
		PrintHelp ();
		exit;
	}
}

my ($flcel,$flsite,$fltemplate) = (FALSE,FALSE,FALSE);
my ($rrhtemplate, $rfmtemplate);
my $swrel = 'NA';
my $logtypeis ='';
for ($inputFileListIndex=0; $inputFileListIndex<=$#inputFileArray; $inputFileListIndex++)
{
	open (INPUT_FILE, $inputFileArray[$inputFileListIndex]) or
		die "Cannot open $inputFileArray[$inputFileListIndex]";
	print '--------------------------------------------------------'."\n";
	print "Reading file $inputFileArray[$inputFileListIndex] . . .\n";

	@filepath = split(/[\\\/]/,$inputFileArray[$inputFileListIndex]);
	if ($inputFileArray[$inputFileListIndex] =~ /$filepath[$#filepath]$/ ) {$filepath = $`;}
	if ($filepath[$#filepath] =~ /(.+).csv$/)  {
		if ($filepath[$#filepath] =~ /bts/)  {
			$logtypeis = 'site';
 			print "***LOG TYPE IS: $logtypeis ***\n\n"; 
		} elsif ($filepath[$#filepath] =~ /cel/) {
			$logtypeis = 'cell';
			print "***LOG TYPE IS: $logtypeis ***\n\n";
		} 
	} elsif ($filepath[$#filepath] =~ /(.+).xml$/) {
		if ($filepath[$#filepath] =~ /template/) {
			$logtypeis = 'template';
			print "***LOG TYPE IS: $logtypeis ***\n\n";
		}
	}
	
	#Loading site/cell data 
	if ((($logtypeis eq 'site') || ($logtypeis eq 'cell')) && (! $genTemplate)){	
		while ($_ = <INPUT_FILE>)  {
			if ($logtypeis eq 'site') {
				if (/Province,Site Name,\$dn/) {
					$_ =~ s/\n//g; $_ =~ s/\r//g;
					@sfirsta = split /;|\t|,/, $_;	 #reading header of planned sitedata
					for  (my $ipos=0; $ipos<=$#sfirsta; $ipos++) { 
						if ($sfirsta[$ipos] eq '') { print ">>> Cell Input Position $ipos : invalid header\n"; }
					}
					$flsite = TRUE; 				
				}   elsif ( ($flsite) && (/^(\w\w),(\w+),PLMN-PLMN\/(MRBTS-\d+\/LNBTS-\d+),/)) {
					my $dn = $3;
					my $sitename = $2;
					$sitedb{$sitename}{'Province'} = $1;
					$_ =~ s/\n//g; $_ =~ s/\r//g; 
					my @siterow = split /;|\t|,/;
					for  (my $ipos=3; $ipos<=$#sfirsta; $ipos++) { 				#starting from lac header
						$sitedb{$sitename}{$sfirsta[$ipos]} = $siterow[$ipos];  
					}				
				}
			} elsif ($logtypeis eq 'cell') {
				if (/Province,Site name,ECI,eCell name,Bandwidth,mrbtsId,lnBtsId,\$dn/) {
					$_ =~ s/\n//g; $_ =~ s/\r//g;
					@cfirsta = split /;|\t|,/, $_;	 #reading header of planned celldata
					for  (my $ipos=0; $ipos<=$#cfirsta; $ipos++) { 
						if ($cfirsta[$ipos] eq '') { print ">>> Site Input Position $ipos : invalid header\n"; } 
					}
					$flcel = TRUE;
				} elsif ( ($flcel) && (/^\w+,\w+,\d+,(\w+),[\w\s]+,\d{6},\d{6},PLMN-PLMN\/(MRBTS-\d+\/LNBTS-\d+\/LNCEL-\d+),(\w+),(\d+)/)) {
#				} elsif ( ($flcel) ) {	
					my $cellname = $1; 
					my $sitename = $3;
					my $id = $4;
					$sitemap{$sitename}{$id} = $cellname; 
					$celldb{$cellname}{'dn'}= $2;
					$_ =~ s/\n//g; $_ =~ s/\r//g; 
					my @cellrow = split /;|\t|,/;
					for  (my $ipos=8; $ipos<=$#cfirsta; $ipos++) { 				#starting from enbName header
						$celldb{$cellname}{$cfirsta[$ipos]} = $cellrow[$ipos];
					}				
				}
			}
		}
		close INPUT_FILE;
	}
	elsif (($logtypeis eq 'template') && (! $genTemplate)){
		my $dom = XML::LibXML->load_xml(location => $inputFileArray[$inputFileListIndex]);
		my $xpc = XML::LibXML::XPathContext->new($dom);
		$xpc->registerNs('ns', 'raml21.xsd');	
		my ($rmod, $smod, $antl, $swrel, $numcell) = (0,0,0,'NA',0);
		my $userlabel = 'S1'; # class FTM
		my ($stext, $sband) = ('','');
		foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
			$_ = $p->getAttribute("class");
			
			if ((/com.nokia.srbts.eqm:SMOD/) || (/^SMOD$/)) {
				$smod++;
			} elsif ((/com.nokia.srbts.eqm:RMOD/) || (/^RMOD$/)) {
				$rmod++;
			} elsif ((/com.nokia.srbts.eqm:ANTL/) || (/^ANTL$/)) {
				$antl++;
			} elsif ((/NOKLTE:LNBTS/) || (/^LNBTS$/) ) {
				$_ = $p->getAttribute("version");
				if (/^([Fx]L\d\d)[_A-Z]/) {
					$swrel = $1;
					#tmp
					if ($swrel eq 'xL19') {
						$swrel = 'FL19';
					}
				}
			} elsif ((/^NOKLTE:LNCEL_FDD$/) || (/^LNCEL$/)) {
				$numcell ++; 
				foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
					$_=$p1->getAttribute("name");
					if (/earfcnDL/) {
						if ($p1->nodeType == XML_ELEMENT_NODE) {
							$stext = $p1->findvalue('.');
							if ($stext eq '1501') {
								$sband = '1800'; 
							} elsif ($stext ne '') {
								$sband .= 'b?';
							}
						};
					}
				}				
			}
		}
		print (">>> Template $filepath[$#filepath] of $smod SM(s), $rmod RM(s), $antl antenna(s) possible for $numcell LTE cell(s)\n");
		$fltemplate = TRUE;
		
		if (($smod > 0) && ($rmod > 0) && ($antl >0) && ($swrel ne 'NA'))  {
			if (($antl/$rmod == 4) || ($antl/$rmod == 2)) {
				$fltemplatedb{$swrel}{'RRH'} =  $inputFileArray[$inputFileListIndex];
				my $count = 1;
				while ( $count < $numcell) {
					$count++;
					$userlabel .= '/1';
				}
				$fltemplatedb{'userlabel'}{'RRH'}  = $userlabel . ' RRH' . " $sband";
			} elsif ($antl/$rmod == 6) {
				$fltemplatedb{$swrel}{'RFM'} =  $inputFileArray[$inputFileListIndex];
				my $count = 1;
				while ( $count < $numcell) {
					$count++;
					$userlabel .= '/1';
				}
				$fltemplatedb{'userlabel'}{'RFM'}  = $userlabel . ' RFM' . " $sband";				
			} else {
				$fltemplatedb{$swrel}{'MIXED'} =  $inputFileArray[$inputFileListIndex];
				$fltemplatedb{'userlabel'}{'MIXED'}  = 'S_RFMIXED_BMIXED';
			}
		} else {
			print ">>> Invalid template $filepath[$#filepath] !!!\n";
		} 
	} #gen Template xml
	elsif ($genTemplate) {
		my $dom = XML::LibXML->load_xml(location => $inputFileArray[$inputFileListIndex]);
		my $xpc = XML::LibXML::XPathContext->new($dom);
		$xpc->registerNs('ns', 'raml21.xsd');
		my $banner = "You are about to access a private system - MLMT.";
		my ($rmod, $smod, $antl, $swrel, $numcell,$mimo) = (0,0,0,'NA',0,0);

		# to remove every line of log, except the last one (FL19 required)
		my @nodes = $xpc->findnodes('/ns:raml/ns:cmData/ns:header/ns:log');
		for ( $p = 0; $p < $#nodes; $p++) {
			$nodes[$p]->unbindNode();
		}
		
		
		foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
			$_ = $p->getAttribute("class");
			if ((/^NOKLTE:LNADJL$/) || (/^NOKLTE:LNADJ$/) || (/^NOKLTE:LNADJW$/) || (/^NOKLTE:LNADJG$/) || (/^NOKLTE:LNREL/) || (/^LNADJL$/) || (/^LNADJ$/) || (/^LNADJW$/) || (/^LNADJG$/) || (/^LNREL/)){
				if ($p->nodeType == XML_ELEMENT_NODE) {
					$p->unbindNode;
				}
			} elsif ((/^com.nokia.srbts.mnl:SECADM$/) || (/^SECADM$/)) {
				foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
					$_=$p1->getAttribute("name");
					if ((/appLoginBannerText/) || (/platLoginBannerText/)) {
						if ($p1->nodeType == XML_ELEMENT_NODE) {
							$p1->removeChildNodes();
							$p1->appendText($banner);
						};
					} 
				}				
			} elsif ((/^NOKLTE:SECPRM$/) || (/^SECPRM$/)) {
				foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
					$_=$p1->getAttribute("name");
					if (/appLoginBannerText/) {
						if ($p1->nodeType == XML_ELEMENT_NODE) {
							$p1->removeChildNodes();
							$p1->appendText($banner);
						};
					} 
				}				
			} elsif ((/com.nokia.srbts.eqm:SMOD/) || (/^SMOD$/)) {
				$smod++;
			} elsif ((/com.nokia.srbts.eqm:RMOD/) || (/^RMOD$/)) {
				$rmod++;
			} elsif ((/com.nokia.srbts.eqm:ANTL/) || (/^ANTL$/)) {
				$antl++;
			} elsif ((/NOKLTE:LNBTS/) || (/^LNBTS$/) ) {
				$_ = $p->getAttribute("version");
				if (/^([Fx]L\d\d)[_A-Z]/) {
					$swrel = $1;
				}
			} elsif ((/^NOKLTE:LNCEL_FDD$/) || (/^LNCEL$/)) {
				$numcell ++; 
			} #estimate MIMO FL16
			 elsif (/LCELL/) {
				$_ = $p->getAttribute("distName");
				if (/LCELL-11/) {
					foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
						$_ = $p1->getAttribute("name");
						if (/txRxUsage/) {
							if ($p1->nodeType == XML_ELEMENT_NODE) {
								$_ = $p1->findvalue('.');
								if (/TXRX/) {
									$mimo++;
								}
							}
						}
					}
				}
			} #estimate MIMO FL18, FL19, xL20
			elsif (/com.nokia.srbts.mnl:CHANNEL/) {
				$_ = $p->getAttribute("distName");
				if (/LCELL-11/) {
					foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
						$_=$p1->getAttribute("name");
						if (/direction/) {
							if ($p1->nodeType == XML_ELEMENT_NODE) {
								$_ = $p1->findvalue('.');
								if (/TX/) {
									$mimo++; 
								}
							}
						} 
					}					
				}
			}
			
		}

		my $scfname = "Configuration_scf_".$numcell."S_";
		if ($mimo == 2) {
			$scfname .= '2x2';
		} elsif ($mimo == 4) {
			$scfname .= '4x4';
		}
		
		if (($smod > 0) && ($rmod > 0) && ($antl >0) && ($swrel ne 'NA'))  { 
			
			if ($antl/$rmod == 4) {
				$scfname .= '_RRH_' . $swrel;
			} elsif ($antl/$rmod == 6) {
				$scfname .= '_RFM_' . $swrel;				
			} else {
				$scfname .= '_MIXED_' . $swrel;
			}
		} 
		
		open my $out, '>', $scfname."_template.xml"; 
		binmode $out;
		$outputs = $dom->toString(0);
		$outputs =~ s/(?<=\n)\s*\n//g;
		print {$out} $outputs;
		close $out;
	}
}

if (! $genTemplate) {
	if ($flcel && $flsite && $fltemplate) { 
		foreach (sort keys %sitedb) {
			my $sitename = $sitedb{$_}{'name'};
			my $rmtype = $sitedb{$_}{'radioModuleType'};
			my $swrel = $sitedb{$_}{'swrel'}; 
			my $siteTemplate =$fltemplatedb{$swrel}{$rmtype};
			
			if ((($rmtype eq 'RRH') || ($rmtype eq 'RFM') || ($rmtype eq 'MIXED')) && (($swrel eq 'FL16') || ($swrel eq 'FL18') || ($swrel eq 'FL19') || ($swrel eq 'xL20')) && (defined $siteTemplate)) {
				print ">>> $sitename is using template >>> $siteTemplate\n";
				my $dom = XML::LibXML->load_xml(location => $siteTemplate);
				my $xpc = XML::LibXML::XPathContext->new($dom);
				$xpc->registerNs('ns', 'raml21.xsd');	

				if ($sitedb{$sitename}{'swrel'} eq "xL20") {
					# update btsid
					foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
						#btsid in distName attribute obj
						$_ = $p->getAttribute("distName");
						if (/\-(\d{6})[\/]?/) {
							s/$1/$sitedb{$sitename}{'lnBtsId'}/g;
						}
						$p->setAttribute("distName",$_);
			
						#btsid in text obj
						$_ = $p->getAttribute("class");
						if (/com.nokia.srbts:MRBTS/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/btsName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									};
								}
							}
						} elsif (/^NOKLTE:LNBTS$/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/enbName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									}
								} # enable ANR - 3 parameters
								elsif (/actUeBasedAnrInterFreqLte/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									};
								}
								elsif (/actUeBasedAnrIntraFreqLte/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									};
								}
								elsif (/actUeBasedAnrUtran/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									};
								}									
							}
						} elsif (/com.nokia.srbts.eqm:SMOD/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/moduleLocation/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'Province'});
									}									
								}
							}
						} elsif (/com.nokia.srbts.tnl:TNL/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/userLabel/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($fltemplatedb{'userlabel'}{$rmtype});
									}	
								}
							}
						}
						elsif (/com.nokia.srbts.eqm:CABLINK/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/EndpointDN$/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/NOKLTE:TRSNW/) {
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/ipV4AddressDN1/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.mnl:CHANNEL/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/antlDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.mnl:MPLANELOCAL/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/ipIfDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						}
						elsif (/com.nokia.srbts.mnl:MPLANENW/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/mPlaneIpv4AddressDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								} elsif (/oamPeerIpAddress/) {		#Here update oam server address since it under same obj as change btsid task
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($sitedb{$sitename}{'oamServerAddr'} =~ /\d+.\d+.\d+.\d+/) {
											$p1->removeChildNodes();
											$p1->appendText($sitedb{$sitename}{'oamServerAddr'});
										}
									}									
								}
							}
						} elsif (/com.nokia.srbts.mnl:CLOCK/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/sModDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.mnl:TOP/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/sPlaneIpAddressDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:ETHIF/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/linkSelectorDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:ETHLK/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/modDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:BRGPRT/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/ethlkDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:TWAMP/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /\-(\d{6})\//) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:TWAMPREFLECT/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /\-(\d{6})\//) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:IPIF/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /\-(\d{6})\//) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:FSTSCH/) {
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:p',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /\-(\d{6})\//) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:RTPOL/) {
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /\-(\d{6})\//) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}
						} elsif (/^NOKLTE:CAREL$/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /(\d{6})/) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}							
						}
					}
			
					#change local ipaddrs of vlanif 1&2 (class IPADDRESSV4)
					foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
						$_ = $p->getAttribute("class");
						if ((/com.nokia.srbts.tnl:IPADDRESSV4/) && (defined $sitedb{$sitename}{'localIpAddr1'}) && (defined $sitedb{$sitename}{'localIpAddr2'})) {
							$_ = $p->getAttribute("distName");
							if (/IPIF-1/) {
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "localIpAddr")) {
										$sipAddr = $p1->findvalue('.');
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr1'});
									} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "localIpPrefixLength")) {
										$stext = $p1->findvalue('.');
										my $netmask = $sitedb{$sitename}{'netMask1'};
										if ( $netmask =~ /\d+.\d+.\d+.\d+/) {
											if ($ipSlashform{$netmask} >= 1) {
												$p1->removeChildNodes();
												$p1->appendText($ipSlashform{$netmask});
											}
										}
									}
								}
							} elsif (/IPIF-2/) {
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "localIpAddr")) {
										$sipAddr = $p1->findvalue('.');
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr2'});
									} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "localIpPrefixLength")) {
										$stext = $p1->findvalue('.');
										my $netmask = $sitedb{$sitename}{'netMask2'};
										if ( $netmask =~ /\d+.\d+.\d+.\d+/) {
											if ($ipSlashform{$netmask} >= 1) {
												$p1->removeChildNodes();
												$p1->appendText($ipSlashform{$netmask});
											}
										}
									}
								}			
							}
						} elsif ((/com.nokia.srbts.tnl:VLANIF/) && (defined $sitedb{$sitename}{'localIpAddr1'}) && ($sitedb{$sitename}{'localIpAddr2'}) && ($sitedb{$sitename}{'vlanId1'}) && ($sitedb{$sitename}{'vlanId2'})) {
							$_ = $p->getAttribute("distName");
							if (/VLANIF-1/) {
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$svlan = $p1->findvalue('.');
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'vlanId1'});
									}
								}								
							} elsif (/VLANIF-2/) {
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$svlan = $p1->findvalue('.');
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'vlanId2'});
									}
								}								
							}
						
						} elsif ((/com.nokia.srbts.tnl:IPRT$/) && (defined $sitedb{$sitename}{'gateway1'}) && (defined $sitedb{$sitename}{'gateway2'})) {
							my $defaultroute = FALSE;
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "destIpAddr")) {
									$_ = $p1->findvalue('.');  
									if (/0.0.0.0/) {
										$defaultroute = TRUE;	
									} else { 
										$defaultroute = FALSE; 
									}
								}
								elsif (($p1->nodeType == XML_ELEMENT_NODE) &&($p1->getAttribute("name") eq "gateway")) {
									$_ = $p1->findvalue('.');
									if ($defaultroute == TRUE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'gateway1'});			
									} elsif ($defaultroute == FALSE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'gateway2'});					
									}
									
								}						
							}
						} elsif ((/com.nokia.srbts.mnl:TOPF/) && (defined $sitedb{$sitename}{'topPrimary'}) && (defined $sitedb{$sitename}{'topSecondary'})) {
							my $topPrim = TRUE;
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "masterIpAddr")) {
									$_ = $p1->findvalue('.');  
									if ($topPrim == TRUE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'topPrimary'});
										$topPrim = FALSE;
									} else {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'topSecondary'});
									}
								}
							}					
						} 
					}
					
					# LNCEL parameters
					foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
						$_ = $p->getAttribute("class");
						
						#change p in class LNCEL_FDD			
						if (/^NOKLTE:LNCEL_FDD$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\//) {
								$scellid = $1; 
								$scellname = $sitemap{$sitename}{$scellid}; 
								if (defined $scellname) {
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "earfcnDL")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'earfcnDL'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "earfcnUL")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'earfcnUL'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "rootSeqIndex")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'rootSeqIndex'});						
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "dlChBw")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'dlChBw'});						
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "ulChBw")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'ulChBw'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumActUE")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumActUE'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumUeDl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumUeDl'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumUeUl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumUeUl'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "dlMimoMode")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'dlMimoMode'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "prachCS")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'prachCS'});					
										}
									}
								} else  {
									print ("!!! No data LNCEL_FDD available for xL20 template's LNCEL $sitename".'_'."$scellid \n") ;
								}
							}
						}
						
						#change p in class LNCEL
						elsif (/^NOKLTE:LNCEL$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)$/) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid}; 
								if (defined $scellname) {
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "tac")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'tac'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "phyCellId")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'phyCellId'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redBwMaxRbDl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'redBwMaxRbDl'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redBwMaxRbUl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'redBwMaxRbUl'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "pMax")) {
											$p1->removeChildNodes();
											$p1->appendText(10*$celldb{$scellname}{'pMax'});				
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "cellName")) {
											$p1->removeChildNodes();
											$p1->appendText($scellname);				
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "expectedCellSize")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'expectedCellSize'});				
										}	
									}
								} else {
									print ("!!! No data LNCEL available for xL20 template's LNCEL $sitename".'_'."$scellid \n") ;
								}
							}
						} 
						
						#change p in class MPUCCH_FDD
						elsif (/^NOKLTE:MPUCCH_FDD$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\//) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								if (defined $scellname ) {
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumRrc")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumRrc'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumRrcEmergency")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumRrcEmergency'});					
										}				
									}
								} else {
									print ("!!! No data MPUCCH available for xL20 template's LNCEL $sitename".'_'."$scellid \n") ;
								}
							}
						}

						#change p in class REDRT
						elsif (/^NOKLTE:REDRT$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\/REDRT-(\d+)/) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								$sredrtid = $2;
								if (defined $scellname ) {
									if ((defined $celldb{$scellname}{'redrtGrp'}) && (defined $sredrtid)) {
										my $sgrp = $celldb{$scellname}{'redrtGrp'};
										foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
											if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "csFallBPrio")) {
												if (defined $redrt{$sgrp}{'csFallBPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'csFallBPrio'}{$sredrtid});
												}
											} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "emerCallPrio")) {
												if (defined $redrt{$sgrp}{'emerCallPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'emerCallPrio'}{$sredrtid});
												}
											} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redirectPrio")) {
												if (defined $redrt{$sgrp}{'redirectPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'redirectPrio'}{$sredrtid});
												}
											}				
										}
									}
								} else {
									print ("!!! No data REDRT available for xL20 template's LNCEL $sitename".'_'."$scellid RDRT- $sredrtid\n") ;
								}
							}
						}
					}
					
					#WNBTS/WNCEL wcdma obj
					foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
						$_ = $p->getAttribute("class");
						
						#
						if (/^com.nokia.srbts.wcdma:WNBTS/) {
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /\-(\d{6})\//) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}							
						} elsif (/^com.nokia.srbts.wcdma:WNCEL/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /\-(\d{6})\//) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}							
						}
						
					}
					
				
				} elsif ($sitedb{$sitename}{'swrel'} eq "FL19") {
					# update btsid
					foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
						#btsid in distName attribute obj
						$_ = $p->getAttribute("distName");
						if (/\-(\d{6})[\/]?/) {
							s/$1/$sitedb{$sitename}{'lnBtsId'}/g;
						}
						$p->setAttribute("distName",$_);
			
						#btsid in text obj
						$_ = $p->getAttribute("class");
						if ((/com.nokia.srbts.lte:MRBTS/) || (/com.nokia.srbts:MRBTS/)) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/btsName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									};
								}
							}
						} elsif (/^NOKLTE:LNBTS$/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/enbName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									}
								} # enable ANR - 3 parameters
								elsif (/actUeBasedAnrInterFreqLte/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									};
								}
								elsif (/actUeBasedAnrIntraFreqLte/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									};
								}
								elsif (/actUeBasedAnrUtran/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									};
								}									
							}
						} elsif (/com.nokia.srbts.eqm:SMOD/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/moduleLocation/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'Province'});
									}									
								}
							}
						} elsif (/com.nokia.srbts.tnl:TNL/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/userLabel/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($fltemplatedb{'userlabel'}{$rmtype});
									}	
								}
							}
						}
						elsif (/com.nokia.srbts.eqm:CABLINK/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/EndpointDN$/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/NOKLTE:TRSNW/) {
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/ipV4AddressDN1/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.mnl:CHANNEL/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/antlDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.mnl:MPLANENW/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/mPlaneIpv4AddressDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								} elsif (/oamPeerIpAddress/) {		#Here update oam server address since it under same obj as change btsid task
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($sitedb{$sitename}{'oamServerAddr'} =~ /\d+.\d+.\d+.\d+/) {
											$p1->removeChildNodes();
											$p1->appendText($sitedb{$sitename}{'oamServerAddr'});
										}
									}									
								}
							}
						} elsif (/com.nokia.srbts.mnl:CLOCK/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/sModDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.mnl:TOP/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/sPlaneIpAddressDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:ETHIF/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/linkSelectorDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:ETHLK/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/modDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:BRGPRT/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_= $p1->getAttribute("name"); 
								if (/ethlkDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:TWAMPREFLECT/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /\-(\d{6})\//) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}
						} elsif (/com.nokia.srbts.tnl:IPIF/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								if ($p1->nodeType == XML_ELEMENT_NODE) {
									$stext = $p1->findvalue('.');
									if ($stext =~ /\-(\d{6})\//) {
										$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
										$p1->removeChildNodes();
										$p1->appendText($stext);
									}
								}
							}
						}
					}
			
					#change local ipaddrs of vlanif 1&2 (class IPADDRESSV4)
					foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
						$_ = $p->getAttribute("class");
						if ((/com.nokia.srbts.tnl:IPADDRESSV4/) && (defined $sitedb{$sitename}{'localIpAddr1'}) && ($sitedb{$sitename}{'localIpAddr2'})) {
							$_ = $p->getAttribute("distName");
							if (/IPIF-1/) {
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "localIpAddr")) {
										$sipAddr = $p1->findvalue('.');
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr1'});
									} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "localIpPrefixLength")) {
										$stext = $p1->findvalue('.');
										my $netmask = $sitedb{$sitename}{'netMask1'};
										if ( $netmask =~ /\d+.\d+.\d+.\d+/) {
											if ($ipSlashform{$netmask} >= 1) {
												$p1->removeChildNodes();
												$p1->appendText($ipSlashform{$netmask});
											}
										}
									}
								}
							} elsif (/IPIF-2/) {
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "localIpAddr")) {
										$sipAddr = $p1->findvalue('.');
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr2'});
									} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "localIpPrefixLength")) {
										$stext = $p1->findvalue('.');
										my $netmask = $sitedb{$sitename}{'netMask2'};
										if ( $netmask =~ /\d+.\d+.\d+.\d+/) {
											if ($ipSlashform{$netmask} >= 1) {
												$p1->removeChildNodes();
												$p1->appendText($ipSlashform{$netmask});
											}
										}
									}
								}			
							}
						} elsif ((/com.nokia.srbts.tnl:VLANIF/) && (defined $sitedb{$sitename}{'localIpAddr1'}) && ($sitedb{$sitename}{'localIpAddr2'}) && ($sitedb{$sitename}{'vlanId1'}) && ($sitedb{$sitename}{'vlanId2'})) {
							$_ = $p->getAttribute("distName");
							if (/VLANIF-1/) {
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$svlan = $p1->findvalue('.');
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'vlanId1'});
									}
								}								
							} elsif (/VLANIF-2/) {
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$svlan = $p1->findvalue('.');
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'vlanId2'});
									}
								}								
							}
						
						} elsif ((/com.nokia.srbts.tnl:IPRT$/) && (defined $sitedb{$sitename}{'gateway1'}) && (defined $sitedb{$sitename}{'gateway2'})){ 
							my $defaultroute = FALSE;
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "destIpAddr")) {
									$_ = $p1->findvalue('.');  
									if (/0.0.0.0/) {
										$defaultroute = TRUE;	
									} else { 
										$defaultroute = FALSE; 
									}
								}
								elsif (($p1->nodeType == XML_ELEMENT_NODE) &&($p1->getAttribute("name") eq "gateway")) {
									$_ = $p1->findvalue('.');
									if ($defaultroute == TRUE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'gateway1'});			
									} elsif ($defaultroute == FALSE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'gateway2'});					
									}
									
								}						
							}
						} elsif ((/TOPF/) && (defined $sitedb{$sitename}{'topPrimary'}) && (defined $sitedb{$sitename}{'topSecondary'})) {
							my $topPrim = TRUE;
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "masterIpAddr")) {
									$_ = $p1->findvalue('.');  
									if ($topPrim == TRUE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'topPrimary'});
										$topPrim = FALSE;
									} else {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'topSecondary'});
									}
								}
							}					
						} 
						
					}
					
					
					# LNCEL parameters
					foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
						$_ = $p->getAttribute("class");
						
						#change p in class LNCEL_FDD			
						if (/^NOKLTE:LNCEL_FDD$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\//) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								if (defined $scellname) {
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "earfcnDL")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'earfcnDL'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "earfcnUL")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'earfcnUL'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "rootSeqIndex")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'rootSeqIndex'});						
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "dlChBw")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'dlChBw'});						
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "ulChBw")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'ulChBw'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumActUE")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumActUE'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumUeDl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumUeDl'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumUeUl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumUeUl'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "dlMimoMode")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'dlMimoMode'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "prachCS")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'prachCS'});					
										}
									}
								} else  {
									print ("!!! No data LNCEL_FDD available for FL19 template's LNCEL $sitename".'_'."$scellid \n") ;
								}
							}
						}
						
						#change p in class LNCEL
						elsif (/^NOKLTE:LNCEL$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)$/) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								if (defined $scellname) {
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "tac")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'tac'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "phyCellId")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'phyCellId'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redBwMaxRbDl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'redBwMaxRbDl'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redBwMaxRbUl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'redBwMaxRbUl'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "pMax")) {
											$p1->removeChildNodes();
											$p1->appendText(10*$celldb{$scellname}{'pMax'});				
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "cellName")) {
											$p1->removeChildNodes();
											$p1->appendText($scellname);				
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "expectedCellSize")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'expectedCellSize'});				
										}	
									}
								} else {
									print ("!!! No data LNCEL available for FL19 template's LNCEL $sitename".'_'."$scellid \n") ;
								}
							}
						} 
						
						#change p in class MPUCCH_FDD
						elsif (/^NOKLTE:MPUCCH_FDD$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\//) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								if (defined $scellname ) {
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumRrc")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumRrc'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumRrcEmergency")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumRrcEmergency'});					
										}				
									}
								} else {
									print ("!!! No data MPUCCH available for FL19 template's LNCEL $sitename".'_'."$scellid \n") ;
								}
							}
						}
						
						#change p in class REDRT
						elsif (/^NOKLTE:REDRT$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\/REDRT-(\d+)/) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								$sredrtid = $2;
								if (defined $scellname ) {
									if ((defined $celldb{$scellname}{'redrtGrp'}) && (defined $sredrtid)) {
										my $sgrp = $celldb{$scellname}{'redrtGrp'};
										foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
											if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "csFallBPrio")) {
												if (defined $redrt{$sgrp}{'csFallBPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'csFallBPrio'}{$sredrtid});
												}
											} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "emerCallPrio")) {
												if (defined $redrt{$sgrp}{'emerCallPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'emerCallPrio'}{$sredrtid});
												}
											} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redirectPrio")) {
												if (defined $redrt{$sgrp}{'redirectPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'redirectPrio'}{$sredrtid});
												}
											}				
										}
									}
								} else {
									print ("!!! No data REDRT available for FL19 template's LNCEL $sitename".'_'."$scellid RDRT- $sredrtid\n") ;
								}
							}
						}						
					}
				
				} elsif ($sitedb{$sitename}{'swrel'} eq "FL18") {
					foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
						$_ = $p->getAttribute("distName");
						if (/\-(\d{6})[\/]?/) {
							s/$1/$sitedb{$sitename}{'lnBtsId'}/g;
						}
						$p->setAttribute("distName",$_);
						
						$_ = $p->getAttribute("class");
						if (/com.nokia.mrbts:MRBTS/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/btsName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									};
								}
							}
						} elsif (/^NOKLTE:LNBTS$/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/enbName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									};
								} # enable ANR - 3 parameters
								elsif (/actUeBasedAnrInterFreqLte/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									};
								}
								elsif (/actUeBasedAnrIntraFreqLte/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									};
								}
								elsif (/actUeBasedAnrUtran/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									};
								}								
							}
						} elsif (/com.nokia.srbts.eqm:SMOD/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/moduleLocation/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'Province'});
									}									
								}
							}							
						} elsif (/^NOKLTE:FTM$/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/systemTitle/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									}
								} elsif (/userLabel/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
									$p1->appendText($fltemplatedb{'userlabel'}{$rmtype});
									}									
								} elsif (/locationName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
									$p1->appendText($sitedb{$sitename}{'Province'});
									}									
								}									
							}
						} elsif (/com.nokia.srbts.mnl:CLOCK/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/sModDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.eqmr:ANTL_R/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/configDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.eqmr:BBMOD_R/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/configDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.eqmr:CABINET_R/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/configDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								}
							}
						} elsif (/com.nokia.srbts.eqmr:CABLINK_R/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/configDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								} elsif (/firstEndpointDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}							
								} elsif (/secondEndpointDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}							
								}
							}
						} elsif (/com.nokia.srbts.eqm:CABLINK/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name"); 
								if (/firstEndpointDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								} elsif (/secondEndpointDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}							
								}
							}
						} elsif (/com.nokia.srbts.eqmr:RMOD_R/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/configDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								} elsif (/radioMasterDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}							
								} 
							}
						} elsif (/com.nokia.srbts.eqmr:SMOD_R/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/configDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								} 
							}
						} elsif (/com.nokia.srbts.eqmr:RSL_R/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/configDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								} 
							}
						} elsif (/com.nokia.srbts.mnl:BBPOOL/) {
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:p',$p)) {
								$_=$p1->getAttribute("name");
								#if (/bbPwrGroupDNList/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								#} 
							}
						} elsif (/com.nokia.srbts.mnl:CHANNEL/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/antlDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									}
								} 
							}
						} elsif ((/NOKLTE:IVIF/) && (defined $sitedb{$sitename}{'localIpAddr1'}) && ($sitedb{$sitename}{'localIpAddr2'})) {
							$_ = $p->getAttribute("distName");
							if (/IVIF-(\d)$/) {
								my $vlanif = $1;
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									$_=$p1->getAttribute("name");
									if (/localIpAddr/) {
										if ($p1->nodeType == XML_ELEMENT_NODE) {
											$p1->removeChildNodes();
											if ($vlanif == 1) {
												$p1->appendText($sitedb{$sitename}{'localIpAddr1'});
											} elsif ($vlanif == 2) {
												$p1->appendText($sitedb{$sitename}{'localIpAddr2'});
											}
										}											
									} elsif (/netmask/) {
										if ($p1->nodeType == XML_ELEMENT_NODE) {
											$p1->removeChildNodes();
											if ($vlanif == 1) {
												$p1->appendText($sitedb{$sitename}{'netMask1'});
											} elsif ($vlanif == 2) {
												$p1->appendText($sitedb{$sitename}{'netMask2'});
											}
										}											
									} elsif (/vlanId/) {
										if ((defined $sitedb{$sitename}{'vlanId1'}) && (defined $sitedb{$sitename}{'vlanId2'})) {
											if ($p1->nodeType == XML_ELEMENT_NODE) {
												$p1->removeChildNodes();
												if ($vlanif == 1) {
													$p1->appendText($sitedb{$sitename}{'vlanId1'});
												} elsif ($vlanif == 2) {
													$p1->appendText($sitedb{$sitename}{'vlanId2'});
												}
											}
										}										
									}
								}									
								
							}
						} elsif ((/NOKLTE:IPNO/) && (defined $sitedb{$sitename}{'localIpAddr1'}) && ($sitedb{$sitename}{'localIpAddr2'})) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/btsId/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'lnBtsId'});
									}								
								} elsif ((/mPlaneIpAddress/) || (/sPlaneIpAddress/)) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr2'});
									}						
								} elsif ((/cPlaneIpAddress$/) || (/uPlaneIpAddress/)) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr1'});
									}							
								}
							}
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/twampIpAddress/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr1'});
									}								
								}						
							}
						} elsif ((/IPRT/) && (defined $sitedb{$sitename}{'gateway1'}) && (defined $sitedb{$sitename}{'gateway2'})) {
							my $defaultroute = FALSE;
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "destIpAddr")) {
									$_ = $p1->findvalue('.');  
									if (/0.0.0.0/) {
										$defaultroute = TRUE;	
									} else { 
										$defaultroute = FALSE; 
									}
								}
								elsif (($p1->nodeType == XML_ELEMENT_NODE) &&($p1->getAttribute("name") eq "gateway")) {
									$_ = $p1->findvalue('.');
									if ($defaultroute == TRUE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'gateway1'});			
									} elsif ($defaultroute == FALSE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'gateway2'});					
									}
									
								}						
							}					
						} elsif ((/TOPF/) && (defined $sitedb{$sitename}{'topPrimary'}) && (defined $sitedb{$sitename}{'topSecondary'})) {
							my $topPrim = TRUE;
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "masterIpAddr")) {
									$_ = $p1->findvalue('.');  
									if ($topPrim == TRUE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'topPrimary'});
										$topPrim = FALSE;
									} else {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'topSecondary'});
									}
								}
							}					
						} elsif (/LNCEL/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\/*/) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								if (defined $scellname) {								
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "earfcnDL")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'earfcnDL'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "earfcnUL")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'earfcnUL'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "rootSeqIndex")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'rootSeqIndex'});						
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "dlChBw")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'dlChBw'});						
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "ulChBw")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'ulChBw'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumActUE")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumActUE'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumUeDl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumUeDl'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumUeUl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumUeUl'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "dlMimoMode")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'dlMimoMode'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "prachCS")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'prachCS'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "tac")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'tac'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "phyCellId")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'phyCellId'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redBwMaxRbDl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'redBwMaxRbDl'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redBwMaxRbUl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'redBwMaxRbUl'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "pMax")) {
											$p1->removeChildNodes();
											$p1->appendText(10*$celldb{$scellname}{'pMax'});				
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "cellName")) {
											$p1->removeChildNodes();
											$p1->appendText($scellname);				
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "expectedCellSize")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'expectedCellSize'});				
										}								
									}
								} else  {
									print ("!!! No data LNCEL available for FL18 template's LNCEL $sitename".'_'."$scellid \n") ;
								}								
							}						
						} elsif (/MPUCCH/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\//) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								if (defined $scellname ) {
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumRrc")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumRrc'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumRrcEmergency")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumRrcEmergency'});					
										}				
									}
								} else {
									print ("!!! No data MPUCCH available for FL18 template's LNCEL $sitename".'_'."$scellid \n") ;
								}
							}
						}
						
						#change p in class REDRT
						elsif (/^NOKLTE:REDRT$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\/REDRT-(\d+)/) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								$sredrtid = $2;
								if (defined $scellname ) {
									if ((defined $celldb{$scellname}{'redrtGrp'}) && (defined $sredrtid)) {
										my $sgrp = $celldb{$scellname}{'redrtGrp'};
										foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
											if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "csFallBPrio")) {
												if (defined $redrt{$sgrp}{'csFallBPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'csFallBPrio'}{$sredrtid});
												}
											} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "emerCallPrio")) {
												if (defined $redrt{$sgrp}{'emerCallPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'emerCallPrio'}{$sredrtid});
												}
											} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redirectPrio")) {
												if (defined $redrt{$sgrp}{'redirectPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'redirectPrio'}{$sredrtid});
												}
											}				
										}
									}
								} else {
									print ("!!! No data REDRT available for FL18 template's LNCEL $sitename".'_'."$scellid RDRT- $sredrtid\n") ;
								}
							}
						}						
					}
				} elsif ($sitedb{$sitename}{'swrel'} eq "FL16") {
					foreach my $p ($xpc->findnodes('/ns:raml/ns:cmData/ns:managedObject')) {
						$_ = $p->getAttribute("distName");
						if (/\-(\d{6})[\/]?/) {
							s/$1/$sitedb{$sitename}{'lnBtsId'}/g;
						}
						$p->setAttribute("distName",$_);
						
						$_ = $p->getAttribute("class");
						if (/^LNBTS$/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/enbName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									}
								} # enable ANR - 3 parameters
								elsif (/actUeBasedAnrInterFreqLte/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									}
								}
								elsif (/actUeBasedAnrIntraFreqLte/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									}
								}
								elsif (/actUeBasedAnrUtran/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText('true');
									}
								}
							}
						} elsif (/^SMOD$/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/moduleLocation/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'Province'});
									}									
								}
							}
						} elsif (/^FTM$/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/systemTitle/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									}
								} elsif (/userLabel/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
									$p1->appendText($fltemplatedb{'userlabel'}{$rmtype});
									}									
								} elsif (/locationName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
									$p1->appendText($sitedb{$sitename}{'Province'});
									}									
								}									
							}
						} elsif (/SFP/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/parentDN/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$stext = $p1->findvalue('.');
										if ($stext =~ /\-(\d{6})\//) {
											$stext =~ s/$1/$sitedb{$sitename}{'lnBtsId'}/;
											$p1->removeChildNodes();
											$p1->appendText($stext);
										}
									};
								}
							}
						} elsif (/BTSSCL/) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/btsId/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'lnBtsId'});
									}
								} elsif (/btsName/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitename);
									}						
								}
							}
						} elsif ((/IVIF/) && (defined $sitedb{$sitename}{'localIpAddr1'}) && (defined $sitedb{$sitename}{'localIpAddr2'})) {
							$_ = $p->getAttribute("distName");
							if (/IVIF-(\d)$/) {
								my $vlanif = $1;
								foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
									$_=$p1->getAttribute("name");
									if (/localIpAddr/) {
										if ($p1->nodeType == XML_ELEMENT_NODE) {
											$p1->removeChildNodes();
											if ($vlanif == 1) {
												$p1->appendText($sitedb{$sitename}{'localIpAddr1'});
											} elsif ($vlanif == 2) {
												$p1->appendText($sitedb{$sitename}{'localIpAddr2'});
											}
										}											
									} elsif (/netmask/) {
										if ($p1->nodeType == XML_ELEMENT_NODE) {
											$p1->removeChildNodes();
											if ($vlanif == 1) {
												$p1->appendText($sitedb{$sitename}{'netMask1'});
											} elsif ($vlanif == 2) {
												$p1->appendText($sitedb{$sitename}{'netMask2'});
											}
										}											
									} elsif (/vlanId/) {
										if ((defined $sitedb{$sitename}{'vlanId1'}) && (defined $sitedb{$sitename}{'vlanId2'})) {
											if ($p1->nodeType == XML_ELEMENT_NODE) {
												$p1->removeChildNodes();
												if ($vlanif == 1) {
													$p1->appendText($sitedb{$sitename}{'vlanId1'});
												} elsif ($vlanif == 2) {
													$p1->appendText($sitedb{$sitename}{'vlanId2'});
												}
											}
										}										
									}
								}									
								
							}
						} elsif ((/IPNO/) && (defined $sitedb{$sitename}{'localIpAddr1'}) && ($sitedb{$sitename}{'localIpAddr2'})) {
							foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/btsId/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'lnBtsId'});
									}								
								} elsif ((/mPlaneIpAddress/) || (/sPlaneIpAddress/)) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr2'});
									}						
								} elsif ((/cPlaneIpAddress$/) || (/uPlaneIpAddress/)) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr1'});
									}							
								}
							}
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								$_=$p1->getAttribute("name");
								if (/twampIpAddress/) {
									if ($p1->nodeType == XML_ELEMENT_NODE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'localIpAddr1'});
									}								
								}						
							}
						} elsif ((/IPRT/) && (defined $sitedb{$sitename}{'gateway1'}) && (defined $sitedb{$sitename}{'gateway2'})) {
							my $defaultroute = FALSE;
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "destIpAddr")) {
									$_ = $p1->findvalue('.');  
									if (/0.0.0.0/) {
										$defaultroute = TRUE;	
									} else { 
										$defaultroute = FALSE; 
									}
								}
								elsif (($p1->nodeType == XML_ELEMENT_NODE) &&($p1->getAttribute("name") eq "gateway")) {
									$_ = $p1->findvalue('.');
									if ($defaultroute == TRUE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'gateway1'});			
									} elsif ($defaultroute == FALSE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'gateway2'});					
									}
									
								}						
							}					
						} elsif ((/TOPF/) && (defined $sitedb{$sitename}{'topPrimary'}) && (defined $sitedb{$sitename}{'topSecondary'})) {
							my $topPrim = TRUE;
							foreach my $p1 ($xpc->findnodes('./ns:list/ns:item/ns:p[@name]',$p)) {
								if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "masterIpAddr")) {
									$_ = $p1->findvalue('.');  
									if ($topPrim == TRUE) {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'topPrimary'});
										$topPrim = FALSE;
									} else {
										$p1->removeChildNodes();
										$p1->appendText($sitedb{$sitename}{'topSecondary'});
									}
								}
							}					
						} elsif (/LNCEL/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)/) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								if (defined $scellname) {
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "earfcnDL")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'earfcnDL'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "earfcnUL")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'earfcnUL'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "rootSeqIndex")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'rootSeqIndex'});						
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "dlChBw")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'dlChBw'});						
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "ulChBw")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'ulChBw'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumActUE")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumActUE'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumUeDl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumUeDl'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumUeUl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumUeUl'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "dlMimoMode")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'dlMimoMode'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "prachCS")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'prachCS'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "tac")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'tac'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "phyCellId")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'phyCellId'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redBwMaxRbDl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'redBwMaxRbDl'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redBwMaxRbUl")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'redBwMaxRbUl'});					
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "pMax")) {
											$p1->removeChildNodes();
											$p1->appendText(10*$celldb{$scellname}{'pMax'});				
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "cellName")) {
											$p1->removeChildNodes();
											$p1->appendText($scellname);				
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "expectedCellSize")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'expectedCellSize'});				
										}								
									}
								} else  {
									print ("!!! No data LNCEL available for FL16 template's LNCEL $sitename".'_'."$scellid \n") ;
								}								
							}						
						} elsif (/MPUCCH/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)/) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								if (defined $scellname ) {
									foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
										if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumRrc")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumRrc'});
										} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "maxNumRrcEmergency")) {
											$p1->removeChildNodes();
											$p1->appendText($celldb{$scellname}{'maxNumRrcEmergency'});					
										}				
									}
								} else {
									print ("!!! No data MPUCCH available for FL16 template's LNCEL $sitename".'_'."$scellid \n") ;
								}
							}
						}
						
						#change p in class REDRT
						elsif (/^REDRT$/) {
							$_ = $p->getAttribute("distName");
							if (/LNCEL-(\d\d)\/REDRT-(\d+)/) {
								$scellid = $1;
								$scellname = $sitemap{$sitename}{$scellid};
								$sredrtid = $2;
								if (defined $scellname ) {
									if ((defined $celldb{$scellname}{'redrtGrp'}) && (defined $sredrtid)) {
										my $sgrp = $celldb{$scellname}{'redrtGrp'};
										foreach my $p1 ($xpc->findnodes('./ns:p[@name]',$p)) {
											if (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "csFallBPrio")) {
												if (defined $redrt{$sgrp}{'csFallBPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'csFallBPrio'}{$sredrtid});
												}
											} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "emerCallPrio")) {
												if (defined $redrt{$sgrp}{'emerCallPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'emerCallPrio'}{$sredrtid});
												}
											} elsif (($p1->nodeType == XML_ELEMENT_NODE) && ($p1->getAttribute("name") eq "redirectPrio")) {
												if (defined $redrt{$sgrp}{'redirectPrio'}{$sredrtid}) {
													$p1->removeChildNodes();
													$p1->appendText($redrt{$sgrp}{'redirectPrio'}{$sredrtid});
												}
											}				
										}
									}
								} else {
									print ("!!! No data REDRT available for FL16 template's LNCEL $sitename".'_'."$scellid RDRT- $sredrtid\n") ;
								}
							}
						}						
					}
				}
				open my $out, '>', "scf_$sitename.xml";
				binmode $out; 
				print {$out} $dom->toString();			
			} else {
				print ">>> $sitename : \($rmtype + $swrel\) not supported !!!\n";
			}	
	
		}
	}
}


############################
sub ExtractFileAndSwitchList
############################
{
   $j=0;$k=0;
   $HelpSwitch    = 0;
   $VersionSwitch = 0;
   
   for (my $i=0; $i<=$#ARGV; $i++)
   {	
      if ($ARGV[$i] =~ m/^-/)
      {
         $switchList[$k++] = $ARGV[$i];
      }
      else
      {
         $inputFileArrayA[$j++] = $ARGV[$i];
      }
   }
   if ($#switchList != -1)
   {
      for ($i=0; $i<=$#switchList; $i++)
      {
         if ($switchList[$i] =~ /-v/)
         {
            $VersionSwitch = 1;
         }
         elsif ($switchList[$i] =~ /-h/)
         {
            $HelpSwitch = 1;
         }
         elsif ($switchList[$i] =~ /-d=(.*)/)
         {	if ( -e $1 ) {$outDir = $1; if ($outDir !~ /\\$/) {$outDir .= "\\";}}
         		else {print "The directory is not exist. Using default output directory ...\n";}
            
         }
		 elsif ($switchList[$i] =~ /-r/) {
			$genTemplate = TRUE; 
		 }
        else
        {
          print ("Invalid option ! ! !\n");
          eval $Usage;
          print "For more help enter \"$0 -h\"\n";
     			exit;
        }
      }
   }

	if (($#inputFileArrayA == -1) &&
	    (! $VersionSwitch) &&
	    (! $HelpSwitch))
	{
		eval $Usage;
		print "For more help enter \"$0 -h\"\n";
	}
	else {
		$#inputFileArray =-1;
		for ($i=0; $i <= $#inputFileArrayA; $i++)
		{
			if ($inputFileArrayA[$i] =~ /(.*)\\(.*)$/){
				chdir $1 || die print "Folder $1 not exist\n";
			}
			@fileA =  <$inputFileArrayA[$i]>;
			if ($#fileA == -1){
				print "File \"$inputFileArrayA[$i]\" not found\n";
			 	exit;
			 }
			foreach $file (<$inputFileArrayA[$i]>) {
				@inputFileArray =  (@inputFileArray, $file);
			}
		}

    for ($i=0; $i <= $#inputFileArray; $i++)
    {
    	if (! -e $inputFileArray[$i])
    	{
      	print "File \"$inputFileArray[$i]\" not found\n";
      	exit;
    	}
		}
	}
}

############################
sub PrintHelp
############################
{	
	
	print "\r\n\n";
	print "*=========================================================================\r\n";
	print "*Program generating xml commissioning file\r\n";
	print "*\/*Version 20210801*\/\r\n";
	print "*Usage:	perl $0 -[hvrd] filenames\r\n";
	print "\t-h\tUsage guidelines\r\n";
	print "\t-v\tDevelopment version\r\n";
	print "\t-r\tGenerate template files\r\n";
	print "\t-d\tOutput directory - without space in dir's path\r\n";
	print "\r\nExamples:> perl XMLgen.pl D:\\data\\lnbts.csv D:\\data\\lncel.csv D:\\data\\scf_config_template.xml\r\n";
	print "\t > perl XMLgen.pl -r D:\\data\\Comm_scf.xml \r\n";
	print "*=========================================================================\r\n";
}	