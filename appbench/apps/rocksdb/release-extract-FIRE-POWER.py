import os
import csv
import numpy as np
import matplotlib.pyplot as plt

# Define the arrays
thread_arr = ["32"]
batchsize_arr = ["10", "20", "40"]  # Adjust batch sizes as needed
workload_arr = ["multireadrandom", "readreverse", "readseq", "readwhilescanning"]
workload_arr = ["multireadrandom"]

config_arr = ["isolated", "Vanilla", "CIPI_PERF"]  # Updated order
config_out_arr = ["isolated", "Vanilla", "Managed"]  # Updated order

config_arr = ["isolated", "OSonly", "OSonly-prio"]  # Updated order
config_out_arr = ["isolated", "sharing", "sharing-prio"]  # Updated order

# Base directory for output files
output_dir = os.environ.get("OUTPUTDIR", "")
base_dir = os.path.join(output_dir, "ROCKSDB/20M-KEYS")

# Output CSV files
output_file_throughput = "RESULT.csv"
output_file_energy = "RESULT-ENERGY.csv"

# Function to extract the value before "MB/s" from a line and round to the nearest integer
def extract_and_round_ops_per_sec(line):
    parts = line.split()
    ops_index = parts.index("MB/s")
    ops_sec_value = float(parts[ops_index - 1])
    return round(ops_sec_value)

# Function to extract energy data from a file
def extract_energy(filename):

    print("calling extract_energy")

    with open(filename, 'r') as file:
        lines = file.readlines()

    energy_data = {'socket0': {'CPU': 0, 'DRAM': 0}, 'socket1': {'CPU': 0, 'DRAM': 0}}
    total_energy = {'CPU': 0, 'DRAM': 0}
    current_socket = ''
    read_next_line = False
    current_domain = ''

    for line in lines:
        if 'socket 0' in line:
            current_socket = 'socket0'
        elif 'socket 1' in line:
            current_socket = 'socket1'

        if 'Domain PKG' in line:
            read_next_line = True
            current_domain = 'CPU'
        elif 'Domain DRAM' in line:
            read_next_line = True
            current_domain = 'DRAM'
        elif read_next_line and 'Energy consumed' in line:
            energy = float(line.split(':')[1].split()[0])
            energy_data[current_socket][current_domain] = energy
            total_energy[current_domain] += energy
            read_next_line = False
            print(energy) 

    return energy_data, total_energy

# Main function to iterate through workloads, extract MB/s, and plot results
def main():
    with open(output_file_throughput, mode='w', newline='') as csv_file, \
         open(output_file_energy, mode='w', newline='') as csv_energy_file:
        csv_writer = csv.writer(csv_file)
        csv_energy_writer = csv.writer(csv_energy_file)
        
        # Write the header row with column names for throughput
        header_row_throughput = ["Workload"] + [f"{config}_{batchsize}" for batchsize in batchsize_arr for config in config_out_arr]
        csv_writer.writerow(header_row_throughput)
        
        # Write the header row with column names for energy
        header_row_energy = ["Configuration", "Batch Size", "CPU Energy (J)", "DRAM Energy (J)"]
        csv_energy_writer.writerow(header_row_energy)

        for workload in workload_arr:
            for batchsize in batchsize_arr:
                #for config in config_arr:
                for config, config_out in zip(config_arr, config_out_arr):
                    result_path = os.path.join(base_dir, thread_arr[0])
                    file_path = os.path.join(base_dir, thread_arr[0], f"batchsize-{batchsize}", workload, f"{config}.out")
                    print(file_path)
                    if os.path.exists(file_path):
                        with open(file_path, 'r') as file:
                            lines = file.readlines()
                            ops_sec_found = False
                            cpu_energy = None  # Initialize CPU energy
                            for line in lines:
                                #print(line + " " + file_path)
                                #if "MB/s" in line:
                                 #   ops_sec_value = None
                                  #  try:
                                   #     ops_sec_value = extract_and_round_ops_per_sec(line)
                                    #except ValueError:
                                     #   pass  # If value cannot be converted to float, leave ops_sec_value as None
                                    #if ops_sec_value is not None:
                                     #   csv_writer.writerow([workload, ops_sec_value])
                                      #  ops_sec_found = True
                                    #break
                                if "Energy" in line:  # Extract energy data if line contains "Energy"
                                    #print("Extract energy data if line contains Energy")
                                    energy_data, total_energy = extract_energy(file_path)
                                    cpu_energy = total_energy['CPU']  # Extract CPU energy
                                    break

                            if not ops_sec_found:
                                # Handle the case where "MB/s" is not found in the file
                                csv_writer.writerow([workload, 0])  # Default value if "MB/s" not found
                            if cpu_energy is not None:  # Write energy data if available
                                csv_energy_writer.writerow([config_out, batchsize, total_energy['CPU'], total_energy['DRAM']])
                    else:
                        # Handle the case where file for configuration is not present
                        csv_writer.writerow([workload, 0])  # Default value if file not found
                        csv_energy_writer.writerow([config_out, batchsize, 0, 0])  # Default energy values if file not found

if __name__ == "__main__":
    main()


