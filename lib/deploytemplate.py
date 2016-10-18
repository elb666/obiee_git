import sys
import os

weblogic_url = '%WEBLOGIC_URL%' 
rpd = '%RPD%'
rpd_password = '%RPD_PASSWORD%'

# Connect to WebLogic. 
# If WebLogicConfig.properties and WebLogicKey.properties are not configured,
#+then user will be prompted for WebLogic user and password
connect( url= weblogic_url )

# Switch to custom MBean tree
domainCustom()

# Get lock
print "Getting lock"
cd('oracle.biee.admin')
cd('oracle.biee.admin:type=BIDomain,group=Service')
objs=jarray.array([], java.lang.Object)
strs=jarray.array([], java.lang.String)
invoke('lock', objs, strs)

# Deploy RPD
print "Deploying RPD"
try:
	cd('..')
	cd('oracle.biee.admin:type=BIDomain.BIInstance.ServerConfiguration,biInstance=coreapplication,group=Service')
	objs = jarray.array([rpd,rpd_password],java.lang.Object)
	strs = jarray.array(['java.lang.String', 'java.lang.String'],java.lang.String)
	invoke( 'uploadRepository', objs, strs)

except:
	cd ('..')
	cd ('oracle.biee.admin:type=BIDomain,group=Service')
	print "Error::", sys.exc_info()[0]
	objs = jarray.array([], java.lang.Object)
	strs = jarray.array([], java.lang.String)
	invoke('rollback', objs, strs)
	print "Rolled back"
	raise

# Commit changes
print "Committing changes"
cd('..')
cd('oracle.biee.admin:type=BIDomain,group=Service')
objs = jarray.array([], java.lang.Object)
strs = jarray.array([], java.lang.String)
invoke('commit', objs, strs)

# Restart BI server
print "Restarting BI server:"
cd('..')
cd ('oracle.biee.admin:oracleInstance=instance1,type=BIDomain.BIInstanceDeployment.BIComponent,biInstance=coreapplication,process=coreapplication_obis1,group=Service')
objs = jarray.array([], java.lang.Object)
strs = jarray.array([], java.lang.String)
print "    Stopping BI server"
invoke('stop', objs, strs)
try:
	print "    Starting BI server"
	invoke('start', objs, strs)
except:
	print "Error:", sys.exc_info()[0]
	print "NOTE: Restarting BI Server may fail if the RPD password was entered incorrectly"
	raise

exit()
