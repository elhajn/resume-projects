#!/bin/bash

# SAVE FUNCTION - create a function that saves the contents of the argument (a variable) to a file
saveFile() {
    read -ep "Provide file name (no extension): " FILE_NAME
    printf "%s\n" "$@" >> "${FILE_NAME}.txt"
}

# MAIN MENU - prompt user to select a data file type or exit
read -ep "Welcome! Please select an action: 
        FASTA - Download FASTA file 
        FASTQ - Download FASTQ file
        EXIT - End the program 
        >> " MAIN_MENU

# MAIN WHILE LOOP - unless the user inputs 'EXIT' when prompted, the script will run through the commands associated with each file type infinitely
while [ $MAIN_MENU != "EXIT" ]; do

    # FASTA - if the user inputs 'FASTA' at the main menu (line 9)
    if [ $MAIN_MENU == "FASTA" ]; then
        
        # DATA DOWNLOAD - prompt the user for the appropriate database & accession number, then retrieve the data
        read -ep "Please provide the database and NCBI accession number: " NCBIdb NCBIacc
        efetch -db $NCBIdb -id $NCBIacc -format fasta > $NCBIacc.fasta

        # ERROR HANDLING - if the download fails, prompt the user to reenter their request or return to the main menu and make a new selection
        EXIT_CODE=$?

        if [ $EXIT_CODE -eq 400 ]; then
            read -ep "An error occurred. Would you like to:
            RETRY - Try again
            BACK - Return to main menu
            >> " ERROR_HAND

            if [ $ERROR_HAND == "RETRY" ]; then
                read -ep "Please provide the database and NCBI accession number: " NCBIdb NCBIacc
                efetch -db $NCBIdb -id $NCBIacc -format fasta > $NCBIacc.fasta
            else
                read -ep "Welcome back! Please select an action: 
        FASTA - Download FASTA file 
        FASTQ - Download FASTQ file
        EXIT - End the program 
        >> " MAIN_MENU
                continue
            fi
        fi

        # DATA PROCESSING - prompt user to select their desired data processing tool
        read -ep "Please select an action:
        ALLATT - Print all attributes
        REVCOMP - Compute Reverse Complement
        SEQLEN - Calculate Sequence Length
        RETMEN - Return to Main Menu 
        >> " SUB_MENU

        # SUB WHILE LOOP - unless the user inputs 'RETMEN' when prompted, will loop through associated data processing commands infinitely
        while [ $SUB_MENU != "RETMEN" ]; do

            # DATA OUTPUT - prompt user to select data output method
            read -ep "Would you like to:
        PRINT - Display the results on your screen
        SAVE - Download the results to a file 
        >> " OUTPUT_MODE

            # data processing commands if user selects to display on screen
            if [ $OUTPUT_MODE == "PRINT" ]; then
                if [ $SUB_MENU == "ALLATT" ]; then
                    bioawk -c fastx '{print "Name: " $name "\nSequence: " $seq}' $NCBIacc.fasta
                elif [ $SUB_MENU == "REVCOMP" ]; then
                    bioawk -c fastx '{print "Name: " $name "\nReverse Complement: " revcomp($seq)}' $NCBIacc.fasta
                elif [ $SUB_MENU == "SEQLEN" ]; then
                    bioawk -c fastx '{print "Name: " $name "\nSequence Length: " length($seq)}' $NCBIacc.fasta
                else
                    echo "Invalid input. Please try again."
                fi

            # data output commands if user selects to save data to file
            elif [ $OUTPUT_MODE == "SAVE" ]; then
                if [ $SUB_MENU == "ALLATT" ]; then
                    FASTAatt="$(bioawk -c fastx '{print "Name: " $name "\nSequence: " $seq}' ${NCBIacc}.fasta)"
                    saveFile "$FASTAatt"
                elif [ $SUB_MENU == "REVCOMP" ]; then
                    FASTArev="$(bioawk -c fastx '{print "Name: " $name "\nReverse complement: " revcomp($seq)}' ${NCBIacc}.fasta)" 
                    saveFile "$FASTArev"
                elif [ $SUB_MENU == "SEQLEN" ]; then
                    FASTAlen="$(bioawk -c fastx '{print "Name: " $name "\nSequence Length: " length($seq)}' ${NCBIacc}.fasta)"
                    saveFile "$FASTAlen"
                else
                    echo "Invalid input. Please try again."
                fi
            fi

            # NEXT STEP - prompt user to continue processing current data or return to main menu
            read -ep "Would you like to:
        PROCESS - Perform another action on the data
        BACK - Return to the main menu
        >> " NEXT_OPTION

            if [ $NEXT_OPTION == "PROCESS" ]; then
                read -ep "Please select an action:
        ALLATT - Print all attributes
        REVCOMP - Compute Reverse Complement
        SEQLEN - Calculate Sequence Length
        RETMEN - Return to Main Menu 
        >> " SUB_MENU
            else
                break
            fi
        done

    # FASTQ - if the user inputs 'FASTQ' at the main menu (line 9)
    elif [ $MAIN_MENU == "FASTQ" ]; then
        
        # DATA DOWNLOAD - prompt the user for the appropriate accession number, then retrieve the data
        read -ep "Please provide an SRA accession number: " SRAacc
        prefetch $SRAacc
        fasterq-dump ./$SRAacc > $SRAacc.fastq
        
        # ERROR HANDLING - if the download fails, prompt the user to reenter their request or return to the main menu and make a new selection
        EXIT_CODE=$?

        if [ $EXIT_CODE -ne 0 ]; then
            read -ep "An error occurred. Would you like to:
            RETRY - Try again
            BACK - Return to main menu
            >> " ERROR_HAND

            if [ $ERROR_HAND == "RETRY" ]; then
                read -ep "Please provide an SRA accession number: " SRAacc
                prefetch $SRAacc
                fasterq-dump ./$SRAacc > $SRAacc.fastq
            else
                read -ep "Welcome back! Please select an action: 
        FASTA - Download FASTA file 
        FASTQ - Download FASTQ file
        EXIT - End the program 
        >> " MAIN_MENU
                continue
            fi
        fi

        # DATA PROCESSING - prompt user to select their desired data processing tool
        read -ep "Please select an action:
        ALLATT - Print all attributes
        REVCOMP - Compute Reverse Complement
        SEQLEN - Calculate Sequence Length
        AVGQS - Compute Average Quality Score
        RETMEN - Return to Main Menu 
        >> " SUB_MENU

        # SUB WHILE LOOP - unless the user inputs 'RETMEN' when prompted, will loop through associated data processing commands infinitely
        while [ $SUB_MENU != "RETMEN" ]; do

            # DATA OUTPUT - prompt user to select data output method
            read -ep "Would you like to:
        PRINT - Display the results on your screen
        SAVE - Download the results to a file
        >> " OUTPUT_MODE

            # data processing commands if user selects to display on screen
            if [ $OUTPUT_MODE == "PRINT" ]; then

                if [ $SUB_MENU == "ALLATT" ]; then
                    bioawk -c fastx '{print "\nName: " $name "\nSequence: " $seq "\nQuality: " $qual "\nComment: " $comment}' $SRAacc.fastq
                elif [ $SUB_MENU == "REVCOMP" ]; then
                    bioawk -c fastx '{print "\nName: " $name "\nReverse complement: " revcomp($seq)}' $SRAacc.fastq
                elif [ $SUB_MENU == "SEQLEN" ]; then
                    bioawk -c fastx '{print "\nName: " $name "\nSequence Length: " length($seq)}' $SRAacc.fastq
                elif [ $SUB_MENU == "AVGQS" ]; then
                    bioawk -c fastx '{print "\nName: " $name "\nSequence: " $seq "\nAverage QS: " meanqual($qual)}' $SRAacc.fastq
                else
                    echo "Invalid input. Please try again."
                fi

            # data output commands if user selects to save data to file
            elif [ $OUTPUT_MODE == "SAVE" ]; then
                if [ $SUB_MENU == "ALLATT" ]; then
                    FASTQatt="$(bioawk -c fastx '{print "\nName: " $name "\nSequence: " $seq "\nQuality: " $qual "\nComment: " $comment}' ${SRAacc}.fastq)" 
                    saveFile "$FASTQatt"
                elif [ $SUB_MENU == "REVCOMP" ]; then
                    FASTQrev="$(bioawk -c fastx '{print "\nName: " $name "\nReverse complement: " revcomp($seq)}' ${SRAacc}.fastq)"
                    saveFile "$FASTQrev"
                elif [ $SUB_MENU == "SEQLEN" ]; then
                    FASTQlen="$(bioawk -c fastx '{print "\nName: " $name "\nSequence Length: " length($seq)}' ${SRAacc}.fastq)"
                    saveFile "$FASTQlen"
                elif [ $SUB_MENU == "AVGQS" ]; then
                    FASTQqs="$(bioawk -c fastx '{print "\nName: " $name "\nSequence: " $seq "\nAverage QS: " meanqual($qual)}' ${SRAacc}.fastq)"
                    saveFile "$FASTQqs"
                else
                    echo "Invalid input. Please try again."
                fi
            fi

            # NEXT STEP - prompt user to continue processing current data or return to main menu
            read -ep "Would you like to:
        PROCESS - Perform another action on the data
        BACK - Return to the main menu
        >> " NEXT_OPTION

            if [ $NEXT_OPTION == "PROCESS" ]; then
            read -ep "Please select an action:
        ALLATT - Print all attributes
        REVCOMP - Compute Reverse Complement
        SEQLEN - Calculate Sequence Length
        AVGQS - Compute Average Quality Score
        RETMEN - Return to Main Menu 
        >> " SUB_MENU

        else
            break
        fi
        done
    else
        echo "Invalid input. Please try again."
    fi
    
    # update while loop condition
    read -ep "Welcome back! Please select an action: 
        FASTA - Download FASTA file 
        FASTQ - Download FASTQ file
        EXIT - End the program 
        >> " MAIN_MENU
done

# parting message to user once they choose to quit the program
echo "Thank you for using our program. Goodbye!"