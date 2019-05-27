# putio-seedbox-automator

Version: 0.1.0

A package of script utilities to automate the connection between a users seedbox and Put.io account.

## Table of Contents

<!--td-->
   * [Usage](#usage)
      * [rclone-mount](#rclone-mount)
         * [Run rclone-mount as user](#run-rclone-mount-as-user)
         * [Install rclone-mount as a service](#install-rclone-mount-as-a-service)
      * [blackhole-uploader](#blackhole-uploader)
         * [Run blackhole-uploader as user](#run-blackhole-uploader-as-user)
         * [Automate blackhole-uploader with crontab](#automate-blackhole-uploader-with-crontab)
      * [putio-downloader](#putio-downloader)
         * [Run putio-downloader as user](#run-putio-downloader-as-user)
         * [Automate putio-downloader with crontab](#automate-putio-downloader-with-crontab)
<!--te-->

## Usage

### rclone-mount

#### Run rclone-mount as user

```bash
./rclone-mount/rclone-mount.sh [--cache_dir] [--config_dir] [--mount_dir] [--remote]
```

#### Install rclone-mount as a service                        
                                                 
Edit `./rclone-mount/rclone-mount.service` with the appropriate configuration values.             
                                                 
Then run the following:                          
                                                 
```bash
cp -r /path/to/rclone-mount/rclone-mount.service /etc/systemd/system/rclone-mount.service         
systemctl start rclone-mount.service             
systemctl enable rclone-mount.service            
```                                    
                                                 
### blackhole-uploader                           
                                                 
#### Run blackhole-uploader as user                                 
                                                 
Create a symlink for each service you’d like to monitor (radarr, donate, etc):

```Bash
ln -s blackhole-uploader.sh radarr-uploader.sh
```

Then run the following:

```bash
./radarr-uploader [—blackhole_dir] [—oauth_token] [—putio_dir]
```

#### Automate blackhole-uploader with crontab

Open crontab:
```bash
crontab -e
```

Then add the following to the end of the file (be sure to chance the file names to that of your symlink):
```bash
*/15 * * * * pgrep blackhole-uploader.sh || /bin/bash /path/to/blackhole-uploader/blackhole-uploader.sh [-b blackhole directory] [-o oauth key] [-p put.io directory] >> /path/to/blackhole-uploader/.blackhole.log
```

###  putio-downloader

#### Run putio-downloader as user

```bash
./putio-Downloader/putio-Downloader.sh [—config_dir] [—source_path] [—dest_path]
```

#### Automate putio-downloader with crontab

Open crontab:
```bash
crontab -e
```

Then add the following to the end of the file (be sure to chance the file names to that of your symlink):

```bash
*/15 * * * * pgrep putio-downloader.sh || /bin/bash /path/to/putio-downloader/putio-downloader.sh [—config_dir] [—source_path] [—dest_path] >> /path/to/putio-downloader/.log
```
