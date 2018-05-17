#!/bin/bash

###########################################################
# This is part 2 of the 4.2.28 FULL installer.
# End=sure these environment variables are the same as 
# in script 1
###########################################################

export FNAME='Development Server'
export MYFQDN='dev4.trymsys.net'
export USERNAME='Tom Mairs'
export EMAIL='tom.mairs@sparkpost.com'
export TZ='MST'
export DEFAULT=/opt/msys/ecelerity/etc/conf/default/
export MOMOVER1="momentum-bundle-4.2.1.56364.rhel6.x86_64.tar.gz"
export MOMOVER2="momentum-bundle-4.2.28.58446.rhel6.x86_64.tar.gz"
export MOMOREL1="momentum-4.2.1.56364"
export MOMOREL2="momentum-4.2.28.58446"


 sed -i 's/cassandra_client {/cassandra_native_client {/' /opt/msys/ecelerity/etc/conf/default/msg_gen.conf  
 sed -i 's/uri = (/contact_points = (/' /opt/msys/ecelerity/etc/conf/default/msg_gen.conf  
 sed -i 's/"name=(.*)9160"/<FQDN>/' /opt/msys/ecelerity/etc/conf/default/msg_gen.conf 


 /opt/msys/ecelerity/bin/cassandra_momo_setup.sh --multinode /opt/msys/ecelerity/etc

service eccmgr start
service ecconfigd start
service msys-riak start
service msys-cassandra start
service msc_server start
service msys-rabbitmq start
service msys-vertica start
#service msys-app-metrics-etl stop
#service msys-app-adaptive-delivery-etl stop
#service msys-app-webhooks-batch stop
#service msys-app-webhooks-transmitter stop
service ecelerity start
service msys-nginx start
service msys-app-metrics-api start
service msys-app-adaptive-delivery-api start
service msys-app-users-api start
service msys-app-webhooks-api start




########################################################
# END of Momentum install and upgrade
########################################################



###########################################################
# These are custom for the SETEAM install
###########################################################

# To label the server with a descriptive and helpful MOTD
# Edit as needed for this install

echo "








##############################################

Welcome to the $FNAME server 
[ https://$MYFQDN ]

Hosting Momentum $MOMOREL2 FULL DEPLOY

 - for any questions, please contact
$USERNAME <$EMAIL>

##############################################
" > /etc/motd

echo "
echo \"version\" |/opt/msys/ecelerity/bin/ec_console
echo " > /etc/motd.sh

echo "sh /etc/motd.sh" >> /etc/profile



#######################################################################################
#
# WARNING 
#
# This following section is to give users server access
# You may want to edit this section before running the script
#
#######################################################################################
# to give seteam users sudo access to the server
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config   
echo "seteam        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
service sshd restart

useradd seteam
passwd seteam
#######################################################################################
#######################################################################################


#######################################################################################
#
# WARNING 
#
# This following section generates and alters system configuration
# You may want to edit this section before running the script
#
#######################################################################################


mkdir $DEFAULT/lua
mkdir $DEFAULT/conf.d


#################################
# FBL Config
#################################
echo "
Enable_FBL_Header_Insertion = enabled

fbl {
  Auto_Log = true # default is \"false\"
  Log_Path = \"jlog:///var/log/ecelerity/fbllog.jlog=>master\"
  Addresses = ( \"^.*@fbl.$MYFQDN\" ) # default is unset
  Header_Name = \"X-MSFBL\" # this is the default
#  User_String = \"%{vctx_mess:my_context_variable}\" # default is unset
  Message_Disposition = \"pass\" # default is blackhole, also allowed to set to \"pass\"
#  Condition = \"can_relay\" # default is unset, should be name of a vctx entry
}
" > $DEFAULT/conf.d/fbl.conf


#################################
# DKIM Config
#################################
echo "
opendkim_sign = \"enabled\"

opendkim \"opendkim1\" {
  header_canon = \"relaxed\"
  body_canon = \"relaxed\"
  headerlist = (\"from\", \"to\", \"message-id\", \"date\", \"subject\", \"Content-Type\")
  digest = \"rsa-sha256\"
  key = \"/opt/msys/ecelerity/etc/conf/default/dk/%{d}/%{s}.key\"
  dkim_domain \"$MYFQDN\" {
    selector = \"s1024\"
  }

}
" > $DEFAULT/conf.d/dkim.conf



#################################
# ADAPTIVE Config
#################################
echo "
adaptive_enabled = true
adaptive_notification_interval = 5
adaptive_adjustment_interval = 10

adaptive  {
  suspend_sweep_interval = 5
  operational_log_level = \"debug\"
  jlog_file = \"jlog:///var/log/ecelerity/adaptive.rt=>ad_stats\"
  enable_jlog = true
}

alerting {}

scriptlet \"scriptlet\" {
  # Add the Lua adaptive script
  script \"adaptive\" {
    source = \"msys.adaptive\"
  }
}

inbound_audit {
  monitors = (\"300,6\")
}" > $DEFAULT/conf.d/adaptive.conf



#################################
# BINDING Config
#################################
echo "
binding_group general {

  binding \"generic\" {
  }
  binding \"marketing\" {
  }
  binding \"news\" {
  }
  binding \"trans\" {
  }
  binding \"msys\" {
  }
}
" > $DEFAULT/conf.d/bindings.conf


#################################
# General ecelerity config
#################################
sed -i 's/Bounce_Domains /#Bounce_Domains /' $DEFAULT/ecelerity.conf
sed -i 's/Bounce_Behavior /#Bounce_Behavior /' $DEFAULT/ecelerity.conf
sed -i 's/Generate_bounces /#Generate_bounces /' $DEFAULT/ecelerity.conf
echo "include \"conf.d\"" >> $DEFAULT/ecelerity.conf

echo "
#
# Additional ecelerity mods to add.  Remember to INCLUDE this file in ecelerity.conf
#

Bounce_Domains = (\"*.$MYFQDN\")
Bounce_Behavior = blackhole
Generate_bounces = false

scriptlet \"scriptlet\" {
  script \"policy\" {
    source = \"$DEFAULT/lua/policy.lua\"
  }
}

eventloop \"pool\" {
concurrency = 4
}

delivery_pool = \"pool\"
maintainer_pool = \"pool\"


#smtpapi{}

ESMTP_Listener{
  Listen \":587\" {
    Enable = true
    TLS_Verify_Mode = \"require\"
    TLS_Certificate = \"/etc/pki/tls/certs/server.crt\"
    TLS_Key = \"/etc/pki/tls/certs/server.key\"
    TLS_Client_CA = \"/etc/pki/tls/certs/server.crt\"
    TLS_Ciphers = \"DEFAULT\"
    AuthLoginParameters = [
       uri = \"file:///opt/msys/ecelerity/etc/unsafe_passwd\"
    ]
    SMTP_Extensions = ( \"ENHANCEDSTATUSCODES\" \"STARTTLS\" \"AUTH LOGIN\" )
#    tracking_domain = \"$MYFQDN:81\"
  }
}

#tls_macros {}


" > $DEFAULT/conf.d/ecelerity_mods.conf



#################################
# Mobile Config
#################################
echo "
smpp_logger \"smpp_logger\"
{
  logfile = \"/var/log/ecelerity/smpplog.ec\"
  logmode = 0644
  log_reception_format = \"%t@R@%m@%s@%d@%q@%bg@%b@%ip@%l\"
  log_permfail_format = \"%t@P@%m@%s@%d@%q@%bg@%b@%ip@%e\"
  log_delivery_format = \"%t@D@%m@%s@%d@%q@%bg@%b@%ip@%l@%rm\"
  log_tempfail = false
  log_status = false
}

#Datasource \"ram\" {
#  uri = ( \"pgsql:host=localhost;dbname=ecelerity;user=ecuser;password=123456\")
#  no_cache = \"true\"
#}

smpp {
   debug_level=debug
}


#domain mblox.sms.agg {
#  SMPP_SMSC_Server = \"smpp.mt.us.mblox.com\"
#  SMPP_SMSC_Port = \"3210\"
#  SMPP_SMSC_System_ID = \"<redacted>\"
#  SMPP_SMSC_Password = \"<redacted>\"
#  SMPP_ESME_Address = \"<redacted>\"
#  SMPP_Default_Email_Address = \"<redacted>\"
#  SMPP_Registered_Delivery = (SMSC_Delivery)
#  SMPP_Max_Sms_Subject_Size = \"0\"
#  SMPP_ESME_Service_Type = \"32538\"
#  SMPP_SMS_Data_Coding = \"ascii\"
#  SMPP_Inactivity_Timer = 600
#  SMPP_Enquire_Link_Timer = 90
#  SMPP_Response_Timer = 60
#}
" > $DEFAULT/conf.d/mobile.conf


#################################
# Lua Policy
#################################
echo "
require(\"msys.core\");
require(\"msys.db\");
require(\"msys.pcre\");
require(\"msys.dumper\");
require(\"msys.extended.message\");
require(\"msys.extended.message_routing\");
require(\"msys.extended.ac\");

local mod = {};

--[[ Modify these as necessesary for your demo ]]--
local sinkdomain = \"54.244.3.35\"
local safedomains = { \"mblox.sms.agg\", \"validator.messagesystems.com\", \"messagesystems.com\", \"sparkpost.com\" }

--[[ each rcpt_to function ]]--
function mod:validate_data_spool_each_rcpt (msg, accept, vctx)
--  print (\"Using data_spool_each_rcpt\");
  return msys.core.VALIDATE_CONT;
end 


--[[ each MSG_GEN rcpt_to function ]]--
function mod:msg_gen_data_spool(msg)
--  print (\"Using msg_gen_data_spool\");
  return msys.core.VALIDATE_CONT;
end


--[[ Set Binding function ]]--
function mod:validate_set_binding(msg)
  local domain_str = msys.core.string_new();
  local localpart_str = msys.core.string_new();
  msg:get_envelope2(msys.core.EC_MSG_ENV_TO, localpart_str, domain_str);
  local mydomain = tostring(domain_str);
  local mylocalpart = tostring(localpart_str);
  local validdomain = \"false\"
  local bindingname = msg:header(\"X-Binding\")

  if bindingname[1] then 
    msg:context_set(msys.core.VCTX_MESS, \"mo_binding\", bindingname[1])
  end


-- Test to see if the TO domain is in the safe list
  for i,v in ipairs(safedomains) do
    if v == mydomain then
    --  print (\"Routing to a valid domain: \" .. mydomain);
      validdomain = \"true\"
      break
   end
  end

  if validdomain == \"false\" then

  --  print (\"Sending this to sink: \" .. sinkdomain .. \" / \" .. mydomain);
    msg:routing_domain(sinkdomain);
  end
    if ( ( bindingname[1] ~= \"\" ) and (bindingname[1] ~= nil ) )  then
      local err = msg:binding(bindingname[1]);
    else 
      local err = msg:binding(\"generic\");
    end


-- print(msg:context_get(msys.core.ECMESS_CTX_MESS, 'mo_campaign_id'));

  return msys.core.VALIDATE_CONT;
end;

msys.registerModule(\"policy\", mod);
" > $DEFAULT/lua/policy.lua


#######################################
# Commit and restart
#######################################
chown ecuser.ecuser $DEFAULT/* -R
service ecelerity restart

echo 
echo 
echo "Installation complete!"
echo 
echo 
cat /etc/motd
sh /etc/motd.sh


