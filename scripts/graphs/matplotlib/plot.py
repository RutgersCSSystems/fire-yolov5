import numpy as np

# Trail 1 data
trail_1 = np.array([
    [1090, 1647, 1470, 1906, 1798],
    [348, 347, 575, 1249, 1691],
    [994, 1021, 1195, 1375, 1485],
    [866, 1012, 1086, 1192, 1274],
    [887, 923, 1104, 1289, 1261]
])

# Trail 2 data
trail_2 = np.array([
    [1090, 1647, 1470, 1906, 1798],
    [348, 347, 575, 1249, 1691],
    [994, 1021, 1195, 1375, 1485],
    [866, 912, 1086, 1192, 1274],
    [887, 923, 1104, 1289, 1261]
])

# Trail 3 data
trail_3 = np.array([
    [1290, 1647, 1470, 1906, 1798],
    [398, 347, 575, 1249, 1691],
    [994, 1021, 1195, 1375, 1485],
    [866, 912, 1086, 1192, 1274],
    [1027, 923, 1104, 1289, 1261]
])

# Combine data into one array
data = np.array([trail_1, trail_2, trail_3])

# Calculate mean and standard deviation for each access pattern and technique
means = np.mean(data, axis=0)
std_devs = np.std(data, axis=0)

# Print the results
access_patterns = ['rseq', 'rrev', 'rscan', 'multirrand', 'rrand']
techniques = ['Vanilla', 'OSonly', 'CIP', 'CIPI', 'CII']

for i in range(len(access_patterns)):
    print(f"\nAccess pattern: {access_patterns[i]}")
    for j in range(len(techniques)):
        print(f"{techniques[j]}: mean={means[i,j]}, std dev={std_devs[i,j]}")

ax.set_xticks(x + width*2)
ax.set_xticklabels(patterns)
ax.set_ylabel('Throughput')
ax.set_xlabel('Access Patterns')
ax.legend()

plt.show()

