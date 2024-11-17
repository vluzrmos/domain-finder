<!-- Tell how to use this package as a docker container -->

## How to use this package as a docker container

### Prerequisites
- Docker installed on your machine

### Steps
1. Pull the docker image from the docker hub
```bash
docker pull vluzrmos/domain-finder
```

2. Run the docker container
```bash
docker run --rm vluzrmos/domain-finder <domain>
```

Replace `<domain>` with the domain you want to check.

### Example
```bash
docker run --rm vluzrmos/domain-finder hackerone.com
```

### Output
```bash
hackerone.com. 300  IN  A 123.123.123.123
...
```

## Passing list of subdomain names
You can pass a file with a list of subdomain names to the container by using the following command:
```bash
docker run -v <path_to_file>:/app/<filename> --rm vluzrmos/domain-finder <domain> -w=<filename>
```

Replace `<path_to_file>` with the path to the file containing the list of subdomain names and `<filename>` with the name of the file.

### Example
```bash
docker run -v ./subdomains.txt:/app/subdomains.txt:/app/subdomains.txt --rm vluzrmos/domain-finder hackerone.com -w=subdomains.txt
```

Considering that the `subdomains.txt` file is in the same directory as the command will run.


### Create an alias
You can create an alias to run the docker container with the following command:
```bash
sudo curl -s https://raw.githubusercontent.com/vluzrmos/domain-finder/main/run.sh -o /usr/local/bin/domain-finder && sudo chmod +x /usr/local/bin/domain-finder
```