# Introducing Script for Nextcloud

## Usage
First, download this script.

```bash
curl https://raw.githubusercontent.com/kensyo/introducing-script-for-nextcloud/main/nextcloud.sh -o nextcloud.sh
chmod 755 nextcloud.sh
```

Then,

```bash
./nextcloud.sh install
./nextcloud.sh start
```

## Update
For container update,
```bash
./nextcloud.sh update
```

For self-update(updating this script itself),
```bash
./nextcloud.sh updateself
```

Recommend running the following after selfupdate
```
./nextcloud.sh updateDockerConfs
./nextcloud.sh update
```

## Configuration
Edit `ncdata/config.yml`, which is created after installation, then
```bash
./nextcloud.sh rebuild
```

## Backup
Save `ncdata` directory.

## Custom Dockerfile
If you want to use your own nextcloud image, set the `Dockerfile` file at `ncdata/ncdocker/app`.
Then run
```bash
./nextcloud.sh rebuild
```

## Change DB settings
If you want to change the mariadb root password, user name, and user password you has defiend by yourself at installation,
run
```bash
./nextcloud.sh changedbsetup
```
This feature may be unsafe, so run after you back up nextcloud.

## Help

```bash
./nextcloud.sh help
```
