#!/bin/bash


# Default values

# the network name will be appened to each container,  if you want to run serveral instances of this CTF then each instance
# will have to have its own unique network name
network_name="sshfun"

# This will be the third octet of a 24-bit 192.168 address space,  if you want to run several instances of this CTF then each instance
# will have to have it own unique thrid octect.  This is so the networks won't overlap
third_octet="22"
#third_octet=$(shuf -i 10-254 -n 1) # randomly generate a third octet


# This is the external port that will listen for the inital ssh connection, if you want to run serveral instances of the CTF then each instance
# will have to have a unique port
port="2222"
#port=$(shuf -i 49152-65535 -n 1) # chose a random dynamic/ephemeral port

# Account names and passwords can be the same for each player
username="student"
password="Goodluck!"

# if you want to keep config files and dockerfiles for troubleshooting then set this value to false
# if the player has access to the host computer this can prevent cheating  (assuming you delete this script 😱😫😭 )
delete_working_files=true

# You can overide default values at the command line (no need to change the script for that)
# Parse options
while getopts "n:o:p:u:w:h" opt; do
  case $opt in
    n) network_name="$OPTARG";;
    o) third_octet="$OPTARG";;
    p) port="$OPTARG";;
    u) username="$OPTARG";;
    w) password="$OPTARG";;
    h) echo "Usage: $0 [-n network_name] [-o network thrid octet 192.168.x.0/24] [-p ssh port] [-u student username] [-w password] "
       exit 0
       ;;
  esac
done

## a little input validation

## make sure third_octet is valid
if ! [[ "$third_octet" =~ ^[0-9]+$ ]] || (( third_octet < 0 || third_octet > 255 )); then
  echo "Error: -o must be a number between 0 and 255"
  echo "Usage: $0 [-n network_name] [-o network thrid octet 192.168.x.0/24] [-p ssh port] [-u student username] [-w password] "
  exit 1
fi

## check of port number is valid
if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
  echo "Error: -p. Must be a valid port number."
  echo "Usage: $0 [-n network_name] [-o network thrid octet 192.168.x.0/24] [-p ssh port] [-u student username] [-w password] "
  exit 1
fi

## check the network name 
if ! [[ "$network_name" =~ ^[a-z0-9][a-z0-9_.-]{0,254}$ ]]; then
  echo "Error: Invalid network name."
  echo "Must start with a letter or digit, be lowercase, and contain only letters, numbers, dashes (-), underscores (_), or periods (.)"
  exit 1
fi


#flags for each level
ssh_facts=(
    "SSH was first released in 1995 by Tatu Ylönen."                            #level0 flag
    "The default SSH port is 22, but it can be changed for \"seCuRiTy\"."       #level1 flag
    "Using scp and rsynce, SSH can transport files securely"                    #level2 flag
    "The main SSH server configuration file is /etc/ssh/sshd_config."           #level3 flag
    "SSH supports local, remote, and dynamic port forwarding for tunneling."    #level4 flag
    "You can use public key authentication to log in without a password."       #level5 flag
    "The setting PermitRootLogin no disables direct root SSH access."           #level6 flag
    "You're Amazing"                                                            #level7 flag is in the picture
)

#Unpredictable hostnames so the player can't use DNS to cheat
host_names=(
    "launchpad"   #level0
    "imFeeling22" #level1
    "2s"          #level2
    "eyeshaveit"  #level3
    "alicia"      #level4
    "Dikembe"     #level5
    "webhead"     #level6
)

ips=(

    "192.168.$third_octet.100"  #launchpad
    "192.168.$third_octet.22"   #level1
    "192.168.$third_octet.222"  #level2
    "192.168.$third_octet.33"   #level3
    "192.168.$third_octet.45"   #level4
    "192.168.$third_octet.50"   #level5
    "192.168.$third_octet.66"   #level6
)


#Create the docker network
create_docker_network(){

    docker network create --driver bridge --subnet=192.168.$third_octet.0/24 $network_name
    printf "created docker network: %s \n" $network_name
    docker network ls --filter="Name=$network_name"

}

# Custom banner that replaces the /etc/motd on each system
# usage: custom_banner "$currentLevel" "$congrats" "$hint" "$flag"
custom_banner() {
    cat << EOF > "$1-custom-motd.sh"
    #!/bin/sh
    clear
    figlet "Welcome to the $1!" | lolcat
    echo "$2" | pv -qL 100
    echo "$3" | pv -qL 100
    echo "$4" | pv -qL 100
EOF
}


build_and_run_containers() {

    # Container names will be the level name + the network name
    container_name=$(printf '%s-%s' $1 $network_name)
    docker build -f  $1/Dockerfile -t  $container_name .
    docker run -dit --name $container_name -h ${host_names[$2]} --network  $network_name --ip ${ips[$2]} $container_name
    printf "Created a container\n"
    docker ps --filter "name=$container_name"

}

                                ########################## Level Building ###################################
                                ## Each level is setup in six parts.                                       ##
                                ## 1. Level specific guidance, such flags and hints                        ##
                                ## 2. Level specific banner creation                                       ##
                                ## 3. Support file creation (I'm going to use a lot of herdocs)            ##
                                ## 4. Building The docker file (like so many herdocs)                      ##
                                ## 5. Building and running the container                                   ##
                                ## 6. Clean up temp files (I need to clean up the mess from all my herdocs)##
                                #############################################################################

create_launchpad(){

currentLevel="launchpad"
congrats="Welcome to the Launchpad, this system will be used as a starting point for many of the next challeneges"
hint="Level 1 can be found on this same network. Its ip ends with secure shell's default port number"
flag="Flag: ${ssh_facts[0]}"

custom_banner "$currentLevel" "$congrats" "$hint" "$flag"

mkdir -p $currentLevel && printf "Created directory %s \n" $currentLevel

cat << EOF > $currentLevel/Dockerfile
# Use Alpine Linux as the base image
FROM alpine:latest

COPY $currentLevel-custom-motd.sh /etc/profile.d/custom-motd.sh

# Install software, configure user
RUN apk add --no-cache openssh figlet pv curl\
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing --update lolcat \
    && mkdir -p /var/run/sshd \
    && echo '' > /etc/motd \
    && chmod +x /etc/profile.d/custom-motd.sh \
    && adduser -D  $username \
    && echo "$username:$password" | chpasswd \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config \
    && ssh-keygen -A

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]

EOF

# Unlike the other containers this container will need to have a port open on the host machine

    container_name=$(printf '%s-%s' $currentLevel $network_name)

    docker build -f  $currentLevel/Dockerfile -t  $container_name .
    docker run -dit -p $port:22 --name $container_name -h ${host_names[0]} --network  $network_name --ip ${ips[0]} $container_name
    printf "Created a container\n"
    docker ps --filter "name=$container_name"

#clean up files
if [ "$delete_working_files" = true ]; then
    rm $currentLevel-custom-motd.sh
    rm -rf $currentLevel #this will delete the dockerfile and its directory
fi

}

create_level1(){

currentLevel="level1"
congrats="Ok so you know something about ports 🛥️"
hint="SSH servers dont always listen on standard ports. The next server's address is ${ips[2]}"
flag="Flag: ${ssh_facts[1]}"

custom_banner "$currentLevel" "$congrats" "$hint" "$flag"

mkdir -p $currentLevel && printf "Created directory %s \n" $currentLevel

cat << EOF > $currentLevel/Dockerfile
# Use Alpine Linux as the base image
FROM alpine:latest

COPY $currentLevel-custom-motd.sh /etc/profile.d/custom-motd.sh

RUN apk add --no-cache openssh figlet pv \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing --update lolcat \
    && mkdir -p /var/run/sshd \
    && echo '' > /etc/motd \
    && chmod +x /etc/profile.d/custom-motd.sh \
    && mkdir -p /var/run/sshd \
    && adduser -D  $username \
    && echo "$username:$password" | chpasswd \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers $username@${ips[0]}" >> /etc/ssh/sshd_config \
    && ssh-keygen -A


# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]

EOF

   build_and_run_containers "$currentLevel" "1"

#clean up files
if [ "$delete_working_files" = true ]; then
    rm $currentLevel-custom-motd.sh
    rm -rf $currentLevel #this will delete the dockerfile and its directory
fi
}

create_level2(){

currentLevel="level2"
congrats="Good job looking at numbers on your screen and typing them in 💪, arugments in ssh are a good thing"
hint="There are places where you can find address for ssh servers. When you find the server's IP, go back to the launchpad and try it "
flag="Flag: ${ssh_facts[2]}"


custom_banner "$currentLevel" "$congrats" "$hint" "$flag"

mkdir -p $currentLevel && printf "Created directory %s \n" $currentLevel

cat << EOF > $currentLevel/Dockerfile
# Use Alpine Linux as the base image
FROM alpine:latest


COPY $currentLevel-custom-motd.sh /etc/profile.d/custom-motd.sh

# Install OpenSSH
RUN apk add --no-cache openssh figlet pv \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing --update lolcat \
    && mkdir -p /var/run/sshd \
    && echo '' > /etc/motd \
    && chmod +x /etc/profile.d/custom-motd.sh \
    && adduser -D  $username \
    && echo "$username:$password" | chpasswd \
    && echo "#!/bin/sh" > /home/$username/.ash_profile \
    && echo "ssh-keyscan -t ecdsa ${ips[3]} > /home/$username/.ssh/known-hosts" >> /home/$username/.ash_profile \
    && chown $username:$username /home/$username/.ash_profile \
    && chmod +x /home/$username/.ash_profile \
    && echo '[ -f "\$HOME/.ash_profile" ] && . "\$HOME/.ash_profile"' >> /etc/profile \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && mkdir -p /home/$username/.ssh \
    && chown $username:$username /home/$username/.ssh \
    && chmod 700 /home/$username/.ssh \
    && sed -i 's/^#Port 22/Port 222/' /etc/ssh/sshd_config \
    && echo "AllowUsers $username@${ips[0]}" >> /etc/ssh/sshd_config \
    && sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config \
    && ssh-keygen -A




# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]

EOF



    build_and_run_containers "$currentLevel" "2"

if [ "$delete_working_files" = true ]; then
    rm $currentLevel-custom-motd.sh
    rm -rf $currentLevel #this will delete the dockerfile and its directory
fi
}


create_level3(){

# Generate RSA Private Key
openssl genpkey -algorithm RSA -out id_rsa -pkeyopt rsa_keygen_bits:2048

currentLevel="level3"
congrats="Good Job, The known hosts file should be encrypted so attackers can't read it 🤐. "
hint="A private key has leaked. Level 4 will only allow logins from the launchpad. Your password is no good there "
flag="Flag: ${ssh_facts[3]}"

custom_banner "$currentLevel" "$congrats" "$hint" "$flag"

mkdir -p $currentLevel && printf "Created directory %s \n" $currentLevel

cat << EOF > $currentLevel/Dockerfile
# Use Alpine Linux as the base image
FROM alpine:latest

COPY $currentLevel-custom-motd.sh /etc/profile.d/custom-motd.sh
COPY id_rsa /${host_names[4]}

# Install OpenSSH
RUN apk add --no-cache openssh figlet pv \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing --update lolcat \
    && mkdir -p /var/run/sshd \
    && echo '' > /etc/motd \
    && chmod +x /etc/profile.d/custom-motd.sh \
    && mkdir -p /var/run/sshd \
    && adduser -D  $username \
    && echo "$username:$password" | chpasswd \
    && mkdir -p /home/$username/.ssh \
    && chown $username:$username /home/$username/.ssh \
    && chmod 700 /home/$username/.ssh \
    && echo "#!/bin/sh" > /home/$username/.ash_profile \
    && chmod 444 /${host_names[4]} \
    && echo '[ -f "\$HOME/.ash_profile" ] && . "\$HOME/.ash_profile"' >> /etc/profile \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config \
    && echo "AllowUsers $username@${ips[0]}" >> /etc/ssh/sshd_config \
    && sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config \
    && ssh-keygen -A



# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]

EOF

    build_and_run_containers "$currentLevel" "3"

if [ "$delete_working_files" = true ]; then
    rm $currentLevel-custom-motd.sh
    rm -rf $currentLevel #this will delete the dockerfile and its directory
fi
}


create_level4(){


currentLevel="level4"
congrats="Its important to keep your keys secure 🔐 "
hint="Level5 is at ${ips[5]}. However, theres something wrong with level 5 and you can't login (per se), but you don't need a shell to RCE "
flag="Flag: ${ssh_facts[4]}"

custom_banner "$currentLevel" "$congrats" "$hint" "$flag"

# Extract Public Key from previous levels private key
ssh-keygen -y -f id_rsa > authorized_keys

mkdir -p $currentLevel && printf "Created directory %s \n" $currentLevel

cat << EOF > $currentLevel/Dockerfile
# Use Alpine Linux as the base image
FROM alpine:latest

COPY authorized_keys /authorized_keys
COPY $currentLevel-custom-motd.sh /etc/profile.d/custom-motd.sh

# Install OpenSSH
RUN apk add --no-cache openssh figlet pv \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing --update lolcat \
    && mkdir -p /var/run/sshd \
    && echo '' > /etc/motd \
    && chmod +x /etc/profile.d/custom-motd.sh \
    && adduser -D  $username \
    && echo "$username:$(openssl rand -base64 10) | cut -c1-10" | chpasswd \
    && mkdir -p /home/$username/.ssh \
    && chown $username:$username /home/$username/.ssh \
    && chmod 700 /home/$username/.ssh \
    && mv /authorized_keys /home/$username/.ssh/authorized_keys \
    && chown $username:$username /home/$username/.ssh/authorized_keys \
    && mkdir -p /var/run/sshd \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "AllowUsers $username@${ips[0]}" >> /etc/ssh/sshd_config \
    && sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config \
    && ssh-keygen -A

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]

EOF


    build_and_run_containers "$currentLevel" "4"


if [ "$delete_working_files" = true ]; then
    
    rm $currentLevel-custom-motd.sh
    rm -rf $currentLevel #this will delete the dockerfile and its directory
fi

}


create_level5(){


currentLevel="level5"
congrats="You got this far, but theres still a little ways to go"
hint=" I installed level fives key on the launchpad . . . you're welcome"
flag="*** flag not found ***"

custom_banner "$currentLevel" "$congrats" "$hint" "$flag"

mkdir -p $currentLevel && printf "Created directory %s \n" $currentLevel

cat << EOF > flag.conf
flag = ${ssh_facts[5]}
hint = curl is installed on the launchpad but level6 (${ips[6]}) only accepts connections from this system
EOF

cat << EOF > $currentLevel/Dockerfile
# Use Alpine Linux as the base image
FROM alpine:latest

COPY flag.conf /etc/flag.conf
# Be nice to the user and don't make them have to type the password every time they want to run a command via ssh
COPY authorized_keys /authorized_keys
COPY $currentLevel-custom-motd.sh /etc/profile.d/custom-motd.sh

# Install OpenSSH
RUN apk add --no-cache openssh figlet pv\
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing --update lolcat \
    && mkdir -p /var/run/sshd \
    && echo '' > /etc/motd \
    && chmod +x /etc/profile.d/custom-motd.sh \
    && adduser -D  $username \
    && echo "$username:$password" | chpasswd \
    && echo "#!/bin/sh" > /home/$username/.ash_profile \
    && echo "echo 'Access is restricted. You are being logged out.' && exit" >> /home/$username/.ash_profile \
    && chown $username:$username /home/$username/.ash_profile \
    && chmod +x /home/$username/.ash_profile \
    && echo '[ -f "\$HOME/.ash_profile" ] && . "\$HOME/.ash_profile"' >> /etc/profile \
    && mkdir -p /home/$username/.ssh \
    && chown $username:$username /home/$username/.ssh \
    && chmod 700 /home/$username/.ssh \
    && mv /authorized_keys /home/$username/.ssh/authorized_keys \
    && chown $username:$username /home/$username/.ssh/authorized_keys \
    && rm /usr/bin/wget \
    && sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config \
    && ssh-keygen -A


# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]

EOF

    build_and_run_containers "$currentLevel" "5"

if [ "$delete_working_files" = true ]; then
    rm flag.conf
    rm $currentLevel-custom-motd.sh
    rm -rf $currentLevel #this will delete the dockerfile and its directory
fi
}

create_level6() {
currentLevel="level6"
congrats="This is a webserver so you should not be seeing this"
hint=""
flag=""

#Get the picture for the webpage
#wget -O picture.png https://i.imageupload.app/15b29769c100e9377643.png 
# Looks like imageupload is no more, but this is better. Now its all self contained
cat images/flag6.base64 | base64 -d > picture.png


# Create the nginx conf file
cat << EOF > default.conf
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        allow ${ips[5]};
        deny all;
    }
}
EOF

# Create the index.html
cat << EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Congrats on finishing the sshFun CTF</title>
    <style>
        /* Full-page animated gradient background */
        body {
            margin: 0;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            background: linear-gradient(270deg, #ff7e5f, #feb47b, #86a8e7, #7f7fd5);
            background-size: 400% 400%;
            animation: gradientAnimation 8s ease infinite;
        }

        @keyframes gradientAnimation {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }

        /* Centered image styling */
        img {
            max-width: 50%;
            max-height: 50vh;
            border-radius: 15px;
            box-shadow: 0px 8px 16px rgba(0, 0, 0, 0.2);
        }
    </style>
</head>
<body>
    <!-- flag6 is: ${ssh_facts[6]} -->
    <img src="picture.png" alt="Centered Picture">
    <!-- Level 7 flag is in the picutre -->
</body>
</html>

EOF

mkdir -p $currentLevel && printf "Created directory %s \n" $currentLevel

cat << EOF > $currentLevel/Dockerfile

FROM nginx:alpine

# Remove default Nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom Nginx configuration
COPY default.conf /etc/nginx/conf.d/

# Copy website files
COPY picture.png /usr/share/nginx/html/picture.png
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
EOF


build_and_run_containers "$currentLevel" "6"

if [ "$delete_working_files" = true ]; then
    rm picture.png
    rm -rf $currentLevel #this will delete the dockerfile and its directory
    rm index.html
    rm default.conf

    ## delete keys from level 3,4,5
    rm id_rsa
    rm authorized_keys
fi
}


## -- if bash had a main this would be it -- ##

if [[ $EUID -eq 0 || $(id -Gn | grep -w docker) ]]; then

    create_docker_network
    create_launchpad
    create_level1
    create_level2
    create_level3
    create_level4
    create_level5
    create_level6

else

    echo "User needs to be root or member of docker group"

fi
