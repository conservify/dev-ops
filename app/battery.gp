set datafile separator ","
set terminal png size 900,400
set title "Battery"
set ylabel "Level"
set xlabel "Date"
set xdata time
set timefmt "%s"
set format x "%m/%d %H"
set ytics font "Verdana,8"
set xtics font "Verdana,8"
set key left top
set grid

plot filename using 1:2 with lines lw 2 lt 3 title title
