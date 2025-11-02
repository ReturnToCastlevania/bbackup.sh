##### ----- Manual ----- #####
# newdisks - clears disk, and creates luks encrypted partition ( ext4 )
# - enter only empty disks on your own risk
# - example: ( '/dev/sda', '/dev/sdc')
# 
#
# linux_senders - gets data from /home/
# - requires setted up ssh connection trough keys, writenn in `/etc/ssh/ssh_config`
#     - or in configuration.nix ( `programs.ssh.extraConfig` section ) for nixos
# - example: ( 'homeserv', 'raspy', 'walterwite' ) 
#
# termux_senders - same as linux_senders, but gets data from .
#
# android_senders - same as linux_senders, but gets data from storage/shared/
# - requires working termux session with ssh enabled
#
#
# crydisks - partitions on disks, where will be stored backups
# - example: ( '/dev/sda1' '/dev/sdc1' )
#
# remote_recievers - coming soon

##### ----- Config ----- #####
main_filter="/home/pled/Archive/scripts/main.filter"
ntfy= # check out https://github.com/binwiederhier/ntfy 

newdisks=() 

android_senders=(vayu)
termux_senders=(vayu)
linux_senders=()

crydisks=( '/dev/sdb1' '/dev/sdc1' '/dev/sdd1' '/dev/sde1' '/dev/sdf1'  ) 
#crydisks=( '/dev/sda1' ) 
remote_recievers=()


ccache-nixos.sh # Cache clearing script

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
for i in "${newdisks[@]}"; do
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





##### ----- Creating empty file with backup date ----- #####
mkdir -p /backup/nixos/
rm /backup/!-!*!-!
touch "/backup/!-!$(date)!-!"

##### ----- Getting data from this pc ----- #####
rsync -avh --progress /etc/nixos /backup/nixos/etc/
fuckupcheck '/etc/nixos/ > /backup/nixos/etc/'

rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" /home /backup/nixos/
fuckupcheck '/home/ > /backup/nixos/'

##### ----- Getting backup from android device ----- #####
for i in "${android_senders[@]}"; do
   printf "# starting getting data from android-$i \n"
   rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i:storage/shared/ /backup/android-$i/
   fuckupcheck "$i:storage/shared/ /backup/$i/"
done

##### ----- Getting backup from termux senders ----- #####
for i in "${termux_senders[@]}"; do
   printf "# starting getting data from termux-$i \n"
   rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i:. /backup/termux-$i/
   fuckupcheck "$i:/home/ /backup/$i/"
done

##### ----- Getting backup from linux senders ----- #####
for i in "${linux_senders[@]}"; do
   printf "# starting getting data from linux-$i \n"
   rsync -avh --delete --delete-excluded --progress --exclude-from="$main_filter" $i:/home/ /backup/linux-$i/
   fuckupcheck "$i:/home/ /backup/$i/"
done









##### ----- Backup on crypted disks ----- #####
for i in "${crydisks[@]}"; do
   printf "# backuping on $i \n"
   cryptsetup open $i crydiskasdf
   fuckupcheck "opening $i"
   mount -m /dev/mapper/crydiskasdf /mnt/crydiskasdf
   rsync -avh --delete --delete-excluded --progress /backup /mnt/crydiskasdf
   fuckupcheck "backup on $i"
   umount /mnt/crydiskasdf
   cryptsetup close /dev/mapper/crydiskasdf
done
