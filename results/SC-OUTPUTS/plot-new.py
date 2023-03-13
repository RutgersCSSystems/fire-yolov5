import matplotlib.pyplot as plt
import numpy as np
import os

# Define the names of the trial files
trial_files = ['ROCKSDB-THREADS-16-trial4.DATA', 'ROCKSDB-THREADS-16-trial2.DATA', 'ROCKSDB-THREADS-16-trial3.DATA']

# Define the names of the readers and techniques
readers = ['rseq', 'rrev', 'rscan', 'multirrand', 'rrand']
techniques = ['Vanilla', 'OSonly', 'CIP', 'CIPI', 'CII']
techniques_text = ['Vanilla', 'OSonly', 'CIP', 'CIPI', 'CII']


# Create an empty dictionary to hold the mean values and standard deviations for each technique and reader
data = {technique: {reader: {'mean': [], 'std': []} for reader in readers} for technique in techniques}

# We can override the global variables with environment variables set somewhere lese
def get_legends():
    global legends
    global legendtext
    global clusterlen

    #print str(os.getenv('legendlist'))
    if(str(os.getenv('legendlist')) != 'None'):
        legends=os.getenv('legendlist').split(',')
        clusterlen=len(legends)
        techniques=legends

    if(str(os.getenv('legendnamelist')) != 'None'):
        legendtext=os.getenv('legendnamelist').split(',') 
        techniques_text=legendtext

    #print legends 
    #print legendtext


get_legends()

# Read the data from each trial file
for trial_file in trial_files:
    with open(trial_file, 'r') as f:
        for line in f:
            if line.startswith('reader'):
                headers = line.strip().split()[1:]
            else:
                values = line.strip().split()
                for i, value in enumerate(values[1:]):
                    reader = values[0]
                    technique = headers[i]
                    data[technique][reader]['mean'].append(float(value))

# Calculate the mean and standard deviation for each technique and reader
for technique in techniques:
    for reader in readers:
        mean = np.mean(data[technique][reader]['mean'])
        std = np.std(data[technique][reader]['mean'])
        data[technique][reader]['mean'] = mean
        data[technique][reader]['std'] = std

# Plot the mean values with standard deviation error bars as a grouped bar chart
x = np.arange(len(readers))
width = 0.15

fig, ax = plt.subplots(figsize=(8,4.5))
plt.subplots_adjust(top=0.98, bottom=0.15, left=0.12, right=0.98)

for i, technique in enumerate(techniques):
    means = [data[technique][reader]['mean'] for reader in readers]
    stds = [data[technique][reader]['std'] for reader in readers]
    hatch = "/" if i % 2 == 0 else "\\" # add hatch pattern based on technique index
    ax.bar(x + (i - 2) * width, means, yerr=stds, align='center', width=width, label=technique, hatch=hatch)

ax.set_xticks(x)
ax.set_xticklabels(readers)
#ax.legend()
ax.legend(ncol=6)
ax.set_ylabel('Througput in 1000x')
#ax.set_title('Access Pattern')
ax.legend(fontsize=12)
ax.set_ylabel('Throughput in 1000x', fontdict={'fontsize': 14})
ax.set_xlabel('Access Pattern', fontdict={'fontsize': 14})
ax.legend(ncol=2, fontsize=13, loc='best')
ax.tick_params(axis='x', labelsize=14)
ax.tick_params(axis='y', labelsize=14)

#plt.show()
plt.savefig("rocksdb-16threads.pdf")
