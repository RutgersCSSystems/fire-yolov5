import matplotlib.pyplot as plt
import numpy as np

# Define the file paths for each trial
trial_paths = ['ROCKSDB-THREADS-16-trial1.DATA', 'ROCKSDB-THREADS-16-trial2.DATA', 'ROCKSDB-THREADS-16-trial3.DATA']

# Define the access patterns and techniques
patterns = ['rseq', 'rrev', 'rscan', 'multirrand', 'rrand']
techniques = ['Vanilla', 'OSonly', 'CIP', 'CIPI', 'CII']

# Initialize an empty array to store the data for each trial
data = []

# Read in the data for each trial from its corresponding file
for path in trial_paths:
    trial_data = []
    with open(path, 'r') as f:
        # Skip the first line (header)
        next(f)
        for line in f:
            # Remove leading/trailing whitespace and split by whitespace
            vals = line.strip().split()
            # Convert each value to an integer and append to the row
            row = [int(val) for val in vals[1:]]
            trial_data.append(row)
    # Append the trial data to the overall data array
    data.append(trial_data)

# Convert the data to a numpy array for easier manipulation
data = np.array(data)

# Calculate mean and standard deviation
means = np.mean(data, axis=0)
stds = np.std(data, axis=0)

# Plot
x = np.arange(len(patterns))
width = 0.15

fig, ax = plt.subplots(figsize=(10, 6))
for i in range(len(techniques)):
    ax.bar(x + i*width, means[i], width, yerr=stds[i], label=techniques[i])

ax.set_xticks(x + width*2)
ax.set_xticklabels(patterns)
ax.set_ylabel('Throughput')
ax.set_xlabel('Access Patterns')
ax.legend()

plt.show()

