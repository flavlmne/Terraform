
#!/bin/bash
source "$(dirname ${BASH_SOURCE[0]})"/../constants/colors.sh

display_msg()
{
    local msg=$1
    local type=$2

    if [ "$type" = "info" ]; then 
        echo -e "${INFO_COLOR}$msg${RESET_COLOR}"
    elif [ "$type" = "warning"  ]; then 
        echo -e "${WARNING_COLOR}$msg${RESET_COLOR}"
    elif [ "$type" = "error" ]; then 
        echo -e "${ERROR_COLOR}$msg${RESET_COLOR}"
    else 
        echo -e $msg
    fi
}