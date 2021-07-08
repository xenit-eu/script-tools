# About

Repository to host helper scripts that can make our life easier and centralize the knowledge base of scripting and automation.  

# Table of contents

- Tomcat thread dump capturing with sleep interval between each thread dump.  
  Supports automatic tomcat ID detection in Dockerized environment, as well as lookup for running tomcat instances based on Catalina Home.  
  Can restart service 'alfresco' optionally.  
  - `./usr/local/tomcat/capture-thread-dumps-and-restart-alfresco-service.sh`
- Example schedule script as a service (e.g. run script periodically that creates thread dumps)  
  In this example, the script `/$CATALINA_HOME/capture-thread-dumps-and-restart-alfresco-service.sh` will be executed every 60 seconds.  
  To enable this service, one must execute `systemctl start alfresco-thread-dump-truck` to start the service and `systemctl enable alfresco-thread-dump-truck` to start it automatically upon reboot.  
  - `./etc/systemd/system/alfresco-thread-dump-truck.service`
