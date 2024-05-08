import csv
import matplotlib.pyplot as plt

# Read data from CSV file
data = {}
with open('RESULT-ENERGY.csv', newline='') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        config = row['Configuration']
        batch_size = row['Batch Size']
        cpu_energy = float(row['CPU-POWER'])
        dram_energy = float(row['DRAM-POWER'])
        if config not in data:
            data[config] = {}
        data[config][batch_size] = {'CPU': cpu_energy, 'DRAM': dram_energy}

# Extracting data for plotting
configs = list(data.keys())
batch_sizes = list(data[configs[0]].keys())
cpu_energy = {config: [data[config][batch]['CPU'] for batch in batch_sizes] for config in configs}
dram_energy = {config: [data[config][batch]['DRAM'] for batch in batch_sizes] for config in configs}

# Plotting
x = range(len(batch_sizes))
bar_width = 0.35

# Plot stacked bars for CPU and DRAM energy
for i, config in enumerate(configs):
    plt.bar([p + i * bar_width for p in x], cpu_energy[config], width=bar_width, label=f'{config} - CPU Energy', align='center')
    plt.bar([p + i * bar_width for p in x], dram_energy[config], width=bar_width, bottom=cpu_energy[config], label=f'{config} - DRAM Energy', align='center')

plt.xlabel('Batch Size')
plt.ylabel('Power (Watts)')
plt.title('CPU and DRAM Energy Consumption for Different Configurations and Batch Sizes')
plt.xticks([p + bar_width / 2 for p in x], batch_sizes)
plt.legend()
plt.tight_layout()
plt.savefig('energy_consumption.pdf')
plt.show()

