#!/bin/dash

###########################################################
################ VARIABLE INITIALISATION ##################
###########################################################

html=0
css=0
f=0
v=0
t=0
t_file=""
origin_directory=""
destination_directory=""
t_file_content="";

###########################################################
##################### HELP FUNCTION #######################
###########################################################

# The parameter $1 of the help function is normaly the option --help. This is a double verification
# system. She juste normaly print with some echo the help for the user. 

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
	
	exit 0
	return 0
}

###########################################################
#################### PRINT THE ERRORS #####################
###########################################################

# error_check goal is to tell the user his error and always invite him to use --help
# She only needs one argument $1 which is the error number. It aims to echo the good error message

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
    11) echo "The destination directory needs to be different from the origin direction"
    esac

    echo "Enter \"./minifier.sh --help\" for more information."

    exit 1
    return 0
    
}

##########################################################
############## ALL CHECK AND TEST FUNCTION ###############
##########################################################

# This function is made to increment the correct variable. The argument $1 is the option.
# If the option isn't good, the user will see the correct error message through out the error_check function

check_args_valid()
{
    case $1 in
    --help) help ;;
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

# This function take all the arguments that the user put when he wrote the function
# and then she looks at all of them and check each one.

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
                t_file_content=$(cat $Args)
                was_t_before=0
                return 0
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

# Check if both directories are ok, no arguments needed

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

# Check if the destination is ok, no argument needed

check_destination()
{
    if test "$destination_directory" = "$origin_directory";
    then
        return 1
    fi
    if test -d $destination_directory -o -f $destination_directory;
    then
        if test $f -gt 0;
        then
            rm -r $destination_directory
        else
            echo -n "$destination_directory already exist, do you really want to delete it ? ____ "
            read user_val
            if test "$user_val" = "oui" -o "$user_val" = "yes" -o "$user_val" = "y" -o "$user_val" = "o";
            then
                rm -r $destination_directory
            else
                exit 0
            fi
        fi
    fi
    return 0
}

# The aim is to minify only the selected file types, no arguments needed

html_css_check()
{
    if test $html -eq 0 -a $css -eq 1;
    then
        html=-1;
    fi
    if test $html -eq 1 -a $css -eq 0;
    then
        css=-1;
    fi
}

##########################################################
##################### COPY FUNCTION ######################
##########################################################

 # Recursive function that copies files, the arguments arge, the original directory ($1) 
 # and the destination directory ($2)

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

##########################################################
########################## HTML ##########################
##########################################################

# Delete the \n in the file, the argument is the file path

linefeed_html()
{
	tr -s '\n' < $1 > $destination_directory/temp.html # Delete the \n in the file and put the result in a temporary file
    rm $1   # Delete the original file
    mv $destination_directory/temp.html $1  # change the name and the place of the temporary file to replace the original one
}

# Replace the consecutives spaces by only one space in the file, the argument is the file path

unuse_space_html()  # Delete the useless spaces
{
	tr -s '[:space:]' ' ' < $1 > $destination_directory/temp.html
    rm $1
    mv $destination_directory/temp.html $1
}

# Remove the comment in the file, the argument is the file path

remove_comment_html ()
{
	sed 's/<!--[^>]*>//g' < $1 > $destination_directory/temp.html # /!\ [^>] is important because if not put, the pattern take from the first to the last comment
    rm $1
    mv $destination_directory/temp.html $1
}

# Put all the tags to lower cases in the file, the argument is the file path

put_lo_tags ()  # The aim of this function is to put all the tags to lower case. To compare with tags in the t-file
{
    sed 's/<[^>]*>/\L&/g' < $1 > $destination_directory/temp.html
    rm $1
    mv $destination_directory/temp.html $1
}

###########################################################
########################### CSS ###########################
###########################################################

# Same as the html one

linefeed_css()
{
	tr -d '\n' < $1 > $destination_directory/temp.css # Delete the \n in the file and put the result in a temporary file
    rm $1   # Delete the original file
    mv $destination_directory/temp.css $1   # change the name and the place of the temporary file to replace the original one
}

# Same as the html one

unuse_space_css()   # remove the useless spaces
{
	sed s/', '/'\,'/g < $1 > $destination_directory/temp.css
    rm $1
    mv $destination_directory/temp.css $1
}

# Same as the html one

remove_comment_css () # Remove the comment of the css file
{
    perl -pe 's|\/\*(.*?)\*\/||g' < $1 > $destination_directory/temp.css
    rm $1
    mv $destination_directory/temp.css $1
}

# Remove all differents types of unuse spaces that do not change the file execution

remove_space_css () # Remove the unuse spaces after {, after : and after ;
{
    sed s/'{[ ]*'/'{'/g < $1 > $destination_directory/temp.html
    rm $1
    mv $destination_directory/temp.html $1
    sed s/':[ ]*'/':'/g < $1 > $destination_directory/temp.html
    rm $1
    mv $destination_directory/temp.html $1
    sed s/';[ ]*'/';'/g < $1 > $destination_directory/temp.html
    rm $1
    mv $destination_directory/temp.html $1
    sed s/'[ ]*{'/'{'/g < $1 > $destination_directory/temp.html
    rm $1
    mv $destination_directory/temp.html $1
    sed s/'[ ]*>[ ]*'/'>'/g < $1 > $destination_directory/temp.html
    rm $1
    mv $destination_directory/temp.html $1
    sed s/')[ ]*'/'('/g < $1 > $destination_directory/temp.html
    rm $1
    mv $destination_directory/temp.html $1
}

# Remove the tab from the file

tabfeed_css()
{
	tr -d '\t' < $1 > $destination_directory/temp.css # Delete the \n in the file and put the result in a temporary file
    rm $1   # Delete the original file
    mv $destination_directory/temp.css $1   # change the name and the place of the temporary file to replace the original one
}

############################################################
################### APPLICATION OF T FILE ##################
############################################################

# This function execute the t option by clearing the spaces before and after the tags contained in
# the "t-file", the argument is the file (.html)

apply_t_file ()
{
    for line in $t_file_content; # browse the content of the variable which itself contains the content of the t-file
    do 
        sed "s/[ ]*<$line>[ ]*/<$line>/g" < $1 > $destination_directory/temp.html # Open tag
        rm $1
        mv $destination_directory/temp.html $1
        sed "s/[ ]*<\/$line>[ ]*/<\/$line>/g" < $1 > $destination_directory/temp.html # Close tag
        rm $1
        mv $destination_directory/temp.html $1
    done
    return 0
}

###########################################################
##################### MINIFY FUNCTION #####################
###########################################################

# Function which minify the css file, the function uses all the function we wrote before,
# the only argument is the file path

minify_css()
{
    local origin_size=$(ls -l $1 | cut -f5 -d' ')

    linefeed_css $1
    unuse_space_css $1
    remove_comment_css $1
    remove_space_css $1
    tabfeed_css $1
    
    local final_size=$(ls -l $1 | cut -f5 -d' ')
    if test $origin_size -eq 0;
    then
        local compression_ratio=0
    else
        local ratio=$(($final_size * 100 / $origin_size * 100 / 100)) # There is a problem with the float / double so I use a multiplication by 100
        local compression_ratio=$((100 - $ratio))
    fi
    if test $v -eq 1; # If the option v is active, the program print the compretion ratio and the file name
    then
        echo "File CSS : $1 --> $origin_size / $final_size : $compression_ratio %"
    fi
    return 0
}

# Function which minify the hmtl file, the function uses all the function we wrote before,
# the only argument is the file path

minify_html() 
{
    local origin_size=$(ls -l $1 | cut -f5 -d' ')

    linefeed_html $1
    unuse_space_html $1
    remove_comment_html $1
    put_lo_tags $1

    if test $t -eq 1;
    then
        apply_t_file $1
    fi
    
    local final_size=$(ls -l $1 | cut -f5 -d' ')
    if test $origin_size -eq 0;
    then
        local compression_ratio=0
    else
        local ratio=$(($final_size * 100 / $origin_size * 100 / 100)) # There is a problem with the float / double so I use a multiplication by 100
        local compression_ratio=$((100 - $ratio))
    fi
    if test $v -eq 1;
    then
        echo "File HTML : $1 --> $origin_size / $final_size : $compression_ratio %"
    fi
    return 0
}

 # Function that browse the directory to minify files, she cares about the options --css and --hmtl 

minify_dest()
{
    for search in $(ls $1);
    do
        if echo $search | grep -qe ".css$";
        then
            if test $css -gt -1;
            then
                minify_css "$1/$search"
            fi
        fi

        if echo $search | grep -qe ".html$";
        then
            if test $html -gt -1;
            then
                minify_html "$1/$search"
            fi
        fi

        if test -d "$1/$search";
        then
            minify_dest "$1/$search"
        fi 
    done
}

##########################################################
######################## PRINTER #########################
##########################################################

# We decided to leave this function here because she is usefull when you want to do some
# tests and see the options the user used

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

##########################################################
########################## MAIN ##########################
##########################################################

# Main function which will call all the other, the argument is $@ (so all)

main()
{
    check_args_nb $@

    check_all_needed

    #print_get      #Can print all the entries from the user

    check_destination

    if test $? -eq 0;
    then
        copy_all_files $origin_directory $destination_directory
    else
        error_check 11
        exit 0
    fi

    html_css_check

    minify_dest $destination_directory

}


main $@ # call of the main function
