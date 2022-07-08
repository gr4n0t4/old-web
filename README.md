### Docker compose squeleton with mysql 5.0 and php 5.2
## Docker compose installation
# Ubuntu/Debian
```
sudo apt install docker-compose
```
It is useful to add your user to the docker group, this way you don't need sudo to execute docker commands
```
usermod -a -G docker youruser
```
To this change have effect you'll need to open a new terminal or make a new login

## Docker compose execution
First you need to be in the same folder where docker-compose.yaml is, this folder.
Then you need to build and run the containers, this can be done by a single command. The first time it will build the containers and import the database, so it will take longer. After this first time it is almost instant.
You'll need the port 80 free, this mean no nginx/apache running on the machine. if you are going to access the url from the same machine you don't need to change any configuration, if you are going to access from a diferent machine you will need to change the BASE_URL parameter on the php/.env file to the IP or hostname.
To bring the dockers up, just execute
```
docker-compose up
```
Remember to put sudo in front if you didn't add your user to the docker group.
You can append *-d* to the command to execute it in dettached mode and leave it running in the background
