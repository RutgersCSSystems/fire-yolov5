import xml.etree.ElementTree as ET
import subprocess
import os, datetime
import re
from subprocess import Popen, PIPE

APPBENCH=os.environ['APPBENCH']
APP=APPBENCH + "/runapps.sh"
SCRIPTS=os.environ['SCRIPTS']
INFILE=os.environ['INPUTXML']
QUARTZ=os.environ['QUARTZ']
OUTDIR=os.environ['OUTPUTDIR']
tree = ET.parse(INFILE)
root = tree.getroot()

def setup():
    os.system("scripts/set_appbench.sh")

def makedb():
    os.chdir(APPBENCH)
    #os.system("make -j4")
    os.chdir(APPBENCH)
    APP = APPBENCH + "/runapps.sh"


def throttle(membw):
    print "throttling bandwidth to: " + str(membw)
    CMD1 = "sed -i '/read =/c    read =" + str(membw) + "'" + " " +  QUARTZ + "/" + "nvmemul.ini"
    CMD2 = "sed -i '/write =/c   write =" + str(membw) + "'" + " " +  QUARTZ + "/" + "nvmemul.ini"
    os.system(CMD1)
    os.system(CMD2)
    os.system(APPBENCH + "/throttle.sh")

def cleandb():
    print "starting tests"
    #os.system()    


class prettyfloat(float):
    def __repr__(self):
        return "%0.2f" % self


class stats(object):
  
  def __init__(self):
      self.init = 1


  def print_bwlat(self, header, bwidth_set, lat_set, f):
      print "****************************"
      print "Header size " + str(header)
      print "[%s]"%", ".join(map(str,bwidth_set))
      print "[%s]"%", ".join(map(str,lat_set))
      f.write("[%s]\n"%", ".join(map(str,bwidth_set)))
      f.write("[%s]\n"%", ".join(map(str,lat_set)))
      print "****************************\n"
      f.write("\n");


class system(object):

  def __init__(self):
      self.init = 1
      self.diskspace = 0
      self.system_schema = root.find('./system-main')


  def cleandb(self):
     os.system("")    

  def set_dbdir(self):
      self.dbdir = self.system_schema.find('dbdir').text
      os.environ['TEST_TMPDIR'] = self.dbdir
      print "Database in " + self.dbdir


  def get_diskspace(self, root):
      system_schema = root.find('./system-main')
      partition = system_schema.find('partition').text 
      s = os.statvfs(partition) 
      self.diskspace = (s.f_bavail * s.f_frsize)
      return self.diskspace


  def fitto_diskspace(self, elements, key, value, logspace):  
      usage = ((value + key) * elements) + logspace
      if( usage > self.diskspace):     
          diff = usage - self.diskspace 
          maxele = elements - (diff/(key+value))
          return maxele 
      else:
          return elements


############# Check the tests that are enabled #############

class ParamTest:

    seed_count = 0
    num_tests = 0
    membw = 0
    
    output = " "    
    resarr = []    
    xincr = 0
    xmanual = []
    xlegend = []

    #def __init__(self):

    def setvals(self, params):    

        self.seed_count = params.find('seed-count').text
        self.num_tests = params.find('num-tests').text
        self.membw = params.find('membw').text

        self.membw_str = str(self.membw);
        self.xincr = int(self.seed_count)


    def runapp(self, APP, index):

        i = 0
        x_values = []

	#Clean the exisiting database; we don't want to read old database
	cleandb();
	print APP +" "+ self.membw_str 

	process = Popen([APP, self.membw_str], \
		  stdout=PIPE)
	(self.output, err) = process.communicate()
	exit_code = process.wait()
        print self.output

	"""
	for line in self.output.splitlines():
	    if re.search(str(benchmarks[0]), line):
		my_set = line.split();
		if my_set[0] in benchmarks:
		    print  my_set[2] + "\t" +  my_set[4]
	    i = i + 1
        """

    # Vary num elements (keys) from base num-elements to num-elements * 2 * num_tests
    def run_membw_test(self, params):

        count=int(self.membw)      
             
        for loop in range(0, int(self.num_tests)):
            self.num_str = "--num=" + str(count)

	    #Set the output director
            output = OUTDIR + "/membw_" + str(count)
            #Set environmental variable output directory
            os.environ['OUTPUTDIR'] = output	
	    throttle(count)	
            self.runapp(APP, count)
            count = count + int(self.xincr) 
            print count;     


def main():

    p = ParamTest()

    membw_test = root.find('./membw-main')
    is_membw_test = False if int(membw_test.get('enable')) == 0 else True

    if is_membw_test:
        p.setvals(membw_test)
        p.run_membw_test(membw_test)

    print " "   

# MAke database 
setup()
makedb()
main()
exit()