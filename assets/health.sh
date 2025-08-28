if ! [ "$(ss -l | grep "LISTEN.*${PORT}")" ];
then
    exit 1
fi