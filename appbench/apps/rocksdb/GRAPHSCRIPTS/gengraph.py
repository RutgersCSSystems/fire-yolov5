import csv
import matplotlib.pyplot as plt
import numpy as np

def plot_access_pattern(datafile, access_pattern, result_path):
    with open(datafile, mode='r') as file:
        csv_reader = csv.reader(file)
        next(csv_reader)  # Skip header row

        for row in csv_reader:
            workload_name = row[0]
            if workload_name == access_pattern:
                plt.figure(figsize=(10, 6))
                x = np.arange(3)
                width = 0.2

                for i in range(1, len(row), 3):
                    config_name = row[i].split('_')[0]
                    batch_sizes = ['128', '256', '512']
                    config_values = [int(value) for value in row[i+1:i+4]]
                    if len(batch_sizes) == len(config_values):
                        plt.bar(x, config_values, width=width, label=f"{config_name}")
                        x = x + width + 0.1  # Adjust for spacing between bars

                plt.xlabel("Batch Size")
                plt.ylabel("MB/s")
                plt.title(f"MB/s by Configuration and Batch Size - Access Pattern: {access_pattern}")
                plt.xticks(np.arange(3) + width * 1.5, batch_sizes)
                plt.legend()
                plt.tight_layout()
                OUTPUTGRAPH = result_path + "/" + f"{access_pattern}_plot.pdf"
                plt.savefig(OUTPUTGRAPH)
                plt.close()  # Close the plot to avoid overlapping when multiple plots are generated

# Example usage:
datafile = "RESULT.csv"
result_path = "/users/kannan11/ssd/ioopt/appbench/apps/rocksdb"
access_pattern = "multireadrandom"
plot_access_pattern(datafile, access_pattern, result_path)

