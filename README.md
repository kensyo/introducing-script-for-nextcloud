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

## Show thumbnails
Add the following options to `ncdata/web/config/config.php`
```
'enable_previews' => true,
'enabledPreviewProviders' => array (
   'OC\Preview\PNG',
   'OC\Preview\JPEG',
   'OC\Preview\GIF',
   'OC\Preview\BMP',
   'OC\Preview\XBitmap',
   'OC\Preview\MP3',
   'OC\Preview\TXT',
   'OC\Preview\MarkDown',
   'OC\Preview\PDF'
),
```
Then run
```bash
./nextcloud.sh restart
```

NOTE: `ncdata/web/config/config.php` is created after you start nextcloud at least once.

## Reinstall
If you want to change the docker container settings such as port, sql password and so on, run
```bash
./nextcloud.sh reinstall
```

## Help

```bash
./nextcloud.sh help
```
