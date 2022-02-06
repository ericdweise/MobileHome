# Quickstart
## Formatting an External Drive
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

## Encrypting a Partition with LUKS
1. Install `cryptsetup`:
    ```bash
    sudo apt install cryptsetup 
    ```
2. Create partition using, for example, gparted or fdisk
3. Write random data to the new partition:
    ```bash
    shred <DEVICE>
    ```
4. Add a crypt header to the device:
    ```bash
    sudo cryptsetup luksFormat <DEVICE>
    ```
5. Unlock the partition:
    ```bash
    sudo cryptsetup open <DEVICE> mobilehome
    ```
6. Add a filesystem:
    ```bash
    sudo mkfs.ext4 /dev/mapper/mobilehome
    ```
7. Close the LUKs partition
    ```bash
    sudo cryptsetup close mobilehome
    ```


# Partition Mounting
# Automounting LUKs Encrypted Partition to `~/mobilehome/`
1. Install PAM Mount:
    ```bash
    sudo apt install libpam-mount
    ```
2. Add your user's password to the LUKs header of the encrypted partition:
    ```bash
    sudo cryptsetup luksAddKey <DEVICE>
    ```
3. Edit `/etc/security/pam_mount.conf.xml`. Add the following stanza after `<!-- Volume definitions -->`:
    ```text
    <volume user="USERNAME" fstype="auto" path="/dev/sdaX" mountpoint="~/mobilehome" options="fsck,noatime" />
    ```
4. Log out and log back in.


# Partition as a User's Home Directory
TODO...
