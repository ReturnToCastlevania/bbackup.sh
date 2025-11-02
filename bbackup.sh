##### ----- Manual ----- #####
# newdisk - create new disk
#  - eats parameters like /dev/sda /dev/sdc ...
#  - can clear or shred disk
#  - `newdisk /dev/sdc`
#  - `echo c | newdisk /dev/sdf`

# createtimestamp
#  - creates timestamp in backup folder
#  - its useful when you need to know when you did last backup
#  - dont takes arguments
#  - `createtimestamp`

# backup
#  - backups folders from current machine to /backup/
#  - `backup /home/`
#  - `backup /etc/nixos/`

# get-backup-android
#  - gets backup from ssh connected device
#  - more specifically, from `/storadge/shared/` folder
#  - `get-backup-android vayu`

# get-backup-termux
#  - same as get-backup-android, but gets backup from . folder
#  - `get-backup-termux vayu`

# get-backup-linux
#  - same as get-backup-android, but gets backup from /home/ folder
#  - probably, `get-backup-linux toshniba`

# ccache-android
#  - compresses **all** jpeg images on device. 
#     - can greatly decrease size of backup
#     - but eats quality of photos
#     - but greatly increases backup time
#  - `ccache-android vayu`

# backupdisk
#  - sends backup on crypted disk
#  - `backupdisk /dev/sda1`




##### ----- Config ----- #####
main_filter="/home/pled/code/scripts/main.filter"
ntfy= # check out https://github.com/binwiederhier/ntfy 


main() {
#   newdisk /dev/sdc
   create_timestamp
   backup /etc/nixos/
   backup /home/

   ccache_android vayu 
   get_backup_android vayu
   get_backup_termux vayu

   backupdisk /dev/sda1
}


##### ----- FuckedUpCheck ----- #####
fuckupcheck() {
   if [[ $? != 0 ]]; then
      printf "! $1 fucked up | exit-code = $? \n"
      if [[ $ntfy != "" ]]; then
         curl -d "$(date) $1 fucked up | exit-code = $?" $ntfy
      fi
      read -p "are you sure that you wonna continue? [y/n] " continue
      if [[ $continue != y ]]; then 
         exit 1
      fi
   else
      printf "# $1 succesful | exit-code = $? \n\n ----- \n\n"
   fi
}


##### ----- Rootcheck ----- #####
if [[ $(whoami) != root ]]; then
   read -p "running without root. are you sure that you wonna continue? [y/n] " continue
   if [[ $continue != y ]]; then 
      exit 1
   fi
fi


##### ----- Creating new disks ----- #####
newdisk() {
   for i in $@; do
      printf '# creating new crypt disk $i \n'
      read -p "just Clear $i or Shred? [c/s/n] " continue
      if [[ $continue == c ]]; then
         wipefs -a "$i"
         fuckupcheck "wiping $i"
      elif [[ $continue == s ]]; then
         shred -vzn 1 $i
         fuckupcheck "shredding $i"
      fi
      echo 'type=83' | sfdisk $i
      part="${i}1"
      printf $part
      cryptsetup luksFormat $part
      fuckupcheck "crypting $i"
      printf "opening $i for creating fs \n"
      cryptsetup open $part crycrycry
      mkfs.ext4 /dev/mapper/crycrycry
      fuckupcheck "creating fileststem on $part"
      cryptsetup close /dev/mapper/crycrycry
      fuckupcheck "closeing $i"
   done
}



##### ----- Creating empty file with backup date ----- #####
create_timestamp() {
   mkdir -p /backup/pc/
   rm /backup/!-!*!-!
   touch "/backup/!-!$(date)!-!"
}

##### ----- Getting data from this pc ----- #####
backup() {
   rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $1 /backup/pc/$1
   fuckupcheck "$1 > /backup/pc/$1"
}


##### ----- Getting backup from android device ----- #####
get_backup_android() {
   for i in $@; do
      printf "# starting getting data from android-$i \n"
      rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i:storage/shared/ /backup/android-$i/
      fuckupcheck "$i:storage/shared/ /backup/$i/"
   done
}

##### ----- Getting backup from termux senders ----- #####
get_backup_termux() {
   for i in $@; do
      printf "# starting getting data from termux-$i \n"
      rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i:. /backup/termux-$i/
      fuckupcheck "$i:/home/ /backup/$i/"
   done
}

##### ----- Getting backup from linux senders ----- #####
# Untested, but probably will work
get_backup_linux() {
   for i in $@; do
      printf "# starting getting data from linux-$i \n"
      rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i:/home/ /backup/linux-$i/
      fuckupcheck "$i:/home/ /backup/$i/"
   done
}

ccache_android() {
   for i in $@; do
      ssh $i -t "find storage/shared/ -name '*.jpg' | xargs jpegoptim --max 30" # compress all photos in Archive folder
   done
}



##### ----- Backup on crypted disks ----- #####
backupdisk() {
   for i in $@; do
      printf "# backuping on $i \n"
      cryptsetup open $i crydiskasdf
      fuckupcheck "opening $i"
      mount -m /dev/mapper/crydiskasdf /mnt/crydiskasdf
      rsync -avh --delete --delete-excluded --progress /backup /mnt/crydiskasdf
      fuckupcheck "backup on $i"
      umount /mnt/crydiskasdf
      cryptsetup close /dev/mapper/crydiskasdf
   done
}



main
