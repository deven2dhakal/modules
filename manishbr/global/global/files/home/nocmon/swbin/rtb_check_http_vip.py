#pass in the node to query when calling the file
#ex: python rtb_external_http_vip_check.py iad01

import httplib
import sys

def get_status_code(host, path="/"):
    try:
        conn = httplib.HTTPConnection(host)
        conn.request("HEAD", path)
        return conn.getresponse().status
    except StandardError:
        return 0

hostname = str(sys.argv[1])+"-rtb.dotomi.com"
result = get_status_code(hostname)
resultCode = 0

if(str(result)=="404"):
	resultCode=1

if(result != 0):
	print "Message.Status: "+hostname+" is returning a status code of "+str(result)
	print "Statistic.Status: "+str(resultCode)
else:
	print "Message.Status: "+hostname+" is returning an unknown status code"
	print "Statistic.Status: "+str(resultCode)

#print get_status_code("iad01-rtb.dotomi.com")
