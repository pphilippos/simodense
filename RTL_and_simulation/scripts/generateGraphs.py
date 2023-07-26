import pandas as pd
import matplotlib.pyplot as plt
import re

# Function to extract data from a line
def extract_data(line):
    m = re.match(r'\{Density, Cycles\} \{(\d+), (\d+)\}', line)
    return m.groups() if m else None

# Read the file
with open('../SPMM_results.txt', 'r') as f:
    lines = f.readlines()

# Extract data
data = [extract_data(line) for line in lines if extract_data(line)]

# Convert to DataFrame
df = pd.DataFrame(data, columns=['Density', 'Cycles'])

# Convert to numeric data
df = df.apply(pd.to_numeric)

# Calculate averages for each unique 'Density'
df_avg = df.groupby('Density').mean().reset_index()

# Plot the data
plt.figure(figsize=(10, 6))
plt.bar(df_avg['Density'].astype(str), df_avg['Cycles'], label='SW SPMM')
#plt.bar(df_avg['Density'].astype(str), df_avg['Cycles'], label='STPU SPMM')

plt.xlabel('Weight Matrix Density (%)')
plt.ylabel('Clock Cycle Count (Avg)')
plt.title('SPMM Performance vs Density')
plt.legend()
plt.grid(False)
plt.show()
