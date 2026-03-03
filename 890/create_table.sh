# ridiculous amount of data - will take ~2 hrs to recreate
for j in $(seq 1 10);
do
    for i in $(seq 1 100000000);
    do
        echo "1" >> ./1g.txt
    done
done

