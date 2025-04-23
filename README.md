# The SSH Obstacle Course

[![Image](https://i.imageupload.app/8d3b43f9c7e2fa5643f1.png)](https://imageupload.app/8d3b43f9c7e2fa5643f1)

Welcome to the SSH Obstacle Course — a fun and practical exercise designed to teach users how to navigate and use SSH effectively. It can be easily deployed on a **CFTD instance** and supports **multiple players** on the same server.

---

## Requirements

- [Docker](https://www.docker.com/)

---

## To start the game

Run as root (or a memeber of the docker group)
> ./s.sh

Log into the launchpad 
> ssh student@192.168.22.100 -p 2222

Goodluck!


## Usage

Run the setup script with optional flags:

```bash
./s.sh [-n network_name] [-o network_third_octet 192.168.x.0/24] [-p ssh_port] [-u student_username] [-w password]
```

### Example:

```bash
./s.sh -n sshfun -o 22 -p 2222 -u student -w Goodluck!
```

You can also run it without any arguments — default values will be used:

```bash
./s.sh
```

---

## Resetting the Environment

To delete and restart all containers, use:

```bash
./reset_containers.sh
```

---





