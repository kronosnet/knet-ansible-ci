#!/bin/bash

set -e

src1="$1"
src2="$2"
dest="$3"

if [ -z "$src1" ]; then
	echo "missing src1"
	exit 1
fi

if [ -z "$src2" ]; then
	echo "missing src2"
	exit 1
fi

if [ -z "$dest" ]; then
	echo "missing dest"
	exit 1
fi

testname1="$(basename $src1 | sed -e 's/\..*//g' -e 's/_/ /g')"
testname2="$(basename $src2 | sed -e 's/\..*//g' -e 's/_/ /g')"
testtype="$(basename $src1 | sed -e 's/.*\.//g')"

plot_perf_data() {
	gnuplot <<-EOF
	reset
	set terminal png
	set output "$dest.perf.png"
	set title "$testname1 (src1) vs $testname2 (src2)"
	set style data linespoints
	set ylabel "MB/sec (higher better)"
	set xlabel "packet size (bytes)"
	plot "$dest.dat" using 2:xtic(1) title columnheader(2), \
		for [i=3:3] '' using i title columnheader(i)

EOF
}

generate_cpg_hum_perf_dat() {
	echo "Perf src1 src2"
	for i in $(cat "$src1" | grep "^\[Perf\]" | awk -F "," '{print $3}' | sort -n); do
		echo -n "$i "
		for x in $src1 $src2; do
			value=$(cat "$x" | grep "^\[Perf\]" | grep ",$i," | awk -F "," '{print $6}')
			echo -n "$value "
		done
		echo
	done
}

plot_lat_data() {
	gnuplot <<-EOF
	reset
	set terminal png
	set output "$dest.lat.png"
	set title "$testname1 (src1) vs $testname2 (src2)"
	set style data linespoints
	set ylabel "microseconds (lower better)"
	set xlabel "packet size (bytes)"
	plot "$dest.dat" using 2:xtic(1) title columnheader(2), \
		for [i=3:7] '' using i title columnheader(i)
EOF
}

generate_cpg_hum_lat_dat() {
	echo "Latency min-src1 avg-src1 max-src1 min-src2 avg-src2 max-src2"
	for i in $(cat "$src1" | grep "^\[Perf\]" | awk -F "," '{print $3}' | sort -n); do
		echo -n "$i "
		for x in $src1 $src2; do
			min=$(cat "$x" | grep "^\[Perf\]" | grep ",$i," | awk -F "," '{print $7}')
			avg=$(cat "$x" | grep "^\[Perf\]" | grep ",$i," | awk -F "," '{print $8}')
			max=$(cat "$x" | grep "^\[Perf\]" | grep ",$i," | awk -F "," '{print $9}')
			echo -n "$min $avg $max "
		done
		echo
	done
	echo -n "Total "
	for x in $src1 $src2; do
		min=$(cat "$x" | grep "^\[Stats]" | awk -F "," '{print $9}')
		avg=$(cat "$x" | grep "^\[Stats]" | awk -F "," '{print $10}')
		max=$(cat "$x" | grep "^\[Stats]" | awk -F "," '{print $11}')
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
