import matplotlib.pyplot as plt
import pandas as pd

# Your data
data = {
    'Configuration': ['isolated', 'sharing', 'isolated', 'sharing', 'isolated', 'sharing', 'isolated', 'sharing'],
    'MEMFRAC': [1, 1, 2, 2, 3, 3, 4, 4],
    'CPU-POWER': [32.9158, 33.1189, 32.9599, 33.1698, 33.0321, 33.0822, 32.9549, 33.0744],
    'DRAM-POWER': [7.01384, 7.12751, 7.06051, 7.12401, 7.09676, 7.06005, 7.00485, 7.09099]
}

df = pd.DataFrame(data)

# Create a figure and a set of subplots
fig, ax = plt.subplots()

# Plot the data
ax.bar(df['MEMFRAC'], df['CPU-POWER'], label='CPU Power')
ax.bar(df['MEMFRAC'], df['DRAM-POWER'], bottom=df['CPU-POWER'], label='DRAM Power')

# Set labels
ax.set_xlabel('Memory Fraction', fontsize=12)
ax.set_ylabel('Power (Watts)', fontsize=12)

# Set title
ax.set_title('CPU and DRAM Power vs Memory Fraction', fontsize=14)

# Set legend
ax.legend(fontsize=10)

# Show the plot
plt.show()

