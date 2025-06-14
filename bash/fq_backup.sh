#!/bin/bash
echo ""
echo "|----------------------->"
echo "| Backup FQ "
echo "|----------->"

# operation variables:
operation=""
set_year=""
is_path=""
year_pre_check() {
    if [ -z $FQ_YEAR ]; then
        return 1
    else
        return 0
    fi
}


load_config() {
    
    if [[ $is_path == "--load-config" ]]; then
        return 1
    fi
    
    if [[ -z "$is_path" ]]; then
        echo ""
        echo "Specify your configuration file: --load-config=/path/to/file.sh"
    else
        echo ""
        echo "Load configuration from: $is_path"
        . $is_path
        echo "... done"
    fi
}

set_year_function() {
    if [[ -z "$FQ_S3_BACKUP_PATH" ]] 
    then
        echo "Load your configuration file via with '--load-config' first"
    else
        export FQ_YEAR=$set_year
        export RESTIC_REPOSITORY=s3:https://s3.fr-par.scw.cloud/$FQ_S3_BACKUP_PATH/$FQ_YEAR
        echo "| Year: $FQ_YEAR"
        echo "| RESTIC Repository: $RESTIC_REPOSITORY"
        echo "|__________________"
    fi
}

show_help() {
     echo "Usage: $1 [-a value] [-b value] [-h]"                                                                        
     echo                                                                                                               
     echo "Options:"
     echo "  --load-config      Command to set credentidals and configuration up right"
     echo "  --set-year=XXXX    A year decoded with 4 digits"
     echo "  --unset            Unset all bash variables of this script"                                                                       
     echo "  --list-folders     List folders in S3 of the backup folder"
     echo "  --list-storage-class    List storage class of uploaded files in S3."
     echo "  --init                  Initialize a Restic repository"
     echo "  --backup                Run a backup"
     echo "  --show-scaleway-bill    Show Scaleway Bill (all resources)"
     echo "  -h | help | --help      Show this menu"
}

# Parse arguments                                                                                                      
for arg in "$@"; do
    case $arg in
        --load-config*)
            operation="load_config"
            is_path="${arg#*=}"
            ;;
        --set-year=*)                                                                                                      
            set_year="${arg#*=}"
            operation="set"
            if [ -z $set_year ]; then
                echo "   Error: --set-year requires a year as 4 digits (--set-year=2000)"
                return
            fi
            set_year_function
            ;;
        --unset)
            operation="unset"
            ;;
        --list-folders | lf)
            operation="list_folders"
            ;;
        --list-storage-class | lsc)
            operation="list_storage_class"
            ;;
        --init | init)
            operation="init"
            ;;
        --show-scaleway-bill | bill | scb)
            operation="show_scaleway_bill"
            ;;
        show | --show)
            operation="show"
            ;;
        help |-h | --help)                                                                                                   
            operation="help"
            show_help
            return
            ;;                                                                                                
        *)                                                                                                             
            echo "Unknown argument: $arg"                                                                              
            return                                                                                                 
            ;;                                                                                                         
    esac                                                                                                               
done


# fail safe: If no year is set before, we assume that the tool is not setup
# correctly. We can stop here and setup the tool first.

#export pre_check_result=$(year_pre_check)
year_pre_check
pre_check_result=$?

# Print the parsed values                                                                                              
echo "|---"
echo "|   Operation: $operation for year $set_year"
if [[ pre_check_result -eq 1 ]] && [[ $operation != "load_config" ]] && [[ $operation != "unset" ]] && [[ $operation != "show_scaleway_bill" ]]
then
    echo "|   Pre check: Failed! Specify a year!"
    echo "|   Error: Run --set-year=XXXX beforehand to setup the tool correctly"
else
    echo "|   Pre check: OK"
fi

# Simple if conditions for the individual operations. nothing special
if [[ "$operation" == "show" ]]
then
    echo "|-------->"
    echo "| Backup of year:       $FQ_YEAR"
    echo "| Backup S3 repository: $RESTIC_REPOSITORY"
    echo "| Restic pack size:     $RESTIC_PACK_SIZE"
    echo "<-----"
fi

if [[ "$operation" == "init" ]]  && [[ $pre_check_result -eq 0 ]]
then
    restic init
fi

if [[ "$operation" == "load_config" ]]
then
    load_config
fi

if [[ "$operation" == "unset" ]]
then
    #year_pre_check
    echo "Unset all Bash variables"
    unset FQ_YEAR
    unset RESTIC_PACK_SIZE
    unset RESTIC_PASSWORD
    unset FQ_S3_BACKUP_PATH
    unset RESTIC_REPOSITORY
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    echo "Done: Unset all necessary environment variables to run fbackup.sh"
fi

if [[ "$operation" == "list_folders" ]] && [[ $pre_check_result -eq 0 ]]
then
    rclone lsd scwfq:$FQ_S3_BACKUP_PATH/
fi

if [[ "$operation" == "list_storage_class" ]] && [[ $pre_check_result -eq 0 ]]
then
    rclone lsjson scwfq:$FQ_S3_BACKUP_PATH/$FQ_YEAR --recursive | jq -r '.[] | "\(.Path): \(.Tier)"'
fi

if [[ "$operation" == "show_scaleway_bill" ]]
then
    scw billing consumption list -p sw_fq
fi
