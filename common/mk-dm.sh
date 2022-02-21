#!/bin/bash

set -ex

MODE=$1
INPUT=`readlink -f $2`

OUTPUT=`dirname $INPUT`
COMMON_DIR=$(cd `dirname $0`; pwd)
if [ -h $0 ]
then
        CMD=$(readlink $0)
        COMMON_DIR=$(dirname $CMD)
fi
cd $COMMON_DIR
cd ../../..
TOP_DIR=$(pwd)

BOARD_CONFIG=$TOP_DIR/device/rockchip/.BoardConfig.mk
source $BOARD_CONFIG

TEMPDIR=${OUTPUT}/tempfile
ROOTFS=${OUTPUT}/dmv.img
ROOT_HASH=${TEMPDIR}/root.hash
ROOT_HASH_OFFSET=${TEMPDIR}/root.offset
INIT_FILE=${TOP_DIR}/buildroot/board/rockchip/common/security-ramdisk-overlay/init
PARTITION_CMD=`cat $TOP_DIR/device/rockchip/${RK_TARGET_PRODUCT}/${RK_PARAMETER} | grep CMDLINE`

if [ -z "`echo ${PARTITION_CMD} | grep \(rootfs\)`" ]; then
	echo -e "\033[41;1m ERROR: no rootfs in parameter \033[0m"
	exit -1
fi

PARTITION_NUM=`echo ${PARTITION_CMD} | sed "s/\(rootfs\).*/,/g" | grep -o , | wc -l`
ROOTFS_INFO=`ls -l ${INPUT}`

PACK=TRUE
if [ -e ${OUTPUT}/rootfs.info ]; then
	if [ "`cat ${OUTPUT}/rootfs.info`" = "`ls -l ${INPUT}`" ]; then
		PACK=FALSE
	else
		echo "`ls -l $INPUT`" > ${OUTPUT}/rootfs.info
	fi
else
	echo "`ls -l $INPUT`" > ${OUTPUT}/rootfs.info
fi

if [ "$PACK" = "TRUE" ]; then
	test -d ${TEMPDIR} || mkdir -p ${TEMPDIR}
	cp ${INPUT} ${ROOTFS}
	ROOTFS_SIZE=`ls ${ROOTFS} -l | awk '{printf $5}'`
	HASH_OFFSET=$[(ROOTFS_SIZE / 1024 / 1024 + 2) * 1024 * 1024]
	tempfile=`mktemp /tmp/temp.XXXXXX`
	veritysetup --hash-offset=${HASH_OFFSET} format ${ROOTFS} ${ROOTFS} > ${tempfile}
	cat ${tempfile} | grep "Root hash" | awk '{printf $3}' > ${ROOT_HASH}

	cp ${tempfile} ${TEMPDIR}/tempfile
	rm ${tempfile}
	echo ${HASH_OFFSET} > ${ROOT_HASH_OFFSET}
fi

cp ${TOP_DIR}/buildroot/board/rockchip/common/security-ramdisk-overlay/init.in ${INIT_FILE}
TMP_HASH=`cat ${ROOT_HASH}`
TMP_OFFSET=`cat ${ROOT_HASH_OFFSET}`
sed -i "s/OFFSET=/OFFSET=${TMP_OFFSET}/" ${INIT_FILE}
sed -i "s/HASH=/HASH=${TMP_HASH}/" ${INIT_FILE}
sed -i "s/BLOCK=/BLOCK=${PARTITION_NUM}/" ${INIT_FILE}

# sed -i "/exec \/sbin/i\#/usr/sbin/veritysetup --hash-offset=${TMP_OFFSET} create vroot /dev/mmcblk0p3 ${TMP_HASH}" ${INIT_FILE}
sed -i "s/# exec busybox switch_root/exec busybox switch_root/" ${INIT_FILE}
