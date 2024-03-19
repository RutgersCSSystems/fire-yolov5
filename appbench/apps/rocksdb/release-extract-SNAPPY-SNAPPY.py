import os
import csv
import numpy as np
import matplotlib.pyplot as plt

# Define the arrays
thread_arr = ["32"]
batchsize_arr = ["8", "16", "32"]  # Adjust batch sizes as needed
workload_arr = ["multireadrandom", "readreverse", "readseq", "readwhilescanning"]
workload_arr = ["multireadrandom"]

config_arr = ["isolated", "Vanilla", "CIPI_PERF"]  # Updated order
config_out_arr = ["isolated", "Vanilla", "Managed"]  # Updated order

config_arr = ["OSonly", "OSonly-prio"]  # Updated order
config_out_arr = ["Memory-sharing",  "Memory sharing + priority"]  # Updated order


# Base directory for output files
output_dir = os.environ.get("OUTPUTDIR", "")
base_dir = os.path.join(output_dir, "ROCKSDB/20M-KEYS/")

# Output CSV file
output_file = "RESULT.csv"

# Function to extract the value before "MB/s" from a line and round to the nearest integer
def extract_and_round_ops_per_sec(line):
    parts = line.split()
    ops_index = parts.index("MB/s")
    ops_sec_value = float(parts[ops_index - 1])
    return round(ops_sec_value)


def plot_access_pattern(datafile, access_pattern, result_path):

    workload_data = [[], [], []]

    for batchsize in batchsize_arr:
        for config in config_arr:
            file_path = os.path.join(base_dir, thread_arr[0], f"SNAPPYTHREADS-{batchsize}", access_pattern, "SNAPPYOUT-" + f"{config}.out")
            if os.path.exists(file_path):
                with open(file_path, 'r') as file:
                    lines = file.readlines()
                    ops_sec_found = False
                    for line in lines:
                        if "MB/s" in line:
                            ops_sec_value = extract_and_round_ops_per_sec(line)
                            if config == "isolated":
                                workload_data[0].append(ops_sec_value)
                            elif config == "OSonly":
                                workload_data[0].append(ops_sec_value)
                            elif config == "OSonly-prio":
                                workload_data[1].append(ops_sec_value)
                            ops_sec_found = True
                            break
                    if not ops_sec_found:
                        # Set ops_sec_value to 0 if not found
                        workload_data[2].append(0)  # Managed configuration

    plt.figure(figsize=(7, 4.5))
    x = np.arange(len(batchsize_arr))  # x-axis positions
    width = 0.2

    #plt.bar(x - width, workload_data[0], width=width, label="No Mem, Space Sharing")
    plt.bar(x, workload_data[0], width=width, label="Mem. Space Sharing")
    plt.bar(x + width, workload_data[1], width=width, label="Mem. Space Sharing + Priority")

    plt.xlabel("Batch Size")
    plt.ylabel("Througput in MB/s")
    #plt.title(f"MB/s by Configuration and Batch Size - Access Pattern: {access_pattern}")
    plt.xticks(x, batchsize_arr)
    plt.legend(["Mem. Space Sharing", "Mem. Space Sharing + Priority"], loc='upper right')
    plt.tight_layout()

    OUTPUTGRAPH = os.path.join(result_path, f"{access_pattern}_plot_SNAPPY_SNAPPY.pdf")
    plt.savefig(OUTPUTGRAPH)
    plt.close()  # Close the plot to avoid overlapping when multiple plots are generated


# Main function to iterate through workloads, extract MB/s, and plot results
def plot(output_file, result_path):
        for pattern in workload_arr:
            plot_access_pattern(output_file, pattern, result_path)



# Main function to iterate through workloads, extract MB/s, and plot results
def main():
    with open(output_file, mode='w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)
        # Write the header row with column names
        #header_row = ["Workload"] + [f"{config}_{batchsize}" for config in config_out_arr for batchsize in batchsize_arr]
        header_row = ["Workload"] + [f"{config}_{batchsize}" for batchsize in batchsize_arr for config in config_out_arr]
        csv_writer.writerow(header_row)

        # Initialize data for plotting
        data = [[] for _ in config_out_arr]

        for workload in workload_arr:
            workload_data = [workload]
            for batchsize in batchsize_arr:
                for i, config in enumerate(config_arr):
                    result_path = os.path.join(base_dir, thread_arr[0])
                    file_path = os.path.join(base_dir, thread_arr[0], f"SNAPPYTHREADS-{batchsize}", workload, "SNAPPYOUT-" + f"{config}.out")
                    print(file_path)
                    if os.path.exists(file_path):
                        with open(file_path, 'r') as file:
                            lines = file.readlines()
                            ops_sec_found = False
                            for line in lines:
                                if "MB/s" in line:
                                    ops_sec_value = None
                                    try:
                                        ops_sec_value = extract_and_round_ops_per_sec(line)
                                    except ValueError:
                                        pass  # If value cannot be converted to float, leave ops_sec_value as None
                                    workload_data.append(ops_sec_value)
                                    data[i].append(ops_sec_value)
                                    ops_sec_found = True
                                    break
                            if not ops_sec_found:
                                # Handle the case where "MB/s" is not found in the file
                                workload_data.append(0)  # Default value if "MB/s" not found
                    else:
                        # Handle the case where file for configuration is not present
                        workload_data.append(0)  # Default value if file not found
            csv_writer.writerow(workload_data)

    plot(output_file, result_path)

if __name__ == "__main__":
    main()

