import matplotlib.pyplot as plt

# Data
data = [
    {"Configuration": "isolated", "Batch Size": 10, "CPU Energy (J)": 18025.5, "DRAM Energy (J)": 3142.1},
    {"Configuration": "OSonly", "Batch Size": 10, "CPU Energy (J)": 25319.1, "DRAM Energy (J)": 4449.59},
    {"Configuration": "isolated", "Batch Size": 20, "CPU Energy (J)": 18061.1, "DRAM Energy (J)": 3151.4},
    {"Configuration": "OSonly", "Batch Size": 20, "CPU Energy (J)": 48598.8, "DRAM Energy (J)": 8833.47},
    {"Configuration": "isolated", "Batch Size": 40, "CPU Energy (J)": 18011.4, "DRAM Energy (J)": 3146.9},
    {"Configuration": "OSonly", "Batch Size": 40, "CPU Energy (J)": 24968.2, "DRAM Energy (J)": 4406.38}
]

# Extracting data
configurations = sorted(set(d["Configuration"] for d in data))
batch_sizes = sorted(set(d["Batch Size"] for d in data))
cpu_energy = {config: [d["CPU Energy (J)"] for d in data if d["Configuration"] == config] for config in configurations}
dram_energy = {config: [d["DRAM Energy (J)"] for d in data if d["Configuration"] == config] for config in configurations}

# Plotting
fig, ax = plt.subplots(figsize=(10, 6))

bar_width = 0.35
index = range(len(batch_sizes))

for i, config in enumerate(configurations):
    ax.bar([x + i * bar_width for x in index], cpu_energy[config], bar_width, label=f'{config} - CPU')
    ax.bar([x + i * bar_width for x in index], dram_energy[config], bar_width, bottom=cpu_energy[config], label=f'{config} - DRAM')

ax.set_xlabel('Batch Size')
ax.set_ylabel('Energy (J)')
ax.set_title('CPU and DRAM Energy Consumption by Configuration and Batch Size')
ax.set_xticks([x + bar_width / 2 for x in index])
ax.set_xticklabels(batch_sizes)
ax.legend()

plt.tight_layout()

# Save the plot to a PDF file
plt.savefig('energy_consumption.pdf')

plt.show()

