#!/usr/bin/env python3
#
# Simple tool to plot collected cache bandwidth results

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import sys

# Computes nicer labels for power-of-two logarithmic x-axis ranges
# In: Series of byte values of transfers
# Out: values, labels of the even powers of two, scaled to 1024 bytes
def get_xticks(series):
    x_ticks = np.log2(series)
    x_ticks_filtered = []
    for x in x_ticks:
        if x == int(x) and x % 2 == 0:
            x_ticks_filtered.append(x)

    x_axis_ticks = [(2**x)/1024 for x in x_ticks_filtered]
    x_axis_tick_labels = [str(x) for x in x_axis_ticks]
    return x_axis_ticks, x_axis_tick_labels


# Select how the plot is output
# 0 = display
# 1 = save to png file
OUTPUT = 0

if len(sys.argv) < 2:
    print("Usage: {} <result_file.csv> [<display/png>]".format(sys.argv[0]))
    exit(0)

if len(sys.argv) >= 3:
    if(sys.argv[2] == "display"):
        OUTPUT = 0
    elif(sys.argv[2] == "png"):
        OUTPUT = 1
    else:
        print("Unknown output format: {}. Defaulting to display.".format(sys.argv[2]))

# Open the CSV result file
res = pd.read_csv(sys.argv[1])

# Now separate the different tests
random = res[res["test_name"] == "random"]
stream = res[res["test_name"] == "stream"]
stride = res[res["test_name"] == "stride"]

stride_arr = []

# Also differentiate between the different strides used
strides = stride["stride"].unique()
strides.sort()
for s in strides:
    stride_arr.append(stride[stride["stride"] == s])

# Plot in a 2x2 grid
fig, ax = plt.subplots(nrows=2, ncols=2, figsize=(19.2, 10.8))
fig.suptitle("Bandwith results for {}".format(sys.argv[1].split('.')[0]))

# All plots use a logarithmic x-axis as the test size
# roughly doubles each step (with 8 in-between steps)
for i in range(2):
    for j in range(2):
        ax[i][j].set_xscale('log', base=2)
        ax[i][j].set_xlabel("Testsize (kiB)")
        ax[i][j].set_ylabel("Average throughput (bytes/cycle)")


# Plot the bytes/cycle for in-order accesses
ax[0][0].set_title("Linear accesses")
ax[0][0].plot(stream["number_of_accesses"]*stream["stride"]/1024, 
              stream["number_of_accesses"]*stream["stride"]/stream["read_cycles"], label="read")
ax[0][0].plot(stream["number_of_accesses"]*stream["stride"]/1024,
              stream["number_of_accesses"]*stream["stride"]/stream["write_cycles"], label="write")

ticks, labels = get_xticks(stream["number_of_accesses"]*8)
ax[0][0].set_xticks(ticks, labels=labels)


# Plot the bytes/cycle for random accesses
ax[0][1].set_title("Random accesses")
ax[0][1].plot(random["number_of_accesses"]*random["stride"]/1024, 
              random["number_of_accesses"]*random["stride"]/random["read_cycles"], label="read")
ax[0][1].plot(random["number_of_accesses"]*random["stride"]/1024,
              random["number_of_accesses"]*random["stride"]/random["write_cycles"], label="write")
ticks, labels = get_xticks(random["number_of_accesses"]*8)
ax[0][1].set_xticks(ticks, labels=labels)


# Plot the bytes/cycle for in-order accesses of different strides
ax[1][0].set_title("Strided read accesses")
ax[1][1].set_title("Strided write accesses")
ticks, labels = get_xticks(stride_arr[0]["number_of_accesses"]*8)
ax[1][0].set_xticks(ticks, labels=labels)
ax[1][1].set_xticks(ticks, labels=labels)

for s in stride_arr:
    ax[1][0].plot(s["number_of_accesses"]*8/1024, 
            s["number_of_accesses"]*8/s["read_cycles"], label="stride: {}".format(int(s["stride"].iloc[0])))
    ax[1][1].plot(s["number_of_accesses"]*8/1024, 
              s["number_of_accesses"]*8/s["write_cycles"], label="stride: {}".format(int(s["stride"].iloc[0])))


# Generate legends for all subplots
ax[0][0].legend()
ax[0][1].legend()
ax[1][0].legend()
ax[1][1].legend()

# Decide how to output the plot
if OUTPUT == 1:
    plt.savefig(sys.argv[1] + ".png")
else:
    plt.show()

