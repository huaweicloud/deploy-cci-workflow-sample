FROM swr.cn-north-4.myhuaweicloud.com/codeci/maven:maven3.5.3-jdk1.8-1.0.1
COPY target/*.jar /demoapp.jar

ENTRYPOINT ["java","-jar","/demoapp.jar"]