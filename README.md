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

## Configuration
Edit `ncdata/config.yml`, then
```bash
./nextcloud.sh rebuild
```

## Help

```bash
./nextcloud.sh help
```
