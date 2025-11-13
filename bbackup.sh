##### ----- Config ----- #####
main_filter="/home/pled/code/scripts/bbackup/main.filter"
ntfy= # check out https://github.com/binwiederhier/ntfy 

main() {
#   newdisk /dev/sdc
   create_timestamp
   backup /etc/nixos/
   backup /home/

#   compress_android vayu 
   get_backup_android vayu
   get_backup_termux vayu

   backupcrydisk /dev/sda1
   backupcrydisk /dev/sdc1 /dev/sdd1 /dev/sde1 /dev/sdf1 /dev/mmcblk0p1
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
   mkdir -p /bbackup/pc/
   rm /bbackup/!-!*!-!
   touch "/bbackup/!-!$(date)!-!"
}

##### ----- Getting data from current device ----- #####
backup() {
   for i in $@; do
      mkdir -p /bbackup/pc$1
      printf "# starting getting data from current pc: $i \n"
      rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i /bbackup/pc$i
      fuckupcheck "$i > /bbackup/pc$i"

      rm /bbackup/pc$i/!-!*!-!
      touch "/bbackup/pc$i/!-!$(date)!-!"
   done
}




##### ----- Getting backup from android device ----- #####
get_backup_android() {
   for i in $@; do
      printf "# starting getting data from android-$i \n"
      rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i:storage/shared/ /bbackup/android-$i/
      fuckupcheck "$i:storage/shared/ /bbackup/$i/"

      touch "/bbackup/android-$i/!-!$(date)!-!"
   done
}

##### ----- Getting backup from termux device ----- #####
get_backup_termux() {
   for i in $@; do
      printf "# starting getting data from termux-$i \n"
      rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i:. /bbackup/termux-$i/
      fuckupcheck "$i:/home/ /bbackup/$i/"

      touch "/bbackup/termux-$i/!-!$(date)!-!"
   done
}

##### ----- Getting backup from linux senders ----- #####
# Untested, but probably will work
get_backup_linux() {
   for i in $@; do
      printf "# starting getting data from linux-$i \n"
      rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i:/home/ /bbackup/linux-$i/
      fuckupcheck "$i:/home/ /bbackup/$i/"

      touch "/bbackup/android-$i/!-!$(date)!-!"
   done
}

##### ----- Compress images on android device ----- #####
compress_android() {
   for i in $@; do
      ssh $i -t "find storage/shared/ -name "*.jpg" -exec jpegoptim -S 256K {} \;"
      ssh $i -t "find storage/shared/ -name "*.png" -exec pngquant --force --verbose --quality=40-100 --strip {} \;"
   done
}



##### ----- Backup on crypted disks ----- #####
backupcrydisk() {
   for i in $@; do
      printf "# backuping on $i \n"
      cryptsetup open $i crydiskasdf
      fuckupcheck "opening $i"
      mount -m /dev/mapper/crydiskasdf /mnt/crydiskasdf
      rsync -avh --delete --delete-excluded --progress /bbackup /mnt/crydiskasdf
      fuckupcheck "backup on $i"
      umount /mnt/crydiskasdf
      cryptsetup close /dev/mapper/crydiskasdf
   done
}


main
