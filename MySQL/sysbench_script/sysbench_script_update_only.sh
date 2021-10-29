#!/bin/bash

PORT=3789

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $DIR

MYSQL_BASE="$DIR""/../inst"

SYSBENCH_BASE=$DIR"/../sysbench"
SYSBENCH=$SYSBENCH_BASE"/sysbench/src/sysbench"
SYSBENCH_LUA=$SYSBENCH_BASE"/sysbench/src/lua/"
SYSBENCH_SCRIPT=$SYSBENCH_BASE"/sysbench_script/"

# compile sysbench
# echo "compile sysbench"
# bash $SYSBENCH_SCRIPT"install.sh"
# prepare sysbench
SYSBENCH_OPT=""
SYSBENCH_OPT+=" --db_driver=mysql --mysql_host=localhost --mysql-user=root --report-interval=1 --secondary=off --mysql-port=${PORT}"
SYSBENCH_OPT+=" --create-secondary=false"
SYSBENCH_OPT+=" --mysql-socket=$MYSQL_BASE/mysql.sock"
SYSBENCH_OPT+=" --time=120"
SYSBENCH_OPT+=" --threads=48"
SYSBENCH_OPT+=" --tables=48" 
SYSBENCH_OPT+=" --table_size=100000"
SYSBENCH_OPT+=" --rand-type=zipfian --rand-zipfian-exp=0.0" 
SYSBENCH_WORKLOAD=$SYSBENCH_LUA"oltp_update_non_index.lua"
cd $SYSBENCH_LUA
$SYSBENCH $SYSBENCH_OPT $SYSBENCH_WORKLOAD "cleanup"
$SYSBENCH $SYSBENCH_OPT $SYSBENCH_WORKLOAD "prepare"

($SYSBENCH $SYSBENCH_OPT $SYSBENCH_WORKLOAD "run" > "${DIR}""/result_file") &

QUERY1="BEGIN; SELECT id,k from sbtest1;"
for ((i=0;i<10;i+=1)); do
	QUERY1+="SELECT SLEEP(2); SELECT id,k from sbtest1;"
done
QUERY1+="COMMIT;"

QUERY2="BEGIN; SELECT count(*) from sbtest1;"
for ((i=0;i<10;i+=1)); do
	QUERY2+="SELECT SLEEP(2); SELECT count(*) from sbtest1;"
done
QUERY2+="COMMIT;"

QUERY3="BEGIN; select sum(cnt) from (SELECT COUNT(*) as cnt FROM sbtest1 sb1 LEFT JOIN sbtest2 sb2 ON sb1.k = sb2.k LEFT JOIN sbtest3 sb3 ON sb1.k = sb3.k group by sb1.k having count(*) >= 1) as t; COMMIT;"

: << "END"
cd $MYSQL_BASE
for ((i=1;i<2;i+=1)); do
	( a=$((i*10)); sleep ${a}; ./bin/mysql --socket="$MYSQL_BASE""/mysql.sock" \
		-u root sbtest -e "${QUERY1}" > /dev/null 2>&1) &
done
END
: << "END"
for ((i=0;i<10;i+=1)); do
	( a=$((i*10)); sleep ${a}; ./bin/mysql --socket="$MYSQL_BASE""/mysql.sock" \
		-u root sbtest -e "${QUERY2}" > /dev/null 2>&1) &
#done
END
#END

cd $DIR
: << "END"
cd $DIR
# run sysbench
( ( sleep 000; cd $SYSBENCH_LUA; $SYSBENCH $SYSBENCH_OPT $SYSBENCH_WORKLOAD run ; cd $DIR) > "${RESULT_DIR}sysbench_${engine}.data") &

QUERY="\c sbtest \\\ BEGIN; SELECT id,k from sbtest1 where id=1;"
for ((i=0;i<100;i+=1)); do
	QUERY+="SELECT COUNT(*) FROM sbtest1; \
						SELECT pg_sleep(1); \
						"
done
QUERY+="COMMIT;"

#for ((i=0;i<150;i+=1)); do
#	( a=$((i*10)); sleep ${a} ; bash ${POSTGRESQL_CLIENT_SCRIPT}"run_query.sh" --query="$QUERY" --port="$PORT") &
#done

wait

sleep 2

# shutdown postgresql server
bash $POSTGRESQL_SERVER_SCRIPT"shutdown_server.sh"


sleep 2


# make long transaction
QUERY="\c sbtest \\\ BEGIN; SELECT txid_current(); SELECT * FROM sbtest1 WHERE id = 10; \
       SELECT pg_sleep(60); \
       COMMIT;"
( sleep 010 ; \
  date +%s.%N > "${RESULT_DIR}longx_01_begin_${engine}.data"; \
  bash ${POSTGRESQL_CLIENT_SCRIPT}"run_query.sh" --query="$QUERY" --port="$PORT"; \
  date +%s.%N > "${RESULT_DIR}longx_01_end_${engine}.data"; ) &


# get stat
if [ "$engine" == "VANILLA" ]
then
for ((i=0;i<"$RUNNING_TIME";i+=1)); do
    QUERY="\c sbtest \\\ BEGIN; \
           SELECT * FROM sbtest3 WHERE id = 1; \
           SELECT get_stat(); \
           COMMIT;"
    ( sleep ${i} ; bash ${POSTGRESQL_CLIENT_SCRIPT}"run_query.sh" --query="$QUERY" --port="$PORT" \
      > "${RESULT_DIR}stat_${engine}_${i}.data"; ) &
done
fi


if [ "$engine" == "VDRIVER" ]
then

QUERY="\c sbtest \\\ BEGIN; SELECT * FROM sbtest3 WHERE id = 11; "
for ((i=0;i<"$RUNNING_TIME";i+=1)); do
           QUERY+="SELECT * FROM sbtest3 WHERE id = 1; \
           SELECT get_stat(); \
           SELECT pg_sleep(1); \
           "
done
QUERY+="COMMIT;"
( sleep 0 ; bash ${POSTGRESQL_CLIENT_SCRIPT}"run_query.sh" --query="$QUERY" --port="$PORT" \
      > "${RESULT_DIR}stat_${engine}.data"; ) &

fi


# sampling chain length
if [ "$engine" == "VANILLA" ]
then

QUERY="\c sbtest \\\ ;"
for ((i=1;i<1000;i+=1)); do
           QUERY+=" \
                   SELECT * FROM sbtest3 WHERE id = ${i}; \
                   SELECT get_stat(); \
                   \
           "
done
( sleep 60 ; bash ${POSTGRESQL_CLIENT_SCRIPT}"run_query.sh" --query="$QUERY" --port="$PORT" \
      > "${RESULT_DIR}sample_${engine}.data"; ) &

fi


if [ "$engine" == "VDRIVER" ]
then
# stop cutter
QUERY="SELECT current_database();"
( sleep 50 ; bash ${POSTGRESQL_CLIENT_SCRIPT}"run_query.sh" --query="$QUERY" --port="$PORT"; ) &

QUERY="\c sbtest \\\ BEGIN; SELECT * FROM sbtest3 WHERE id = 11; SELECT pg_sleep(60); "
for ((i=1;i<1000;i+=1)); do
           QUERY+=" \
                   SELECT * FROM sbtest3 WHERE id = ${i}; \
                   SELECT get_stat(); \
           "
done
QUERY+="COMMIT;"
( sleep 0 ; bash ${POSTGRESQL_CLIENT_SCRIPT}"run_query.sh" --query="$QUERY" --port="$PORT" \
      > "${RESULT_DIR}sample_${engine}.data"; ) &

fi




# recent xid
for ((i=1;i<"$RUNNING_TIME"*1;i+=1)); do
	(sleep "$((1000000000 *   $i/1  ))e-9" ; \
	 (date +%s.%N ; bash ${POSTGRESQL_CLIENT_SCRIPT}"run_query.sh" --query="SELECT txid_current();" --port="$PORT") \
	 > "${RESULT_DIR}recent_xid_${engine}_${i}.data") &
done

# data directory & redo log size
for ((i=1;i<"$RUNNING_TIME"*1;i+=1)); do
	(sleep "$((1000000000 *   $i/1  ))e-9" ; \
	 (date +%s.%N ; du -sb "${POSTGRESQL_DATA}"; du -sb "${POSTGRESQL_DATA}pg_wal";) \
	 > "${RESULT_DIR}size_${engine}_${i}.data") &
done

# run sysbench
( ( sleep 000; cd $SYSBENCH_LUA; $SYSBENCH $SYSBENCH_OPT $SYSBENCH_WORKLOAD run ; cd $DIR) > "${RESULT_DIR}sysbench_${engine}.data") &


wait

sleep 2

# shutdown postgresql server
bash $POSTGRESQL_SERVER_SCRIPT"shutdown_server.sh"

sleep 5


done
######################################################### WORKLOAD_LIST iter end




# copy logfile of postgre to log dir
cp $LOGFILE $RESULT_DIR

# edit logfile

(sed '/HYU_LLT/!d' logfile > $RESULT_DIR"verification.data") &

wait

# copy all config files to log directory
cp $CONFIG_DIR"postgresql.conf" $0 $RESULT_DIR
cp $DIR"refine.py" $DIR"plot.script" $RESULT_DIR

# copy data for gnuplot.
find ${RESULT_DIR} -type f -name "*.data" -exec cp -f {} ${GNUPLOT_DATA} \;

# refine
python3 refine.py

# plot
gnuplot plot.script

cp *.eps $RESULT_DIR

END
