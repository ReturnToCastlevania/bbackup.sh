# bbackup.sh
> simple script that helps you to backup all your important data

### feautures:
- easy creating of new backup recievers ( luks )
- backuping data to encrypted disks trough rsync ( filters included )
- getting data from remote linux / android device ( requires rsync installed on both sides )
- flexible and lightweight

---

# How to use
- by default, **bbackup.sh will do nothing**
- just open script in your favorite text editor and you probably will get it
- you need to write down what he need to do in main function ( check out `functions` section )

# functions
##### newdisk 
 - creates new disk
 - eats parameters like /dev/sda /dev/sdc 
 - can clear or shred disk
 - `newdisk /dev/sdc`
 - `echo c | newdisk /dev/sdf`

##### createtimestamp
 - creates timestamp in /bbackup/ folder
 - its useful when you need to know when you did last backup
 - dont takes arguments
 - `createtimestamp`

##### backup
 - backups folders from current machine to /bbackup/
 - `backup /home/`
 - `backup /etc/nixos/`

##### get_backup_android
 - gets backup from ssh connected device
 - more specifically, from `/storadge/shared/` folder
 - `get-backup-android vayu`

##### get_backup_termux
 - same as get-backup-android, but gets backup from . folder
 - `get-backup-termux vayu`

##### get_backup_linux
 - same as get_backup_android, but gets backup from /home/ folder
 - probably, `get_backup_linux toshniba`

##### compress_android
 - compresses **all** jpeg images on device. 
    - can greatly decrease size of backup
    - but eats quality of photos
    - but greatly increases backup time
 - `compress_android vayu`

##### backupcrydisk
 - sends backup on crypted disk
 - `backupcrydisk /dev/sda1`
