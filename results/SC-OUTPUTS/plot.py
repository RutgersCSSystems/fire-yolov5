import numpy as np
import matplotlib.pyplot as plt

# Define the data
data_set_1 = np.array([[1090, 1647, 1470, 1906, 1798],
                       [348, 347, 575, 1249, 1691],
                       [994, 1021, 1195, 1375, 1485],
                       [866, 912, 1086, 1192, 1274],
                       [887, 923, 1104, 1289, 1261]])

data_set_2 = np.array([[1090, 1647, 1470, 1906, 1798],
                       [348, 347, 575, 1249, 1691],
                       [994, 1021, 1195, 1375, 1485],
                       [866, 912, 1086, 1192, 1274],
                       [887, 923, 1104, 1289, 1261]])

data_set_3 = np.array([[1090, 1647, 1470, 1906, 1798],
                       [348, 347, 575, 1249, 1691],
                       [994, 1021, 1195, 1375, 1485],
                       [866, 912, 1086, 1192, 1274],
                       [887, 923, 1104, 1289, 1261]])

# Calculate the average and standard deviation across the three data sets
average = np.mean([data_set_1, data_set_2, data_set_3], axis=0)
std_dev = np.std([data_set_1, data_set_2, data_set_3], axis=0)

# Define the labels and colors
labels = ['rseq', 'rrev', 'rscan', 'multirrand', 'rrand']
colors = ['blue', 'green', 'orange']

# Set the bar width and positions
bar_width = 0.25
r1 = np.arange(len(labels))
r2 = [x + bar_width for x in r1]
r3 = [x + bar_width for x in r2]

# Create the bar graph
plt.bar(r1, average[:, 0], yerr=std_dev[:, 0], color=colors[0], width=bar_width, edgecolor='white', label='Data Set 1')
plt.bar(r2, average[:, 1], yerr=std_dev[:, 1], color=colors[1], width=bar_width, edgecolor='white', label='Data Set 2')
plt.bar(r3, average[:, 2], yerr=std_dev[:, 2], color=colors[2], width=bar_width, edgecolor='white', label='Data Set 3')

# Add labels and titles
plt.xlabel('Reader')
plt.xticks([r + bar_width for r in range(len(labels))], labels)
plt.ylabel('Execution Time (in microseconds)')
plt.title('Comparison of Execution Time across Three Data Sets')
plt.legend()

# Show the plot
#plt.show()
plt.savefig("errors.pdf")
