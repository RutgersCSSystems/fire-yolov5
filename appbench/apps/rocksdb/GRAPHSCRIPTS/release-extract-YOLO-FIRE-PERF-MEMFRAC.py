import os
import csv
import numpy as np
import matplotlib.pyplot as plt
import re

# Define the arrays
thread_arr = ["32"]
memfrac_arr = ["10", "20", "30", "40", "50"]  # Adjust batch sizes as needed
memfrac_arr_proxy = ["90GB", "80GB", "70GB", "60GB", "50GB"]  # Adjust batch sizes as needed
workload_arr = ["multireadrandom", "readreverse", "readseq", "readwhilescanning"]
workload_arr = ["multireadrandom"]

config_arr = ["isolated", "OSonly", "OSonly-prio"]  # Updated order
config_out_arr = ["isolated", "OSonly", "OSonly-prio"]  # Updated order

#config_arr = ["isolated", "OSonly"]  # Updated order
#config_out_arr = ["isolated", "OSonly"]  # Updated order
config_arr = ["isolated-yolo", "OSonly"]  # Updated order
config_out_arr = ["isolated-yolo", "OSonly"]  # Updated order

batchsize = 60


# Base directory for output files
output_dir = os.environ.get("OUTPUTDIR", "")
base_dir = os.path.join(output_dir, "ROCKSDB/20M-KEYS")

# Output CSV file
output_file = "RESULT-YOLO.csv"

# Function to extract the value before "MB/s" from a line and round to the nearest integer
#def extract_and_round_ops_per_sec(line):
#    parts = line.split()
#    ops_index = parts.index("MB/s")
#    ops_sec_value = float(parts[ops_index - 1])
#    return round(ops_sec_value)


def extract_ops_per_sec_values(file_content):
    values = []
    for line in file_content.split('\n'):
        match = re.search(r"(\d+\.\d+)s/it", line)
        if match:
            values.append(float(match.group(1)))
    return values

def calculate_average_ops_per_sec(file_path):
    if os.path.exists(file_path):
        with open(file_path, 'r') as file:
            content = file.read()
            values = extract_ops_per_sec_values(content)
            if values:
                return round(np.mean(values), 2)
    return None

def plot_access_pattern(datafile, access_pattern, result_path):
    workload_data = [[], [], []]
    for memfrac in memfrac_arr:
        for config in config_arr:
            file_path = os.path.join(base_dir, thread_arr[0], "batchsize-"  + str(batchsize), f"MEMFRAC{memfrac}", access_pattern, "YOVLOVOUT-" + f"{config}.out")
            avg_value = calculate_average_ops_per_sec(file_path)
            if avg_value is not None:
                if config == "isolated-yolo":
                    workload_data[0].append(avg_value)
                elif config == "OSonly":
                    workload_data[1].append(avg_value)
                print(workload_data[0])
                # Uncomment the following if you want to include OSonly-prio
                # elif config == "OSonly-prio":
                #     workload_data[2].append(avg_value)

    plt.figure(figsize=(6, 4))
    x = np.arange(len(memfrac_arr))
    width = 0.2
    plt.bar(x - width, workload_data[0], width=width, label="isolated-yolo")
    plt.bar(x, workload_data[1], width=width, label="OSonly")
   # plt.bar(x + width, workload_data[2], width=width, label="OSonly-prio")
    plt.xlabel("Memory Size (GB)", fontsize=16)
    plt.ylabel("Average Latency (seconds/iteration)", fontsize=16)
    plt.xticks(x, memfrac_arr_proxy, fontsize=16)
    plt.yticks(fontsize=16)
    plt.legend(["Isolated", "Sharing"], loc='upper right', fontsize=16)
    plt.tight_layout()
    OUTPUTGRAPH = os.path.join(result_path, f"YOLO_ROCKSDB_{access_pattern}_batchsize_{batchsize}_plot.pdf")
    print(OUTPUTGRAPH)
    plt.savefig(OUTPUTGRAPH)
    plt.close()

# Main function to iterate through workloads, extract MB/s, and plot results
def plot(output_file, result_path):
        for pattern in workload_arr:
            plot_access_pattern(output_file, pattern, result_path)



def main():
    with open(output_file, mode='w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)
        
        # Write the header row with column names
        header_row = ["Workload"] + [f"{config}_{memfrac}" for memfrac in memfrac_arr for config in config_out_arr]
        csv_writer.writerow(header_row)
        
        # Initialize data for plotting
        data = [[] for _ in config_out_arr]
        
        for workload in workload_arr:
            workload_data = [workload]
            for memfrac in memfrac_arr:
                for i, config in enumerate(config_arr):
                    result_path = os.path.join(base_dir, thread_arr[0])
                    file_path = os.path.join(base_dir, thread_arr[0], "batchsize-"  + str(batchsize), f"MEMFRAC{memfrac}", workload, "YOVLOVOUT-" + f"{config}.out")
                    print(file_path)
                    
                    avg_value = calculate_average_ops_per_sec(file_path)
                    
                    if avg_value is not None:
                        workload_data.append(avg_value)
                        data[i].append(avg_value)
                    else:
                        # Handle the case where file is not present or no valid data found
                        workload_data.append(0)
                        data[i].append(0)
            
            csv_writer.writerow(workload_data)
    
    plot_access_pattern(output_file, workload_arr[-1], result_path)

if __name__ == "__main__":
    main()
