<#noparse>
mydate_finished=$(date +"%Y-%m-%dT%H:%M:%S+0200")

#
# Cleanup 
#
if [ -d ${MC_tmpFolder:-} ]; then
	echo -n "INFO: Removing MC_tmpFolder ${MC_tmpFolder} ..."
	rm -rf ${MC_tmpFolder}
	echo 'done.'
fi

tS=${SECONDS:-0}
tM=$((SECONDS / 60 ))
tH=$((SECONDS / 3600))
echo "On $(date +"%Y-%m-%d %T") ${MC_jobScript} finished successfully after ${tM} minutes." >> molgenis.bookkeeping.log
printf '%s:\t%d seconds\t%d minutes\t%d hours\n' "${MC_jobScript}" "${tS}" "${tM}" "${tH}" >> molgenis.bookkeeping.walltime

#
# Request OS to flush IO buffers/caches to disk.
#
sync

#
# Signal success.
#
mv "${MC_jobScript}.started" "${MC_jobScript}.finished"
if [[ "${lastStep:-false}" == 'true' && -n "${workflowControlFileBase:-}" ]]
then
	rm -f "${workflowControlFileBase}.failed"
	printf 'finished: %s\n' "$(date +%FT%T%z)" >> "${workflowControlFileBase}.totalRuntime"
	printf '%s\n' "Creating ${workflowControlFileBase}.finished ..."
	#
	# NO MORE LOGGING AFTER THIS LINE: finished == finished!
	#
	if [[ -f "${workflowControlFileBase}.started" ]]
	then
		mv "${workflowControlFileBase}".{started,finished}
	else
		touch "${workflowControlFileBase}.finished"
	fi
fi
</#noparse>
trap - EXIT
exit 0

