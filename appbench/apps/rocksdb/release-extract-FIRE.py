import os
import csv
import numpy as np
import matplotlib.pyplot as plt

# Define the arrays
thread_arr = ["32"]
batchsize_arr = ["128", "256", "512"]  # Adjust batch sizes as needed
workload_arr = ["multireadrandom", "readreverse", "readseq", "readwhilescanning"]
config_arr = ["isolated", "Vanilla", "CIPI_PERF"]  # Updated order
config_out_arr = ["isolated", "Vanilla", "Managed"]  # Updated order

# Base directory for output files
output_dir = os.environ.get("OUTPUTDIR", "")
base_dir = os.path.join(output_dir, "ROCKSDB/20M-KEYS")

# Output CSV file
output_file = "RESULT.csv"

# Function to extract the value before "MB/s" from a line and round to the nearest integer
def extract_and_round_ops_per_sec(line):
    parts = line.split()
    ops_index = parts.index("MB/s")
    ops_sec_value = float(parts[ops_index - 1])
    return round(ops_sec_value)

def plot_access_pattern(datafile, access_pattern, result_path):
    with open(datafile, mode='r') as file:
        csv_reader = csv.reader(file)
        next(csv_reader)  # Skip header row

        for row in csv_reader:
            workload_name = row[0]
            if workload_name == access_pattern:
                plt.figure(figsize=(10, 6))
                x = np.arange(len(batchsize_arr))  # x-axis positions
                width = 0.2

                for i in range(1, len(row), 3):
                    config_name = row[i].split('_')[0]
                    config_values = [int(value) for value in row[i+1:i+4]]
                    if len(batchsize_arr) == len(config_values):
                        plt.bar(x + (i - 1) * width, config_values, width=width, label=f"{config_name}")

                plt.xlabel("Batch Size")
                plt.ylabel("MB/s")
                plt.title(f"MB/s by Configuration and Batch Size - Access Pattern: {access_pattern}")
                plt.xticks(x + width * (len(row[1:]) / 3) / 2, batchsize_arr)  # Center x-ticks
                plt.legend(["Isolated", "Vanilla", "Managed"])  # Corrected legend
                plt.tight_layout()
                OUTPUTGRAPH = result_path + "/" + f"{access_pattern}_plot.pdf"
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
                    file_path = os.path.join(base_dir, thread_arr[0], f"batchsize-{batchsize}", workload, f"{config}.out")
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

