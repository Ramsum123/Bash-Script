#!/bin/bash
#### GLOBAL VARIABLES
	toadd=0.10
	tosub=0.05
        maxmarp=0.90
        minmarp=0.10
	marpthirty=0.30
	default_value=0

while true; do
#### FUNCTION TO INCREMENT MARP VALUE
increment () {
       newmarp=$(echo $marp $toadd | awk '{printf "%0.2f", $1 + $2}')
#       echo "marp to submit is" $newmarp
       awk 'NR==26{$2=a}1' a=$newmarp $file > tmp && sudo mv -f tmp $file
       yarn rmadmin -refreshQueues
	echo "MARP Increment by 0.10 and the new MARP is " $newmarp
	}

#increment

#### FUNCTION TO DECREMENT MARP VALUE
decrement () {
	newmarp=$(echo $marp $tosub | awk '{printf "%0.2f", $1 - $2}')
#        echo "marp to submit is" $newmarp
        awk 'NR==26{$2=a}1' a=$newmarp $file > tmp && sudo mv -f tmp $file
        yarn rmadmin -refreshQueues
	echo "MARP Decrement by 0.05 and the new MARP is" $newmarp
	}

#decrement

#### FUNCTION TO ALLOCATE 40% RESOURCES TO APPLICATION MASTER
marp_thirty () {
awk 'NR==26{$2=a}1' a=$marpthirty $file > tmp && sudo mv -f tmp $file
yarn rmadmin -refreshQueues
echo "MARP set to" $marpthirty
}



#### FUNCTION WHICH FETCH METRICES FROM RESOURCE MANAGER
fetch_metrics () {

	#### TOTAL MEMORY IN A CLUSTER
        tot_mem=$(curl http://project-master-01:8088/ws/v1/
cluster/metrics | awk -F':' '{print $18}' | awk -F',' '{print $1}')

        #### MEMORY USED IN THE CLUSTER DURING JOB EXECUTION
        mem_used=$( curl http://project-master-01:8088/ws/v1/
cluster/scheduler | awk -F':' '{print $22}' | cut -d',' -f1)

        #### UNUSED MEMORY IN THE CLUSTER
        mem_unused=$(curl http://project-master-01:8088/ws/v1/
cluster/metrics | awk -F':' '{print $10}' | awk -F',' '{print $1}')

        ####TOTAL MEMORY ALLOCATED BY MARP VALUE
        marp_limit=$( curl http://project-master-01:8088/ws/v1/
cluster/scheduler | awk -F':' '{print $55}' | cut -d',' -f1)

	#### TOTAL MEMORY USED BY APPLICATION MASTER
	am_mem_used=$(curl http://project-master-01:8088/ws/v1/
cluster/scheduler | awk -F':' '{print $52}' | cut -d',' -f1)

	#### TOTAL VCORES USED BY APPLICATION MASTER
	am_vcore_used=$(curl http://project-master-01:8088/ws/v1/
cluster/scheduler | awk -F':' '{print $53}' | 
cut -d',' -f1 | awk -F'}' '{print $1}')

        ####TOTAL NUMBER OF VIRTUAL CORE IN THE CLUSTER
        tot_core=$(curl http://project-master-01:8088/ws/v1/
cluster/metrics | awk -F':' '{print $19}' | awk -F',' '{print $1}')

        ####USED NUMBER OF CORE DURING JOB EXECUTION
        core_used=$(curl http://project-master-01:8088/ws/v1/
cluster/metrics | awk -F':' '{print $14}' | awk -F',' '{print $1}')

        ####UNUSED VIRTUAL CORE
        core_unused=$(curl http://project-master-01:8088/ws/v1/
cluster/metrics | awk -F':' '{print $13}' | awk -F',' '{print $1}')

        ####NUMBER OF APPLICATION RUNNING IN THE CLUSTER
        app_running=$(curl http://project-master-01:8088/ws/v1/
cluster/metrics | awk -F':' '{print $6}' | awk -F',' '{print $1}')

        ####NUMBER OF APPLICATION PENDING IN THE CLUSTER
        app_pending=$(curl http://project-master-01:8088/ws/v1/
cluster/metrics | awk -F':' '{print $5}' | awk -F',' '{print $1}')
	echo "$app_pending" > pending_app.txt
        ####CONTAINER RUNNING
        cont_running=$(curl http://project-master-01:8088/ws/v1/
cluster/metrics | awk -F':' '{print $15}' | awk -F',' '{print $1}')

        ####CONTAINER PENDING
        cont_pending=$(curl http://project-master-01:8088/ws/v1/
cluster/metrics | awk -F':' '{print $17}' | awk -F',' '{print $1}')

	####TOTAL CAPACITY USED IN THE CLUSTER
        capacity_used=$(curl http://project-master-01:8088/ws/v1/
cluster/scheduler | awk -F':' '{print $6}' | cut -d',' -f1)
		}

#### FUNCTION TO CALCULATE PROGRESS FOR 10% RESOURCE ALLOCATION
progress_first () {

app_id=$(yarn application -list | grep "root" | grep "RUNNING" | awk '{print $1}') 
value_initially=$(yarn application -list | grep "root" | 
grep "RUNNING" | awk '{print $8 $9}'| cut -d '%' -f1 | 
awk -F'.' '{print $1}'| awk -F'[^0-9]*' '{print $1 $2}')

while [[ "${#app_id[@]}" != "${#value_initially[@]}" ]]; do
	app_id=()
	value_initially=()
	app_id=$(yarn application -list | grep "root" |
 grep "RUNNING" | awk '{print $1}') 
	value_initially=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $8 $9}'| cut -d '%' -f1 | 
awk -F'.' '{print $1}'| awk -F'[^0-9]*' '{print $1 $2}')
done

echo "$app_id" > progress_first_only_app_id.txt
echo "$value_initially" > progress_first_only_value.txt

	pre_id_only=($(paste <(echo "$app_id")))
	echo "PREVIOUS APP ONLY ID"
	echo "${pre_id_only[@]}"

	pre_value_only=($(paste <(echo "$value_initially")))
	echo "PREVIOUS APP ONLY VALUE"
	echo "${pre_value_only[@]}"


	pre_id_value=$(paste <(echo "$app_id") <(echo "$value_initially"))
	echo "PREVIOUS APP ID AND CORRESPONDING VALUES"
	echo "$pre_id_value"

	progress_initial=0
	for i in ${pre_value_only[@]}
  	  do
	     progress_initial=`echo $progress_initial + $i | bc`
	done

	echo $progress_initial > progress1.txt
	echo "The initial progress is" $progress_initial
	}



#### FUNCTION TO CALCULATE PROGRESS FOR 20% RESOURCE ALLOCATION
progress_second () {
app_id_current=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $1}') 
value_current=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $8 $9}'| 
cut -d '%' -f1 | awk -F'.' '{print $1}'| awk -F'[^0-9]*' '{print $1 $2}')
while [[ "${#app_id_current[@]}" != "${#value_current[@]}" ]]; do
	app_id_current=()
        value_current=()
	app_id=$(yarn application -list | grep "root" |
 grep "RUNNING" | awk '{print $1}') 
	value_initially=$(yarn application -list | 
grep "root" | grep "RUNNING" | awk '{print $8 $9}'|
cut -d '%' -f1 | awk -F'.' '{print $1}'| awk -F'[^0-9]*' '{print $1 $2}')
done
echo "$app_id_current" > progress_second_only_app_id.txt
echo "$value_current" > progress_second_only_value.txt

app_id=$(sudo cat /home/ramesh/progress_first_only_app_id.txt)
value_initially=$(sudo cat /home/ramesh/progress_first_only_value.txt)

curr_id_only=($(paste <(echo "$app_id_current")))
echo "CURRENT APP ONLY ID"
echo "${curr_id_only[@]}"

curr_value_only=($(paste <(echo "$value_current")))
echo "CURRENT APP ONLY VALUE"
echo "${curr_value_only[@]}"

curr_id_value=$(paste <(echo "$app_id_current") <(echo "$value_current"))
echo "CURRENT APP ID AND CORRESPONDING VALUES"
echo "$curr_id_value"

##
pre_id_only=($(paste <(echo "$app_id")))
echo "PREVIOUS APP ONLY ID"
echo "${pre_id_only[@]}"

pre_value_only=($(paste <(echo "$value_initially")))
echo "PREVIOUS APP ONLY VALUE"
echo "${pre_value_only[@]}"


##

#different=$(diff <( echo "$app_id" ) <( echo "$app_id_current" ))
different=$(diff -ia --suppress-common-lines 
<( printf "%s\n" "${app_id[@]}" ) <( printf "%s\n" "${app_id_current[@]}"))
echo "DIFFERENCE BETWEEN THE APPLICATION 
IDS IN THE CURRENT STATE, WHETHER LOST OR ADDED ARE"
#echo ${different[@]}

for i in ${different[@]}
do
echo $i | grep "application_" | awk '{print $1}' >> app_id_changed.txt
done
fetch_file_data=$(sudo cat /home/ramesh/app_id_changed.txt)
echo ${fetch_file_data[@]}

sudo truncate -s 0 app_id_changed.txt


#####################################
#intersection_with_current
####################################
for item1 in ${app_id_current[@]}
 do
    for item2 in ${fetch_file_data[@]}
      do
        if [[ "$item1" == "$item2" ]]
	 then
            intersection_with_current+=( "$item1" )
        fi
    done
done
echo "FOLLOWING APPS ARE NEWELY ADDED"
echo ${intersection_with_current[@]}
#############################################
#TO ADD THE VALUES OF THE NEWELY ADDED JOB
#############################################

for ((i=0; i < ${#curr_id_only[@]}; ++i))
   do
	for j in "${intersection_with_current[@]}"
	  do
		if [[ "${curr_id_only[$i]}" == "$j" ]]
		then

			index_arr_curr+=( "$i" )
		fi
	done
  done

echo "The list of the index for newely added jobs are"
echo ${index_arr_curr[@]}

########################

for ((i=0; i < ${#curr_value_only[@]}; ++i))
 do
	for j in "${index_arr_curr[@]}"
	 do
		if [[ "$i" == "$j" ]]
		then
			sum_newly_added+=( "${curr_value_only[$i]}" )
		fi
	done
done
echo "The array of the value corresponding are"
echo ${sum_newly_added[@]}

##########################
sum1=0
for i in ${sum_newly_added[@]}
 do
	sum1=`echo $sum1 + $i | bc`
 done
echo "The total sum of the currently added job progress is" $sum1


##########################
#intersection_with_previous
##########################
for item1 in ${app_id[@]}
 do
    for item2 in ${fetch_file_data[@]}
      do
        if [[ "$item1" == "$item2" ]]
         then
            intersection_with_previous+=( "$item1" )
        fi
    done
done


echo "FOLLOWING APPS WERE IN PREVIOUS BUT NOT IN CURRENT"
echo ${intersection_with_previous[@]}

###########################
# ADD THE VALUES SUBTRACTIONG FROM 100
###########################

for ((i=0; i < ${#pre_id_only[@]}; ++i))
   do
        for j in "${intersection_with_previous[@]}"
          do
                if [[ "${pre_id_only[$i]}" == "$j" ]]
                then

                        index_arr_pre+=( "$i" )
                fi
        done
  done

echo "The list of the index for 
previous jobs which are not in current job list are"
echo ${index_arr_pre[@]}

########################

for ((i=0; i < ${#pre_value_only[@]}; ++i))
 do
        for j in "${index_arr_pre[@]}"
         do
                if [[ "$i" == "$j" ]]
                then
                        sum_pre_added+=( "${pre_value_only[$i]}" )
                fi
        done
done
echo "The array of the value corresponding previous jobs are"
echo ${sum_pre_added[@]}

##########################
sum2=0
for i in ${sum_pre_added[@]}
 do
        sum2=`echo $sum2 + $i | bc`
 done
echo "The total sum of the previous job progress is" $sum2

########################
#tot_line=$(echo ${#sum_pre_added[@]} | bc)
#echo $tot_line

a=$((echo "${#sum_pre_added[@]}*100")|bc)
#a=$((echo "$tot_line*100")|bc)
#echo $a

total_progress=`echo $a - $sum2 | bc`
echo "The total done progress between the gap time was" $total_progress

#######################
#TO FIND OUT THE TOTAL PROGRESS 
#OF THE JOB WHICH ARE IN BOTH STATE (PREVIOUS AND CURRENT)
##FOR THIS, CURRENT TOTAL PROGRESS AND 
#PREVIOUS TOTAL PROGRESS WILL BE CALCULATED


#####FIRST TO FIND THE SIMILAR JOB IDS
for ((i=0; i < ${#curr_id_only[@]}; ++i))
 do
     for ((j=0; j < ${#pre_id_only[@]}; ++j))
	do
		if [[ "${curr_id_only[$i]}" == "${pre_id_only[$j]}" ]]
		then
			similar_curr+=( "${curr_id_only[$i]}" )
			index_similar_curr+=( "$i" )
			index_similar_pre+=( "$j" )
		fi
	done
done

echo "THE SIMILAR IDS IN PREVIOUS AND CURRENT STATE ARE"
echo ${similar_curr[@]}
echo "THE INDEX OF THE SIMILAR VALUES IN CURRENT STATE ARE"
echo ${index_similar_curr[@]}
echo "THE INDEX OF THE SIMILAR VALUES IN PREVIOUS STATE ARE"
echo ${index_similar_pre[@]}

#################
#TO FIND THE CORRESPONDING VALUES
for ((i=0; i < ${#curr_value_only[@]}; ++i))
 do
        for j in "${index_similar_curr[@]}"
         do
                if [[ "$i" == "$j" ]]
                then
                        sum_similar_curr+=( "${curr_value_only[$i]}" )
                fi
        done
done
echo "THE CORRESPONDING VALUES OF THE SIMILAR JOBS IN CURRENT STATE ARE"
echo ${sum_similar_curr[@]}
#################
##TO CALCULATE THE SUM
sumsimilarcurr=0
for i in ${sum_similar_curr[@]}
 do
	sumsimilarcurr=`echo $sumsimilarcurr + $i | bc`
done
echo "The current value of sum of similar job progress is " $sumsimilarcurr
#################
##TO FIND THE CORRESPONDING VALUES OF THE PREVIOUS

for ((i=0; i < ${#pre_value_only[@]}; ++i))
 do
        for j in "${index_similar_pre[@]}"
         do
                if [[ "$i" == "$j" ]]
                then
                        sum_similar_pre+=( "${pre_value_only[$i]}" )
                fi
        done
done
echo "THE CORRESPONDING VALUES OF THE SIMILAR JOBS IN PREVIOUS STATE ARE"
echo ${sum_similar_pre[@]}
###############
###TO CALCULATE THE SUM
sumsimilarpre=0
for i in ${sum_similar_pre[@]}
 do
        sumsimilarpre=`echo $sumsimilarpre + $i | bc`
done
echo "The current value of sum of similar job progress is " $sumsimilarpre

###############
##TO FIND THE EXACT PROGRESS VALUE BY 
#SUBTRACTION total_progress3 form total_progress2

sum3=`echo $sumsimilarcurr - $sumsimilarpre | bc`
echo "THE PORGRESS IN GAP IS " $sum3



####TOTAL CURRENT PROGRESS IS ######

total_current_progress=`echo $sum1 + $total_progress + $sum3 | bc`
echo "TOTAL CURRENT PROGRESS IS" $total_current_progress
echo $total_current_progress > progress2.txt
 }

################################
#### FUNCTION TO CALCULATE PROGRESS FOR 30% RESOURCE ALLOCATION
progress_third () {
app_id_current=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $1}') 
value_current=$(yarn application -list | 
grep "root" | grep "RUNNING" | awk '{print $8 $9}'| cut -d '%' -f1 |
awk -F'.' '{print $1}'| awk -F'[^0-9]*' '{print $1 $2}')

while [[ "${#app_id_current[@]}" != "${#value_current[@]}" ]]; do
	app_id_current=()
	value_current=()
	app_id=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $1}') 
	value_initially=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $8 $9}'|
 cut -d '%' -f1 | awk -F'.' '{print $1}'| awk -F'[^0-9]*' '{print $1 $2}')
done

echo "$app_id_current" > progress_third_only_app_id.txt
echo "$value_current" > progress_third_only_value.txt

app_id=$(sudo cat /home/ramesh/progress_second_only_app_id.txt)
value_initially=$(sudo cat /home/ramesh/progress_second_only_value.txt)

curr_id_only=($(paste <(echo "$app_id_current")))
echo "CURRENT APP ONLY ID"
echo "${curr_id_only[@]}"

curr_value_only=($(paste <(echo "$value_current")))
echo "CURRENT APP ONLY VALUE"
echo "${curr_value_only[@]}"

curr_id_value=$(paste <(echo "$app_id_current") <(echo "$value_current"))
echo "CURRENT APP ID AND CORRESPONDING VALUES"
echo "$curr_id_value"

##############
pre_id_only=($(paste <(echo "$app_id")))
echo "PREVIOUS APP ONLY ID"
echo "${pre_id_only[@]}"

pre_value_only=($(paste <(echo "$value_initially")))
echo "PREVIOUS APP ONLY VALUE"
echo "${pre_value_only[@]}"

###############


#different=$(diff <( echo "$app_id" ) <( echo "$app_id_current" ))
different=$(diff -ia --suppress-common-lines 
<( printf "%s\n" "${app_id[@]}" ) <( printf "%s\n" "${app_id_current[@]}"))
echo "DIFFERENCE BETWEEN THE APPLICATION 
IDS IN THE CURRENT STATE, WHETHER LOST OR ADDED ARE"
#echo ${different[@]}

for i in ${different[@]}
do
echo $i | grep "application_" | awk '{print $1}' >> app_id_changed.txt
done



fetch_file_data=$(sudo cat /home/ramesh/app_id_changed.txt)
echo ${fetch_file_data[@]}

sudo truncate -s 0 app_id_changed.txt


#####################################
#intersection_with_current
####################################
for item1 in ${app_id_current[@]}
 do
    for item2 in ${fetch_file_data[@]}
      do
        if [[ "$item1" == "$item2" ]]
	 then
            intersection_with_current+=( "$item1" )
        fi
    done
done
echo "FOLLOWING APPS ARE NEWELY ADDED"
echo ${intersection_with_current[@]}
#############################################
#TO ADD THE VALUES OF THE NEWELY ADDED JOB
#############################################




for ((i=0; i < ${#curr_id_only[@]}; ++i))
   do
	for j in "${intersection_with_current[@]}"
	  do
		if [[ "${curr_id_only[$i]}" == "$j" ]]
		then

			index_arr_curr+=( "$i" )
		fi
	done
  done

echo "The list of the index for newely added jobs are"
echo ${index_arr_curr[@]}

########################

for ((i=0; i < ${#curr_value_only[@]}; ++i))
 do
	for j in "${index_arr_curr[@]}"
	 do
		if [[ "$i" == "$j" ]]
		then
			sum_newly_added+=( "${curr_value_only[$i]}" )
		fi
	done
done
echo "The array of the value corresponding are"
echo ${sum_newly_added[@]}

##########################
sum1=0
for i in ${sum_newly_added[@]}
 do
	sum1=`echo $sum1 + $i | bc`
 done
echo "The total sum of the currently added job progress is" $sum1


#############################
#intersection_with_previous
###########################
for item1 in ${app_id[@]}
 do
    for item2 in ${fetch_file_data[@]}
      do
        if [[ "$item1" == "$item2" ]]
         then
            intersection_with_previous+=( "$item1" )
        fi
    done
done


echo "FOLLOWING APPS WERE IN PREVIOUS BUT NOT IN CURRENT"
echo ${intersection_with_previous[@]}

###################################
# ADD THE VALUES SUBTRACTIONG FROM 100
#################################

for ((i=0; i < ${#pre_id_only[@]}; ++i))
   do
        for j in "${intersection_with_previous[@]}"
          do
                if [[ "${pre_id_only[$i]}" == "$j" ]]
                then

                        index_arr_pre+=( "$i" )
                fi
        done
  done

echo "The list of the index for
 previous jobs which are not in current job list are"
echo ${index_arr_pre[@]}

########################

for ((i=0; i < ${#pre_value_only[@]}; ++i))
 do
        for j in "${index_arr_pre[@]}"
         do
                if [[ "$i" == "$j" ]]
                then
                        sum_pre_added+=( "${pre_value_only[$i]}" )
                fi
        done
done
echo "The array of the value corresponding previous jobs are"
echo ${sum_pre_added[@]}

##########################
sum2=0
for i in ${sum_pre_added[@]}
 do
        sum2=`echo $sum2 + $i | bc`
 done
echo "The total sum of the previous job progress is" $sum2

###########################################
#tot_line=$(echo ${#sum_pre_added[@]} | bc)
#echo $tot_line

a=$((echo "${#sum_pre_added[@]}*100")|bc)
#a=$((echo "$tot_line*100")|bc)
#echo $a

total_progress=`echo $a - $sum2 | bc`
echo "The total done progress between the gap time was" $total_progress

######################################
#####FIRST TO FIND THE SIMILAR JOB IDS
for ((i=0; i < ${#curr_id_only[@]}; ++i))
 do
     for ((j=0; j < ${#pre_id_only[@]}; ++j))
	do
		if [[ "${curr_id_only[$i]}" == "${pre_id_only[$j]}" ]]
		then
			similar_curr+=( "${curr_id_only[$i]}" )
			index_similar_curr+=( "$i" )
			index_similar_pre+=( "$j" )
		fi
	done
done

echo "THE SIMILAR IDS IN PREVIOUS AND CURRENT STATE ARE"
echo ${similar_curr[@]}
echo "THE INDEX OF THE SIMILAR VALUES IN CURRENT STATE ARE"
echo ${index_similar_curr[@]}
echo "THE INDEX OF THE SIMILAR VALUES IN PREVIOUS STATE ARE"
echo ${index_similar_pre[@]}

##################################
#TO FIND THE CORRESPONDING VALUES
for ((i=0; i < ${#curr_value_only[@]}; ++i))
 do
        for j in "${index_similar_curr[@]}"
         do
                if [[ "$i" == "$j" ]]
                then
                        sum_similar_curr+=( "${curr_value_only[$i]}" )
                fi
        done
done
echo "THE CORRESPONDING VALUES OF THE SIMILAR JOBS IN CURRENT STATE ARE"
echo ${sum_similar_curr[@]}
#################################
##TO CALCULATE THE SUM
sumsimilarcurr=0
for i in ${sum_similar_curr[@]}
 do
	sumsimilarcurr=`echo $sumsimilarcurr + $i | bc`
done
echo "The current value of sum of similar job progress is " $sumsimilarcurr

##################################
##TO FIND THE CORRESPONDING VALUES OF THE PREVIOUS

for ((i=0; i < ${#pre_value_only[@]}; ++i))
 do
        for j in "${index_similar_pre[@]}"
         do
                if [[ "$i" == "$j" ]]
                then
                        sum_similar_pre+=( "${pre_value_only[$i]}" )
                fi
        done
done
echo "THE CORRESPONDING VALUES OF THE SIMILAR JOBS IN PREVIOUS STATE ARE"
echo ${sum_similar_pre[@]}
############################
###TO CALCULATE THE SUM
sumsimilarpre=0
for i in ${sum_similar_pre[@]}
 do
        sumsimilarpre=`echo $sumsimilarpre + $i | bc`
done
echo "The current value of sum of similar job progress is " $sumsimilarpre

###########################
##TO FIND THE EXACT PROGRESS
#VALUE BY SUBTRACTION total_progress3 form total_progress2

sum3=`echo $sumsimilarcurr - $sumsimilarpre | bc`
echo "THE PORGRESS IN GAP IS " $sum3
##TOTAL CURRENT PROGRESS IS 

total_current_progress=`echo $sum1 + $total_progress + $sum3 | bc`
echo "TOTAL CURRENT PROGRESS IS" $total_current_progress
echo $total_current_progress > progress3.txt
}
#### FUNCTION TO CALCULATE THE 
#DIFFERENCE BETWEEN SECOND AND FIRST PROGRESS

diff_first_speed () {
	fetch_second_value=$(sudo cat /home/
ramesh/progress1.txt | awk '{print $1}')
	fetch_first_value=$(sudo cat /home/
ramesh/progress2.txt | awk '{print $1}')
	echo "Second progress value and first 
progress value are" $fetch_first_value $fetch_second_value
	speed_first=`echo $fetch_first_value - $fetch_second_value | bc`
	}

#### FUNCTION TO CALCULATE THE DIFFERENCE BETWEEN THIRD AND SECOND
diff_second_speed () {
	fetch_third_value=$(sudo cat /home/
ramesh/progress3.txt | awk '{print $1}')
	fetch_second_value=$(sudo cat /home/
ramesh/progress2.txt | awk '{print $1}')
	echo "Third progress value and second 
progress value are" $fetch_third_value $fetch_second_value
	speed_second=`echo $fetch_third_value - $fetch_second_value | bc`
	}
#### FUNCTION TO CALCULATE THE TOTAL CURRENT PROGRESS
progress_current () {
    
app_id_current=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $1}')
value_current=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $8 $9}'|
 cut -d '%' -f1 | awk -F'.' '{print $1}'| awk -F'[^0-9]*' '{print $1 $2}')

while [[ "${#app_id_current[@]}" != "${#value_current[@]}" ]]; do
	app_id_current=()
	value_current=()
	app_id=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $1}') 
	value_initially=$(yarn application -list |
 grep "root" | grep "RUNNING" | awk '{print $8 $9}'|
 cut -d '%' -f1 | awk -F'.' '{print $1}'| awk -F'[^0-9]*' '{print $1 $2}')
done

app_id=$(sudo cat /home/ramesh/progress_third_only_app_id.txt)
value_initially=$(sudo cat /home/ramesh/progress_third_only_value.txt)

echo "$app_id_current" > progress_third_only_app_id.txt
echo "$value_current" > progress_third_only_value.txt


curr_id_only=($(paste <(echo "$app_id_current")))
echo "CURRENT APP ONLY ID"
echo "${curr_id_only[@]}"

curr_value_only=($(paste <(echo "$value_current")))
echo "CURRENT APP ONLY VALUE"
echo "${curr_value_only[@]}"

curr_id_value=$(paste <(echo "$app_id_current") <(echo "$value_current"))
echo "CURRENT APP ID AND CORRESPONDING VALUES"
echo "$curr_id_value"

#############################################################
pre_id_only=($(paste <(echo "$app_id")))
echo "PREVIOUS APP ONLY ID"
echo "${pre_id_only[@]}"

pre_value_only=($(paste <(echo "$value_initially")))
echo "PREVIOUS APP ONLY VALUE"
echo "${pre_value_only[@]}"

#############################################################
#different=$(diff <( echo "$app_id" ) <( echo "$app_id_current" ))
different=$(diff -ia --suppress-common-lines 
<( printf "%s\n" "${app_id[@]}" ) <( printf "%s\n" "${app_id_current[@]}"))
echo "DIFFERENCE BETWEEN THE APPLICATION IDS 
IN THE CURRENT STATE, WHETHER LOST OR ADDED ARE"
#echo ${different[@]}

for i in ${different[@]}
do
echo $i | grep "application_" | awk '{print $1}' >> app_id_changed.txt
done



fetch_file_data=$(sudo cat /home/ramesh/app_id_changed.txt)
echo ${fetch_file_data[@]}

sudo truncate -s 0 app_id_changed.txt


#####################################
#intersection_with_current
####################################
for item1 in ${app_id_current[@]}
 do
    for item2 in ${fetch_file_data[@]}
      do
        if [[ "$item1" == "$item2" ]]
	 then
            intersection_with_current+=( "$item1" )
        fi
    done
done
echo "FOLLOWING APPS ARE NEWELY ADDED"
echo ${intersection_with_current[@]}
#############################################
#TO ADD THE VALUES OF THE NEWELY ADDED JOB
#############################################
for ((i=0; i < ${#curr_id_only[@]}; ++i))
   do
	for j in "${intersection_with_current[@]}"
	  do
		if [[ "${curr_id_only[$i]}" == "$j" ]]
		then

			index_arr_curr+=( "$i" )
		fi
	done
  done

echo "The list of the index for newely added jobs are"
echo ${index_arr_curr[@]}

########################

for ((i=0; i < ${#curr_value_only[@]}; ++i))
 do
	for j in "${index_arr_curr[@]}"
	 do
		if [[ "$i" == "$j" ]]
		then
			sum_newly_added+=( "${curr_value_only[$i]}" )
		fi
	done
done
echo "The array of the value corresponding are"
echo ${sum_newly_added[@]}

##########################
sum1=0
for i in ${sum_newly_added[@]}
 do
	sum1=`echo $sum1 + $i | bc`
 done
echo "The total sum of the currently added job progress is" $sum1


################################################
#intersection_with_previous
#################################################
for item1 in ${app_id[@]}
 do
    for item2 in ${fetch_file_data[@]}
      do
        if [[ "$item1" == "$item2" ]]
         then
            intersection_with_previous+=( "$item1" )
        fi
    done
done


echo "FOLLOWING APPS WERE IN PREVIOUS BUT NOT IN CURRENT"
echo ${intersection_with_previous[@]}

###########################################################
# ADD THE VALUES SUBTRACTIONG FROM 100
##########################################################

for ((i=0; i < ${#pre_id_only[@]}; ++i))
   do
        for j in "${intersection_with_previous[@]}"
          do
                if [[ "${pre_id_only[$i]}" == "$j" ]]
                then

                        index_arr_pre+=( "$i" )
                fi
        done
  done

echo "The list of the index for previous 
jobs which are not in current job list are"
echo ${index_arr_pre[@]}

########################

for ((i=0; i < ${#pre_value_only[@]}; ++i))
 do
        for j in "${index_arr_pre[@]}"
         do
                if [[ "$i" == "$j" ]]
                then
                        sum_pre_added+=( "${pre_value_only[$i]}" )
                fi
        done
done
echo "The array of the value corresponding previous jobs are"
echo ${sum_pre_added[@]}

################
sum2=0
for i in ${sum_pre_added[@]}
 do
        sum2=`echo $sum2 + $i | bc`
 done
echo "The total sum of the previous job progress is" $sum2

###############
#tot_line=$(echo ${#sum_pre_added[@]} | bc)
#echo $tot_line

a=$((echo "${#sum_pre_added[@]}*100")|bc)
#a=$((echo "$tot_line*100")|bc)
#echo $a

total_progress=`echo $a - $sum2 | bc`
echo "The total done progress between the gap time was" $total_progress

############################
#TO FIND OUT THE TOTAL PROGRESS OF 
#THE JOB WHICH ARE IN BOTH STATE (PREVIOUS AND CURRENT)
##FOR THIS, CURRENT TOTAL PROGRESS 
#AND PREVIOUS TOTAL PROGRESS WILL BE CALCULATED


#####FIRST TO FIND THE SIMILAR JOB IDS
for ((i=0; i < ${#curr_id_only[@]}; ++i))
 do
     for ((j=0; j < ${#pre_id_only[@]}; ++j))
	do
		if [[ "${curr_id_only[$i]}" == "${pre_id_only[$j]}" ]]
		then
			similar_curr+=( "${curr_id_only[$i]}" )
			index_similar_curr+=( "$i" )
			index_similar_pre+=( "$j" )
		fi
	done
done

echo "THE SIMILAR IDS IN PREVIOUS AND CURRENT STATE ARE"
echo ${similar_curr[@]}
echo "THE INDEX OF THE SIMILAR VALUES IN CURRENT STATE ARE"
echo ${index_similar_curr[@]}
echo "THE INDEX OF THE SIMILAR VALUES IN PREVIOUS STATE ARE"
echo ${index_similar_pre[@]}

##########################################
#TO FIND THE CORRESPONDING VALUES
for ((i=0; i < ${#curr_value_only[@]}; ++i))
 do
        for j in "${index_similar_curr[@]}"
         do
                if [[ "$i" == "$j" ]]
                then
                        sum_similar_curr+=( "${curr_value_only[$i]}" )
                fi
        done
done
echo "THE CORRESPONDING VALUES OF THE SIMILAR JOBS IN CURRENT STATE ARE"
echo ${sum_similar_curr[@]}
#################################
##TO CALCULATE THE SUM
sumsimilarcurr=0
for i in ${sum_similar_curr[@]}
 do
	sumsimilarcurr=`echo $sumsimilarcurr + $i | bc`
done
echo "The current value of sum of similar job progress is " $sumsimilarcurr

######## TO FIND THE EXACT VALUE OF PROGRESS TO BE DONE AT THAT TIME
#a=$((echo "${#index_similar_curr[@]}*100")|bc)
#total_progress2=`echo $a - $sumsimilarcurr | bc`
#echo "THE EXACT PROGESS AT THAT TIME WAS" $total_progress2

############################
##TO FIND THE CORRESPONDING VALUES OF THE PREVIOUS

for ((i=0; i < ${#pre_value_only[@]}; ++i))
 do
        for j in "${index_similar_pre[@]}"
         do
                if [[ "$i" == "$j" ]]
                then
                        sum_similar_pre+=( "${pre_value_only[$i]}" )
                fi
        done
done
echo "THE CORRESPONDING VALUES OF THE SIMILAR JOBS IN PREVIOUS STATE ARE"
echo ${sum_similar_pre[@]}
##########################################
###TO CALCULATE THE SUM
sumsimilarpre=0
for i in ${sum_similar_pre[@]}
 do
        sumsimilarpre=`echo $sumsimilarpre + $i | bc`
done
echo "The current value of sum of similar job progress is " $sumsimilarpre
########TO FIND THE EXACT VALUE OF THE PROGRESS AT PREVIOUS STATE

sum3=`echo $sumsimilarcurr - $sumsimilarpre | bc`
echo "THE PORGRESS IN GAP IS " $sum3


#################################################################
#################TOTAL CURRENT PROGRESS IS ######################

total_current_progress=`echo $sum1 + $total_progress + $sum3 | bc`
echo "TOTAL CURRENT PROGRESS IS" $total_current_progress
echo $total_current_progress > progress3.txt
}

####FUNCTION THAT RESET THE ARRAY EVERY TIME LOOP EXECUTE
reset_array () {
	pre_id_only=()
	pre_value_only=()
	curr_id_only=()
	curr_value_only=()
	different=()
	fetch_file_data=()
	app_id_current=()
	intersection_with_current=()
	index_arr_curr=()
	sum_newly_added=()
	app_id=()
	intersection_with_previous=()
	index_arr_pre=()
	sum_pre_added=()
	similar_curr=()
	index_similar_curr=()
	index_similar_pre=()
	sum_similar_curr=()
	sum_similar_pre=()
	}



#### FUNCTION TO WRITE THOSE METRICS INTO FILE
write_file () {
		#### TO WRITE THE METRICS FORM THE CLUSTER INTO FILE
	var=$(paste -d, <(echo "$tot_mem") <(echo "$mem_used") 
<(echo "$mem_unused") <(echo "$marp") <(echo "$marp_limit") 
<(echo "$am_mem_used") <(echo "$am_vcore_used") <(echo "$tot_core") 
<(echo "$core_used") <(echo "$core_unused") <(echo "$app_running") 
<(echo "$app_pending") <(echo "$cont_running") <(echo "$cont_pending") 
<(echo "$capacity_used") <(echo "$speed_first") <(echo "$speed_second"))
        echo "$var" >> output_dynamic."csv"
	}


while true; do

	file=/home/ramesh/hadoop-2.8.1/etc/hadoop/capacity-scheduler.xml
	for marp in $(sudo cat $file | awk -F" " 'NR==26 {print $2}'); do


	#### CONDITIONS

	fetch_metrics
	write_file
	if [[ "$(bc -l <<< "$marp == $minmarp")" == "1" && $app_running > 0 ]]
	then

	sleep 15
	progress_first
	reset_array




	increment
	sleep 15
	progress_second
	reset_array

	break
	elif [ "$(bc -l <<< "$marp == 0.20")" == "1" ]
	then
		marp_thirty
		sleep 15
		progress_third
		reset_array
		fetch_metrics
		write_file


		diff_first_speed
                echo "Speed First" $speed_first
		diff_second_speed
                echo "Speed Second" $speed_second

		
		fetch_metrics
		write_file
		break

	elif [[ "$(bc -l <<< "$marp > 0.20")" 
	== "1" && "$(bc -l <<< "$speed_second > $speed_first")" == "1" ]]
	then
		increment
                sleep 15
                value_from_two_to_one=$(sudo cat /home/
		ramesh/progress2.txt | awk '{print $1}')
                echo "$value_from_two_to_one" > progress1.txt
                value_from_three_to_two=$(sudo cat /home/
		ramesh/progress3.txt | awk '{print $1}')
                echo "$value_from_three_to_two" > progress2.txt
                progress_current
		reset_array
                diff_first_speed
                echo "Speed First" $speed_first
                diff_second_speed
                echo "Speed Second" $speed_second
    


	elif [[ "$(bc -l <<< "$marp > 0.15")" 
	== "1" && "$(bc -l <<< "$speed_second < $speed_first")" == "1" ]]
	then
		decrement
                sleep 15
                value_from_two_to_one=$(sudo cat /home/
		ramesh/progress2.txt | awk '{print $1}')
                echo "$value_from_two_to_one" > progress1.txt
                value_from_three_to_two=$(sudo cat /home/
		ramesh/progress3.txt | awk '{print $1}')
                echo "$value_from_three_to_two" > progress2.txt
                progress_current
		reset_array
                diff_first_speed
                echo "Speed First" $speed_first
                diff_second_speed
                echo "Speed Second" $speed_second
        #                       fetch_metrics
        #                       write_file
        #                       break


	elif [ "$(bc -l <<< "$speed_second == $speed_first")" == "1" ]
	then
	  	sleep 15
                value_from_two_to_one=$(sudo cat /home/
		ramesh/progress2.txt | awk '{print $1}')
                echo "$value_from_two_to_one" > progress1.txt
                value_from_three_to_two=$(sudo cat /home/
		ramesh/progress3.txt | awk '{print $1}')
                echo "$value_from_three_to_two" > progress2.txt
                progress_current
		reset_array
                diff_first_speed
                echo "Speed First" $speed_first
                diff_second_speed
                echo "Speed Second" $speed_second

		break

	elif [[ "$(bc -l <<< "$app_running > 0")" 
	== "1" && "$(bc -l <<< "$app_pending == 0")" == "1" ]]
	then
				
		sleep 15
               value_from_two_to_one=$(sudo cat /home/
		ramesh/progress2.txt | awk '{print $1}')
               echo "$value_from_two_to_one" > progress1.txt
               value_from_three_to_two=$(sudo cat /home/
		ramesh/progress3.txt | awk '{print $1}')
               echo "$value_from_three_to_two" > progress2.txt
               progress_current
		reset_array
               diff_first_speed
               echo "Speed First" $speed_first
               diff_second_speed
             echo "Speed Second" $speed_second

               break


	elif [ "$(bc -l <<< "$marp == 0.80")" == "1" ]
	then
		decrement
                sleep 15
                value_from_two_to_one=$(sudo cat /home/
		ramesh/progress2.txt | awk '{print $1}')
                echo "$value_from_two_to_one" > progress1.txt
                value_from_three_to_two=$(sudo cat /home/
		ramesh/progress3.txt | awk '{print $1}')
                echo "$value_from_three_to_two" > progress2.txt
                progress_current
		reset_array
                diff_first_speed
                echo "Speed First" $speed_first
                diff_second_speed
                echo "Speed Second" $speed_second
        
               break
	elif [[ "$(bc -l <<< "$app_running == 0")" 
	== "1" && "$(bc -l <<< "$app_pending == 0")" == "1" ]]
	then
		echo "Set to Default"
		awk 'NR==26{$2=a}1' a=$minmarp $file > tmp && sudo mv -f tmp $file
		yarn rmadmin -refreshQueues
		break


	else
		sleep 15
                value_from_two_to_one=$(sudo cat /home/
		ramesh/progress2.txt | awk '{print $1}')
                echo "$value_from_two_to_one" > progress1.txt
                value_from_three_to_two=$(sudo cat /home/
		ramesh/progress3.txt | awk '{print $1}')
                echo "$value_from_three_to_two" > progress2.txt
                progress_current
		reset_array
                diff_first_speed
                echo "Speed First" $speed_first
                diff_second_speed
                echo "Speed Second" $speed_second
       
                                break

	fi

done
sleep 15
done
done
