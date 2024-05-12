import csv
import matplotlib.pyplot as plt

memfrac_arr_proxy = ["48GB", "24GB", "12GB", "6GB"]  # Adjust batch sizes as needed

# Read data from CSV file
data = {}
with open('RESULT-ENERGY.csv', newline='') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        config = row['Configuration']
        batch_size = row['MEMFRAC']
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
bar_width = 0.2

# Set figure size
#plt.figure(figsize=(14, 12))  # Adjusted figure dimensions
plt.figure(figsize=(6, 4))

# Plot stacked bars for CPU and DRAM energy
for i, config in enumerate(configs):
    plt.bar([p + i * bar_width for p in x], cpu_energy[config], width=bar_width, label=f'{config} - CPU Energy', align='center')
    plt.bar([p + i * bar_width for p in x], dram_energy[config], width=bar_width, bottom=cpu_energy[config], label=f'{config} - DRAM Energy', align='center')

plt.xlabel('Memory Fraction', fontsize=16)
plt.ylabel('Power (Watts)', fontsize=16)
plt.xticks([p + bar_width / 2 for p in x], memfrac_arr_proxy, fontsize=16)  # Adjusted x-tick positions and font size
plt.yticks(fontsize=16)  # Adjusted y-tick font size
plt.legend(fontsize=16, loc='upper center', bbox_to_anchor=(0.5, 1.15), ncol=len(configs), frameon=False)  # Placing legend at the top of the graph without a box and laid out horizontally
plt.gca().spines['top'].set_visible(False)  # Removed border around the top
plt.tight_layout()
plt.savefig('energy_consumption_YOLO.pdf', bbox_inches='tight')  # Adjusted to save legend outside
plt.show()
