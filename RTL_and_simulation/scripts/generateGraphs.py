import pandas as pd
import matplotlib.pyplot as plt
import re

# function to extract data from a line
def extract_data(line):
    m = re.match(r'\{Density, Cycles\} \{(\d+), (\d+)\}', line)
    return m.groups() if m else None

# read the file
with open('../load_results.txt', 'r') as f:
    lines = f.readlines()

# extract data
data = [extract_data(line) for line in lines if extract_data(line)]

average_cycles=0
for point in data:
    average_cycles+=int(point[1])


with open('../STPU_results_HW.txt', 'r') as f:
    lines = f.readlines()

# extract data
data = [extract_data(line) for line in lines if extract_data(line)]

# create a dictionary with density as key and cycles as value
data_dict = {int(density): int(cycles) for density, cycles in data}

data=[]

average_cycles//=300
print(average_cycles)

for percentage in range(5, 105, 5):
    print(average_cycles+data_dict[percentage])
    data.append((percentage, average_cycles+data_dict[percentage]))


# Convert to DataFrame
df = pd.DataFrame(data, columns=['Density', 'Cycles'])

# Convert to numeric data
df = df.apply(pd.to_numeric)

print(df)

# Calculate averages for each unique 'Density'
df_avg0 = df.groupby('Density').mean().reset_index()

## Plot the data
#plt.figure(figsize=(10, 6))
#plt.bar(df_avg0['Density'].astype(str), df_avg0['Cycles'], label='SW SPMM')
##plt.bar(df_avg0['Density'].astype(str), df_avg0['Cycles'], label='STPU SPMM')

#plt.xlabel('Weight Matrix Density (%)')
#plt.ylabel('Clock Cycle Count (Avg)')
#plt.title('SPMM Performance vs Density')
#plt.legend()
#plt.grid(False)
#plt.show()


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
#plt.figure(figsize=(10, 6))
#plt.bar(df_avg['Density'].astype(str), df_avg['Cycles'], label='SW SPMM')
#plt.bar(df_avg0['Density'].astype(str), df_avg0['Cycles'], label='STPU SPMM')

#plt.xlabel('Weight Matrix Density (%)')
#plt.ylabel('Clock Cycle Count (Avg)')
#plt.title('SPMM Performance vs Density')
#plt.legend()
#plt.grid(False)
#plt.show()


#df_avg.set_index('Density', inplace=True)
#df_avg0.set_index('Density', inplace=True)

#df_all = pd.concat([df_avg, df_avg0], axis=1)  # df_avg0 and df_avg order is switched here
#df_all.columns = ['STPU SPMM', 'SW SPMM']  # columns names order is switched here

#df_all.plot(kind='bar', figsize=(10, 6))  # colors specified directly

#plt.xlabel('Weight Matrix Density (%)')
#plt.ylabel('Clock Cycle Count (Avg)')
#plt.title('SPMM Performance vs Density')
#plt.legend()
#plt.grid(False)
#plt.show()

df_avg.set_index('Density', inplace=True)
df_avg0.set_index('Density', inplace=True)

df_all = pd.concat([df_avg, df_avg0], axis=1)  # df_avg0 and df_avg order is switched here
df_all.columns = ['STPU SPMM', 'SW SPMM']  # columns names order is switched here

df_all.plot(kind='bar', figsize=(10, 6), width=0.9)  # colors specified directly and width set to 0.8

plt.xlabel('Weight Matrix Density (%)')
plt.ylabel('Clock Cycle Count (Avg)')
plt.title('SPMM Performance vs Density')
plt.legend()
plt.grid(False)
plt.show()
