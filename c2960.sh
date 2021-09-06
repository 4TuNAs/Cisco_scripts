#!/bin/sh

#kepperwork@gmail.com 2021 
#This script worked with all switch Cisco Catalyst WS-C2960
#to use we need to create file switch.txt and paste ip who need to update
#you need change rw polici on switch and change it on script, and change tftp server
# snmpset -c private (snmp comunity wr) -v2c $LINE  .1.3.6.1.4.1.9.2.10.12.10.127.0.110 c2960-lanbasek9-mz.150-2.SE11.bin    10.127.0.110 -> tftp server c2960-lanbasek9-mz.150-2.SE11.bin  -> name firmware

(echo "Hostname; Swithch IP; Switch Model; Switch Version; Free Space; Firmware Update State";) > fdone.csv
(while read LINE
do
i=0					    			 #var to csv
        old(){		
		 if [ "$flash" -lt 12000000 ] ; then
		 	echo "$LINE Non free space"
			i=3
		 else																												  #function to use witch 2960-24/48p
                        echo "Server send command to download firmware on $LINE Old switch"
                        snmpset -c veralot -v2c $LINE  .1.3.6.1.4.1.9.2.10.12.10.127.0.110 s c2960-lanbasek9-mz.150-2.SE11.bin    #send packet to dowload tftp file
                        i=1          #var to csv
		 fi
}
        new_ll(){																													  #function to use witch Lan Lite 2960+24/48p
                if [ "$sw_f_ver" = " Version 15.2(2)E8" ] ; then
                                echo "$LINE has last firmware version"
                        i=0          #var to csv
                else
		if [ "$flash" -lt 13000000 ] ; then
			echo "$LINE Non free space"
                        i=3
			else
                        echo "Server send command to download firmware on $LINE to Lan Lite" 										  
                        snmpset -c veralot -v2c $LINE  .1.3.6.1.4.1.9.2.10.12.10.127.0.110 s c2960-lanlitek9-mz.152-2.E8.bin  	  #send packet to dowload tftp file
                
		        i=1
			fi			 #var to csv
                fi
}
        new_lb(){																													  #function to use witch Lan Lite 2960+24/48p
                if [ "$sw_f_ver" = " Version 15.2(2)E8" ] ; then
                                echo "$LINE has last firmware version"
                        i=0			 #var to csv
                else
			if [ "$flash" -lt 13000000 ] ; then
                        echo "$LINE Non free space"
                        i=3
                        else
                        echo "Server send command to download firmware on $LINE to Lan Base"
                        snmpset -c veralot -v2c $LINE  .1.3.6.1.4.1.9.2.10.12.10.127.0.110 s c2960-lanbasek9-mz.152-2.E8.bin    #send packet to dowload tftp file
                        i=1          #var to csv
			fi
                fi
}


        get_info=`snmpwalk -O Uqv -v2c -c private $LINE 1.3.6.1.4.1.9.9.25.1.1.1.2.7`              #get info out switch
        switch_model=`snmpwalk -O Uqv -v2c -c private $LINE SNMPv2-SMI::mib-2.47.1.1.1.1.13.1001`  #get switch model
        switch_hostname=`snmpwalk -v2c -OqvU -c private $LINE 1.3.6.1.4.1.9.2.1.3.0`
	flash=`snmpwalk -O Uqv -v2c -c private $LINE SNMPv2-SMI::enterprises.9.9.10.1.1.4.1.1.5.1.1`		

        sw_f_ver=`echo "$get_info" | awk -F ',' '{print $3}' OFS=','`                              #switch firmware version
        sw_mod=`echo "$switch_model" | awk -F '"' '{print $2}' OFS='"'`				   #switch model 
        sw_hostname=`echo "$switch_hostname" | awk -F '"' '{print $2}' OFS='"'`			   #switch hostname

        echo " "
	echo "$flash"											   #informational debug to info.log
        echo "$sw_hostname"										   #informational debug to info.log
        echo "$sw_mod"											   #informational debug to info.log
        echo $sw_f_ver											   #informational debug to info.log
                  if [ "$sw_f_ver" = " Version 15.0(2)SE11" ] ; then					   #block to change switch version
                         echo "$LINE has last firmware version"

                  elif [ "$sw_mod" = "WS-C2960+24LC-L" ] ; then
                          new_lb
                  elif [ "$sw_mod" = "WS-C2960+24LC-S" ] ; then
                          new_ll
                  elif [ "$sw_mod" = "WS-C2960+24PC-L" ] ; then
                             new_lb
                  elif [ "$sw_mod" = "WS-C2960+24PC-S" ] ; then
                          new_ll
                  elif [ "$sw_mod" = "WS-C2960+24TC-L" ] ; then
                             new_lb
                  elif [ "$sw_mod" = "WS-C2960+24TC-S" ] ; then
                          new_ll
                  elif [ "$sw_mod" = "WS-C2960+48PST-L" ] ; then
                             new_lb
                  elif [ "$sw_mod" = "WS-C2960+48PST-S" ] ; then
                          new_ll
                  elif [ "$sw_mod" = "WS-C2960+48TC-L" ] ; then
                             new_lb
                  elif [ "$sw_mod" = "WS-C2960+48TC-S" ] ; then
                          new_ll
				  elif [ "$sw_mod" = "WS-C2960-24TC-S" ] ; then
                          i=4
                  elif [ "$sw_mod" = "" ] ; then
                          i=2
                  else
                         i=1
                         old
                  fi
	
	out=''           #var to csv
		if [ "$i" = "1" ] ; then                         #block to formate csv file
				out="switch_download_firmware"
				m=$(( $m + 1 ))
		elif [ "$i" = "0" ] ; then
				out="Updated_now"
				x=$(( $x + 1 ))
		elif [ "$i" = "2" ] ; then
				out="Unreacheble"
		elif [ "$i" = "3" ] ; then
				m=$(( $m + 1 ))
                                out="Non free space"
		elif [ "$i" = "4" ] ; then
                                out="Haven't firmware"
				z=$(( $z + 1 ))
		else
				out="fail"
		fi

    (echo "$m, $x, $z") > switch.count.txt
    
    (echo "$sw_hostname; $LINE; $sw_mod; $sw_f_ver; $flash; $out";) >> fdone.csv     #formate csv file
  

done < switches.txt )  > info.log  #get info with switches.txt and write log to info log

	sort fdone.csv > done.csv				#sort csv
	rm fdone.csv						#rm unsorted file
	echo "end"						#echo about end script
	switch_count=`cat switch.count.txt`
	rm switch.count.txt
	need=`echo "$switch_count" | awk  -F ','  '{print $1}' OFS=','`
	updated=`echo "$switch_count" | awk  -F ',' '{print $2}' OFS=','`
	hate=`echo "$switch_count" | awk '{print $3}' OFS=','`
	if [ "$need" = "" ] ; then
		$need='0'
	fi
	echo "Need to update: $need"
	echo "Updated now: $updated"
	echo "Haven't firmware: $hate"
