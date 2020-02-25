#!/bin/dash

html=0
css=0
f=0
v=0
t=0
t_file=""
origin_directory=""
destination_directory=""

help()
{
    if test $1 = "--help" ; then
		echo "usage : ./minifier.sh [OPTION]... dir_source dir_dest \n"
		echo "Minifies HTML and/or CSS files with : "
		echo "\tdir_source\tpath to the root directory of the website to be minified"
		echo "\tdir_dest\tpath to the root directory of the minified website"
		echo "OPTIONS"
		echo "\t--help\t\tshow help and exit"
		echo "\t-v\t\tdisplays the list of minified files; and for each\n\t\t\tfile, its final and initial sizes, and its reduction\n\t\t\tpercentage"
		echo "\t-f\t\tif the dir_dest file exists, its content is\n\t\t\tremoved without asking for confirmation of deletion"
		echo "\t--css\t\tCSS files are minified"
		echo "\t--html\t\tHTML files are minified if none of the 2 previous options is present, the HTML and CSSfiles are minified\n"
		echo "\t-t tags_file the "white space" characters preceding and following thetags (opening or closing) listed in the ’tags_file’ are deleted"
	fi

	return 0
}

# error_check goal is to tell the user his error and always invite him to use --help

error_check()
{
    case $1 in
    -1) echo "Paths to ’dir_source’ and ’dir_dest’ directories must be specified";;
    1) echo "--help can only be used alone" ;;
    2) echo "Paths to the 'tags_file' must be specified";;
    3) echo "An argument can only appear once";;
    4) echo "The option $2 is not valid";;
    5) echo "Bad use : Only 2 directories needed, $2 is the third";;
    6) echo "Bad use : you need to have the options and then the directories, $2 is at a bad position";;
    7) echo "A readable file is needed, $2 is not readable";;
    8) echo "You need to give an Origin directory";;
    9) echo "You need to give a Destination directory";;
    10) echo "The origin directory needs to be followed by the destination directory";;
    esac

    echo "Enter \"./minifier.sh --help\" for more information."

    exit 1
    return 0
    
}

check_args_valid()
{
    case $1 in
    --help) echo "OK option --help" ;;
    --html) html=$(($html+1)) 
        return $html ;;
    -f) f=$(($f+1)) 
        return $f ;;
    -v) v=$(($v+1)) 
        return $v ;;
    -t) t=$(($t+1))
        return $t ;;
    --css) css=$(($css+1)) 
        return $css ;;
    *) error_check 4 $1
    esac
    
    return 0
}

check_args_nb()
{

    local check_order=0; # Add +1 when find a directory
    local was_t_before=0; # Put at 1 when the option -t was just before (and normaly it's a file)
    local dir_okay=0;

    for Args in $@;
    do

        # Management of the -t option 

        if test $was_t_before -eq 1;
        then
            if test -f $Args;
            then
                t_file="$Args";
                was_t_before=0
            else
                error_check 7 $Args
            fi
        fi

        # Management of all options

        if echo $Args | grep -qe "^-";
        then
            if test $check_order -eq 0;
            then
                if echo $Args | grep -qe "^-t";
                then
                    was_t_before=$(($was_t_before+1))
                fi

                check_args_valid $Args
                if test $? -gt 1;
                then
                    error_check 3 $Args
                fi
            else
                echo "$Args"
                error_check 10
            fi
        else
            if test $dir_okay -eq 1;
            then
                error_check 5 $Args
            fi
        fi

        # Management of the directories

        if test $check_order -eq 1;
        then
            destination_directory="$Args"
            check_order=0
            dir_okay=1
        fi

        if test -d $Args -a $dir_okay -eq 0;
        then
            check_order=1
            origin_directory="$Args"
        fi

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
            exit 1
        fi
    fi
}

check_all_needed()
{
    if test "$origin_directory" = "";
    then
        error_check 8
        exit 1
    fi

    if test "$destination_directory" = "";
    then
        error_check 9
        exit 1
    fi

    return 0
}

print_get()
{
    echo "You have enter the options :"
    if test $html -eq 1;
    then
        echo "-html"
    fi
    if test $css -eq 1;
    then
        echo "-css"
    fi
    if test $f -eq 1;
    then
        echo "-f"
    fi
    if test $v -eq 1;
    then
        echo "-v"
    fi
    if test $t -eq 1;
    then
        echo "-t and the file is $t_file"

    fi
    echo "The origin directory is : $origin_directory. The destination directory is : $destination_directory"
}

copy_all_files()
{
    mkdir "$2"
    for each_content in $(ls $1);
    do
        if test -d "$1/$each_content";
        then
            copy_all_files "$1/$each_content" "$2/$each_content"
        else
            cp "$1/$each_content" "$2/$each_content"
        fi
    done
}



check_destination()
{
    if test "$destination_directory" = "$origin_directory";
    then
        return 1
    fi
    if test -d $destination_directory -o -f $destination_directory;
    then
        echo -n "$destination_directory already exist, do you really want to delete it ? ____ "
        read user_val
        if test "$user_val" = "oui" -o "$user_val" = "yes";
        then
            rm -r $destination_directory
        else
            exit 0
        fi
    fi
    return 0
}

# HTML

linefeed_html()
{
	tr -s '\n' < $1 > temp.html
    rm $1
    mv temp.html $1
}

unuse_space_html()
{
	tr -s '[:space:]' ' ' < $1 > temp.html
    rm $1
    mv temp.html $1
}

remove_comment_html ()
{
	sed '/<!--/,/-->/g' < $1 > temp.html
    # sed -r s/'<!--*-->'/''/g < $1 > temp.html
    rm $1
    mv temp.html $1
}

remove_tag_space ()
{
    sed s/'> <'/'><'/g < $1 > temp.html
    rm $1
    mv temp.html $1
}

# CSS

linefeed_css()
{
	tr -s '\n' < $1 > temp.css
    rm $1
    mv temp.css $1
}

unuse_space_css()
{
	sed s/', '/'\,'/g < $1 > temp.css
    rm $1
    mv temp.css $1
}

# Minify function

minify_css()
{
    local origin_size=$(ls -l $1 | cut -f5 -d' ')

    linefeed_css $1
    unuse_space_css $1
    
    local final_size=$(ls -l $1 | cut -f5 -d' ')
    if test $origin_size -eq 0;
    then
        local compression_ratio=0
    else
        local ratio=$(($final_size * 100 / $origin_size * 100 / 100))
        local compression_ratio=$((100 - $ratio))
    fi
    if test $v -eq 1;
    then
        echo "File CSS : $1 --> $origin_size / $final_size : $compression_ratio %"
    fi
    return 0
}

minify_html()
{
    local origin_size=$(ls -l $1 | cut -f5 -d' ')

    linefeed_html $1
    unuse_space_html $1
    remove_comment_html $1
    # remove_tag_space $1
    
    local final_size=$(ls -l $1 | cut -f5 -d' ')
    if test $origin_size -eq 0;
    then
        local compression_ratio=0
    else
        local ratio=$(($final_size * 100 / $origin_size * 100 / 100))
        local compression_ratio=$((100 - $ratio))
    fi
    if test $v -eq 1;
    then
        echo "File HTML : $1 --> $origin_size / $final_size : $compression_ratio %"
    fi
    return 0
}

minify_dest()
{
    for search in $(ls $1);
    do
        if echo $search | grep -qe ".css$";
        then
            minify_css "$1/$search"
        fi

        if echo $search | grep -qe ".html$";
        then
            minify_html "$1/$search"
        fi

        if test -d "$1/$search";
        then
            minify_dest "$1/$search"
        fi 
    done
}

main()
{
    check_args_nb $@

    check_all_needed

    #print_get      #Can print all the entries from the user

    check_destination

    if test $? -eq 0;
    then
        copy_all_files $origin_directory $destination_directory
    fi

    minify_dest $destination_directory

}


main $@


