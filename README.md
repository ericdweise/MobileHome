# Quickstart
## Formatting a Drive
If your drive is listed in the device folder as `/dev/sdb` then you will use the following command:
```bash
./format-drive.sh /dev/sdb
```
This will wipe any partition table on the device so be careful! It will then create two partitions, one a small NTFS partition that will store unencrypted data. You will be prompted to enter your email and phone number so that anyone who finds this drive can contact you and return it (if they are nice.)

The second partition will take up the remanider of the space on the drive and will be encrypted. After formatting this you will have a device structure like this:

```
sdb              8:16   1  14.5G  0 disk  
├─sdb1           8:17   1     1M  0 part  
└─sdb2           8:18   1  14.5G  0 part  
```


## Automounting
After you have formatted the drive (see above) you will want to automount the drive on your many computers. Assuming that the device is still recognized as `/dev/sdb` then run the following:
```bash
./automount-drive.sh /dev/sdb2
```
This will create a key-file in your user's home folder, add entries to `/etc/fstab` and `/etc/crypttab`, and set the drive to mount automatically to `/home/mobilehome`.


## Gotchas
- After automounting sometimes the ownership of the mountpoint will revert to `root`. To change this run `sudo chown USERNAME /home/mobilehome` where USERNAME is your users uid.

- To keep your encryption key-file safe you should encrypt your user's home folder.
