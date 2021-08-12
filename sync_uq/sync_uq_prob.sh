pulp rpm remote create --name ol7 --url http://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64 --policy on_demand
pulp rpm remote create --name ol7opt --url http://yum.oracle.com/repo/OracleLinux/OL7/optional/latest/x86_64 --policy on_demand
for i in {1..4}
do
    echo "RUN $i"
    pulp rpm repository create --name ol7 --remote ol7 --autopublish
    pulp rpm repository create --name ol7opt --remote ol7opt --autopublish
    pulp -b rpm repository sync --name ol7; pulp -b rpm repository sync --name ol7opt
    while true
    do
        running=`pulp task list --state running | jq length`
        echo -n "."
        sleep 5
        if [ ${running} -eq 0 ]
        then
            echo "DONE"
            break
        fi
    done
    failed=`pulp task list --state failed | jq length`
    echo "FAILURES : ${failed}"
    echo "CLEANING UP..."
    pulp rpm repository destroy --name ol7
    pulp rpm repository destroy --name ol7opt
    pulp orphans delete
done
