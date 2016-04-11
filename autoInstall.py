#!/usr/bin/python
import pexpect
import sys
import os


def ssh(ip) :
   d = pexpect.spawn('ssh root@%s'%ip)
   ret=100
   while ret !=2:
    ret =d.expect (['Are you sure',pexpect.EOF,'\#'])
    if ret == 0 :
      d.sendline ('yes')
      continue
    elif ret == 1 :
      print "End Of File"
      sys.exit(1)
   return d

def get_ip_list():
   fp = ''
   controller=[]
   compute=[]
   path = '/etc/cluster_info'
   if os.path.exists(path):
      fp = open(path,'r')
   else:
      print "File doesn't exist. Exiting!"
      sys.exit(1)
   
   line = fp.readline()
   while line:
      if line.startswith('Controller'):
         controller.append(line.strip('Controller ').strip('=').strip(' ').strip('\n'))
      else :
         if line.startswith('Compute'):
             compute.append(line.strip('Compute ').strip('=').strip(' ').strip('\n'))
      line = fp.readline()
   #print file
   fp.close()
   return controller+compute
       
if __name__=='__main__':
   #parse cluster_info file and get the list of IP addresses
   ip_list=get_ip_list()
   Controller=ip_list[0]
   Compute=ip_list[1]
   #ssh to each Compute except Controller. Get a handle to Controller by executing the command sudo -i
   handle_Controller=pexpect.spawn('sudo',['-i'])
   handle_Controller.expect('#')
   print handle_Controller.before + '\n' + handle_Controller.after

   handle_Compute = ssh(Compute)
   #
