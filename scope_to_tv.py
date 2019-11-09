#!/usr/bin/python
# This is not really useful to anyone but me as the loaded data is
# from a non standard format
# (last line of file with a dumped python array of readouts between 0 and 255)

import sys
# 200Msa/s -> 1.0/200000000
def load_data_from_file(filename):
    with open(filename,"r") as f:
        data = f.read().splitlines()[-1][1:-1]
    data_ints = list(map(int,data.split(", ")))
    min_val = min(data_ints)
    max_val = max(data_ints)
    mid = min_val+(max_val-min_val)/2
    print("min: %d, mid: %d, max: %d"%(min_val,mid,max_val), file=sys.stderr)
    for v in data_ints:
        value = 0 if v < mid else 1
        yield value
        
def verify_noloss(filename, skips):
    prev_val = "A"
    changes = -1
    for idx,val in enumerate(load_data_from_file(filename)):
        if idx != 0 and idx%skips == 0:
            changes = 0
            continue
        if val == prev_val:
            continue
        else:
            changes+=1
        if changes > 1:
            raise Exception(" Loss! (idx: %d)"%idx)
    return True
    

verify_noloss("authenticate_chan1_output_200MSas_28Mpts",2)
verify_noloss("authenticate_chan2_output_200MSas_28Mpts",2)

clock_data = load_data_from_file("authenticate_chan1_output_200MSas_28Mpts")
data_data = load_data_from_file("authenticate_chan2_output_200MSas_28Mpts") 
last_data = 'A'
last_clock = 'A'
for timestamp, (clock_value,data_value) in enumerate(zip(clock_data,data_data)):
    if timestamp%2 == 0:
        clock_change=last_clock != clock_value
        data_change=last_data != data_value
        print("%d%d%d%d"%(1 if clock_change else 0, clock_value, 1 if data_change else 0, data_value))
        last_clock = clock_value
        last_data = data_value
