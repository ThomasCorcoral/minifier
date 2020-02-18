#!/bin/dash

# error_check goal is to tell the user his error and always invite him to use --help

error_check()
{
    case $1 in
    -1) echo "Paths to ’dir_source’ and ’dir_dest’ directories must be specified";;
    1) echo "--help can only be used alone" ;;
    2) echo "Paths to the 'tags_file' must be specified";;
    3) echo "An argument can only appear once";;
    4) echo "The option is not valid";;
    esac

    echo "Enter \"./minifier.sh --help\" for more information."
    return 0
    
}

check_args_valid()
{
    case $1 in
    --help) echo "OK option --help" ;;
    --html) echo "OK option --html" ;;
    -f) echo "OK option -f" ;;
    -v) echo "OK option -v" ;;
    -t) echo "OK option -t" ;;
    --css) echo "OK option --css" ;;
    *) error_check 4
    esac
    
    return 0
}

check_args_nb()
{
    local count=0

    for frstArg in $@;
    do
        if echo $frstArg | grep -qe "^-";
        then
            check_args_valid $frstArg
        fi
        for secArg in $@;
        do
            if test $frstArg = $secArg;
            then
                 count=$(($count + 1))
            fi
        done
        if test $count -gt 1;
        then
            error_check 3
            return  1
        fi
        count=0 
    done

    return 0
}

tags_file()
{
    echo " Good execution "
    return 0
}

check_help()
{
    if test $1 = "--help";    #Check if the user correctly used --help 
    then
        if test $# = 1;
        then
            help $1
            exit 0
        else
            error_check 1
        fi
    fi
}

test_t()
{
    if test $1 = "-t";
    then
        if test $# -eq 2 -a -f $2 -a -e $2 -a -r $2;
        then
            tags_file $2
            exit 0
        else
            error_check 2
            exit 2
        fi
    fi
}


main()
{
    check_args_nb $@

    if test $? -eq 1;
    then
        exit 3
    fi

    case $# in
    0) error_check -1  #Check if there isn't any argument
        exit 1;;
    1) check_help $1 ;;
    *) echo "ok"
    esac
}


main $@


