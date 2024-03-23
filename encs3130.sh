# Function to check if a file exists
read_file() {
    echo "Please input the name of the file:"
    read filename

    if [ -f "$filename" ]
    then
        echo "File exists"
        while true
        do
            echo "Do you want to print the file content? (yes/no)"
            read answer
            if [ "$answer" = "yes" ]
            then
                cat "$filename"
                return 0
            elif [ "$answer" = "no" ]
            then
                return 0
            else
                echo "Invalid response, please answer with 'yes' or 'no'."
            fi
        done
    else
        echo "File does not exist"
        return 1
    fi
}
# Function to calculate CPU usage stats
calculate_cpu_usage() {
    if ! read_file; then
        return
    fi

    total=0
    count=0
    max=-1
    min=101

    while IFS= read -r line
    do
        if [[ $line == *"CPU usage"* ]]; then
            cpu=$(echo $line | awk -F ' ' '{print $3}' | tr -d '%')
            total=$(echo "$total + $cpu" | bc)
            ((count++))

            if (( $(echo "$cpu > $max" | bc -l) )); then
                max=$cpu
            fi
            if (( $(echo "$cpu < $min" | bc -l) )); then
                min=$cpu
            fi
        fi
    done < "$filename"

    if ((count > 0)); then
        average=$(echo "scale=2; $total / $count" | bc)
        echo "Average CPU usage: $average%"
        echo "Maximum CPU usage: $max%"
        echo "Minimum CPU usage: $min%"
    else
        echo "No CPU usage data found in the file."
    fi
}
# Function to calculate received packets stats
calculate_received_packets() {
    if ! read_file; then
        return
    fi

    total=0
    count=0
    max=-1
    min=-1

    while IFS= read -r line
    do
        if [[ $line == *"Networks: packets:"* ]]; then
            packets_in=$(echo "$line" | awk -F 'packets:|/' '{print $2}' | awk '{print $1}')
            if [[ -n $packets_in && $packets_in =~ ^[0-9]+$ ]]; then
                total=$(echo "$total + $packets_in" | bc)
                ((count++))

                if ((packets_in > max)); then
                    max=$packets_in
                fi
                if ((min == -1)) || ((packets_in < min)); then
                    min=$packets_in
                fi
            fi
        fi
    done < "$filename"

    if ((count > 0)); then
        average=$(echo "scale=2; $total / $count" | bc)
        printf "Average received packets: %.2f\n" $average
        echo "Maximum received packets: $max"
        echo "Minimum received packets: $min"
    else
        echo "No received packets data found in the file."
    fi
}
# Function to calculate sent packets stats
calculate_sent_packets() {
    if ! read_file; then
        return
    fi
    sent_packets=$(grep 'Networks:' "$filename" | awk -F'[/ ]' '{print $6}' | sort -n)

    sum=0
    count=0
    for sent in $sent_packets; do
        sum=$((sum + sent))
        count=$((count + 1))
    done
    average=$(printf "%.2f" $(echo "scale=2; $sum / $count" | bc))
    minimum=$(echo "$sent_packets" | awk 'NR==1')
    maximum=$(echo "$sent_packets" | awk 'END{print}')

    echo "Average sent packets: $average"
    echo "Minimum sent packets: $minimum"
    echo "Maximum sent packets: $maximum"
}

get_commands() {
  local file_contents=$(<"$1")  # Read the file contents into a variable
  commands=""
  local read=false

  IFS=$'\n'  


  readarray -t lines <<< "$file_contents"

  # Loop through the lines
  for ((i=0; i<${#lines[@]}; i++)); do
    line="${lines[i]}"

    if [[ $line == Processes* ]]; then
      read=false
    fi

    if $read; then
      commands+="$line"$'\n'
    fi

    if [[ $line == PID* ]]; then
      read=true
    fi
  done

  
}



isolate_max_cpu_usage() {

    # Fetch the process details using ps command
    #process_details=$(ps aux)

    # Identify the CPU time column from the process details
    cpuTime=$(echo "$commands" | awk '{ for (j=1; j<=NF; j++) { if ($j ~ /^[0-9]+\.[0-9]+$/) { print $j; break } } }')

    # Consolidate the CPU time column with the first column of process details
    commands=$(paste <(echo "$cpuTime") <(echo "$commands"))

    # Arrange the process details in reverse order based on CPU time
    commands=$(echo "$commands" | sort -nrk1)

    tracker=0
    
    commands=$(echo "$commands" | awk '{tracker=0; for (i=2; i<=NF; i++) { if ($i ~ /^[0-9]+(\.[0-9]+)?$/ && tracker < 2) { printf " %s  ", $i; tracker++ } else if (tracker == 2) { print ""; break } else{ printf "%s ", $i } } }')

    # Isolate and print the top 'm' entries from process details
    commands=$(echo "$commands" | head -n "$1")

    echo "******************************************************"
    echo "$commands"
    echo "******************************************************"
}



top_command_memory() {
get_commands "top.txt"
    # Extract the column containing memory usage
    memory=$(echo "$commands" | tr -d '/+-' | awk '{
        count=0;
        for (i=2; i<=NF; i++) {
            if ($i ~ /^[0-9]+[kKmMgGbB]?$/) {
                if (count < 3) {
                    count++;
                } else {
                    print $i;
                    break;
                }
            }
        }
    }')

    # Convert memory usage to bytes
    memory_bytes=$(echo "$memory" | awk '{
        if ($1 ~ /[kK]$/) {
            printf "%d\n", $1 * 1024;
        } else if ($1 ~ /[mM]$/) {
            printf "%d\n", $1 * 1024 * 1024;
        } else if ($1 ~ /[gG]$/) {
            printf "%d\n", $1 * 1024 * 1024 * 1024;
        } else if ($1 ~ /[bB]$/) {
            printf "%d\n", $1;
        }
    }')

    # Add memoryColumn and memoryColumn_bytes to the first column of pid_lines
    commands=$(paste <(echo "$memory") <(echo "$commands"))
    commands=$(paste <(echo "$memory_bytes") <(echo "$commands"))

    # Sort the lines in descending order based on memory usage
    commands=$(echo "$commands" | sort -nrk1)


    memory=$(echo "$memory_bytes")

    # Sort the lines in descending order based on memory bytes
    memory=$(echo "$memory" | sort -nrk1)
}

max_memory() {
top_command_memory
    count=0
    awk_command='{
        count=1;
        for (i=3; i<=NF; i++) {
            if ($i ~ /^[0-9]+(\.[0-9]+)?$/) {
                if (count < 2) {
                    printf " %s  ", $i;
                    count++;
                } else if (count == 2) {
                    print "";
                    break;
                }
            } else {
                printf "%s ", $i;
            }
        }
    }'
    
    commands=$(echo "$commands" | awk "$awk_command")

    commands=$(paste <(echo "$commands") <(echo "$memory"))

    commands=$(echo "$commands" | head -n "$1")

    echo "******************************************************"
    echo "$commands"
    echo "******************************************************"

}

min_memory() {
top_command_memory
commands=$(echo "$commands" | sort -nk1)
memory=$(echo "$memory" | sort -nk1)
    
    count=0
    awk_command='{
        count=1;
        for (i=3; i<=NF; i++) {
            if ($i ~ /^[0-9]+(\.[0-9]+)?$/) {
                if (count < 2) {
                    printf " %s  ", $i;
                    count++;
                } else if (count == 2) {
                    print "";
                    break;
                }
            } else {
                printf "%s ", $i;
            }
        }
    }'
    
    commands=$(echo "$commands" | awk "$awk_command")

    commands=$(paste <(echo "$commands") <(echo "$memory"))

    commands=$(echo "$commands" | head -n "$1")

    echo "******************************************************"
    echo "$commands"
    echo "******************************************************"
}



# Main menu loop
while true
do
    echo "Select an option to run the top statistics project:"
    echo "r) read top output file"
    echo "c) average, minimum, and maximum CPU usage"
    echo "i) average, minimum, and maximum received packets"
    echo "o) average, minimum, and maximum sent packets"
    echo "u) commands with the maximum average CPU"
    echo "a) commands with the maximum average memory usage"
    echo "b) commands with the minimum average memory usage"
    echo "e) exit"
    
    read option

    case "$option" in
        r) read_file ;;
        c) calculate_cpu_usage ;;
        i) calculate_received_packets ;;
        o) calculate_sent_packets ;;
        u)  read -p "Please enter an integer: " m
 		 if [[  $m =~ ^[0-9]+$ ]]; then
		  get_commands "top.txt"
                  isolate_max_cpu_usage "$m"
          else
          echo "Invalid input"
 		 fi 
       ;;
        a)  read -p "Please enter an integer: " m
 		 if [[  $m =~ ^[0-9]+$ ]]; then
                  max_memory "$m"
          else
          echo "Invalid input"
 		 fi ;;
        b) read -p "Please enter an integer: " m
 		 if [[  $m =~ ^[0-9]+$ ]]; then
                  min_memory "$m"
          else
          echo "Invalid input"
 		 fi ;;
        e) 
            echo "Are you sure you want to exit? (yes/no)"
            read confirm_exit
            if [ "$confirm_exit" == "yes" ]; then
                exit 0
            fi
            ;;
        *) echo "Invalid option. Please select a valid one." ;;
    esac
done
