FROM java:8
COPY target/*.jar /demoapp.jar

ENTRYPOINT ["java","-jar","/demoapp.jar"]