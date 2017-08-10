#!/bin/bash

set -e

declare -a src

dest="$1"
if [ -z "$dest" ]; then
	echo "missing dest"
	exit 1
fi
shift 1

srcin=0

while [ -n "$1" ]; do
	src[$srcin]="$1"
	srcin=$((srcin + 1))
	shift 1
done

if [ $srcin -lt 1 ]; then
	echo "Missing data source!"
	exit 1
fi

srcin=$((srcin - 1))

testtype="$(basename ${src[0]} | sed -e 's/.*\.//g')"

plot_perf_data() {
	gnuplot <<-EOF
	reset
	set terminal png size 1280,720
	set output "$dest.perf.png"
	set title "$dest"
	set style data linespoints
	set key top left
	set ylabel "MB/sec (higher better)"
	set xlabel "packet size (bytes)"
	plot "$dest.dat" using 2:xtic(1) title columnheader(2), \
		for [i=3:*] '' using i title columnheader(i)

EOF
}

generate_cpg_hum_perf_dat() {
	echo -n "Perf"
	for i in $(seq 0 $srcin); do
		name=$(basename ${src[i]} | sed -e 's/_/-/g' -e 's/\..*//g')
		echo -n " ${name}"
	done
	echo ""
	for i in $(cat "${src[0]}" | grep "^\[Perf\]" | awk -F "," '{print $3}' | sort -n); do
		echo -n "$i "
		for x in $(seq 0 $srcin); do
			value=$(cat "${src[$x]}" | grep "^\[Perf\]" | grep ",$i," | awk -F "," '{print $6}')
			echo -n "$value "
		done
		echo
	done
}

plot_lat_data() {
	gnuplot <<-EOF
	reset
	set terminal png size 1280,720
	set output "$dest.lat.png"
	set title "$dest"
	set style data linespoints
	set key top left
	set ylabel "Latency in microseconds (lower better)"
	set xlabel "packet size (bytes)"
	plot "$dest.dat" using 2:xtic(1) title columnheader(2), \
		for [i=3:*] '' using i title columnheader(i)
EOF
}

generate_cpg_hum_lat_dat() {
	echo -n "Latency"
	for i in $(seq 0 $srcin); do
		name=$(basename ${src[i]} | sed -e 's/_/-/g' -e 's/\..*//g')
		echo -n " ${name}-min ${name}-avg ${name}-max"
	done
	echo ""
	for i in $(cat "${src[0]}" | grep "^\[Perf\]" | awk -F "," '{print $3}' | sort -n); do
		echo -n "$i "
		for x in $(seq 0 $srcin); do
			min=$(cat "${src[$x]}" | grep "^\[Perf\]" | grep ",$i," | awk -F "," '{print $7}')
			avg=$(cat "${src[$x]}" | grep "^\[Perf\]" | grep ",$i," | awk -F "," '{print $8}')
			max=$(cat "${src[$x]}" | grep "^\[Perf\]" | grep ",$i," | awk -F "," '{print $9}')
			echo -n "$min $avg $max "
		done
		echo
	done
	echo -n "Total "
	for x in $(seq 0 $srcin); do
		min=$(cat "${src[$x]}" | grep "^\[Stats]" | awk -F "," '{print $9}')
		avg=$(cat "${src[$x]}" | grep "^\[Stats]" | awk -F "," '{print $10}')
		max=$(cat "${src[$x]}" | grep "^\[Stats]" | awk -F "," '{print $11}')
		echo -n "$min $avg $max "
	done
	echo
}

process_cpg_hum() {
	rm -f "$dest.perf.png" "$dest.lat.png" "$dest.dat"
	generate_cpg_hum_perf_dat > "$dest.dat"
	plot_perf_data
	generate_cpg_hum_lat_dat > "$dest.dat"
	plot_lat_data
	rm -f "$dest.dat"
}

case $testtype in
	cpghum)
		process_cpg_hum
		;;
	knet_bench)
		;;
esac

exit 0
