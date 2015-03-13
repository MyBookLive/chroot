#!/bin/sh

SCRIPT_NAME=$(basename $0)
SCRIPT_START='99'
SCRIPT_STOP='01'

MOUNT_DIR="/DataVolume/shares"
CHROOT_DIR="__CHROOT_DIR_PLACEHOLDER__"
CHROOT_SERVICES="$(cat $CHROOT_DIR/chroot-services.list)"

### BEGIN INIT INFO
# Provides:          $SCRIPT_NAME
# Required-Start:
# Required-Stop:
# X-Start-Before:
# Default-Start:     2 3 4 5
# Default-Stop:      0 6
### END INIT INFO

script_install() {
  cp $0 /etc/init.d/$SCRIPT_NAME
  chmod a+x /etc/init.d/$SCRIPT_NAME
  update-rc.d $SCRIPT_NAME defaults $SCRIPT_START $SCRIPT_STOP > /dev/null
}

script_remove() {
  update-rc.d -f $SCRIPT_NAME remove > /dev/null
  rm -f /etc/init.d/$SCRIPT_NAME
}

#######################################################################

shareDirMountCount="$(mount | grep "$CHROOT_DIR/" | wc -l)"

check_started() {
  if [[ $shareDirMountCount -gt 0 ]]; then
      echo "CHROOT servicess seems to be already started, exiting..."
      exit 1
  fi
}

check_stopped() {
  if [[ $shareDirMountCount -eq 0 ]]; then
      echo "CHROOT services seems to be already stopped, exiting..."
      exit 1
  fi
}

#######################################################################

start() {
    check_started
    mount --bind $MOUNT_DIR $CHROOT_DIR/mnt
    chroot $CHROOT_DIR mount -t sysfs none /sys -o rw,noexec,nosuid,nodev
    mount -o bind /dev $CHROOT_DIR/dev
    mount -o bind /dev/pts $CHROOT_DIR/dev/pts
    mount -o bind /proc $CHROOT_DIR/proc
    for ITEM in $CHROOT_SERVICES; do
        chroot $CHROOT_DIR service $ITEM start
    done
}

stop() {
    check_stopped
    for ITEM in $CHROOT_SERVICES; do
        chroot $CHROOT_DIR service $ITEM stop
    done
    umount $CHROOT_DIR/proc
    umount $CHROOT_DIR/dev/pts
    umount $CHROOT_DIR/dev
    chroot $CHROOT_DIR umount /sys
    umount $CHROOT_DIR/mnt
}

#######################################################################

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        sleep 1
        start
    ;;
    install)
        script_install
    ;;
    init)
        script_install
        sleep 1
        start
    ;;
    remove)
#        stop
#        sleep 1
        script_remove
        echo Warning! A reboot is highly recommended to complete uninstallation!
    ;;
    *)
        echo $"Usage: $0 {start|stop|restart|install|init|remove}"
        exit 1
esac

exit $?
