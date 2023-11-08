import pandas as pd

filename = "case03_input_file.xlsx"
data = pd.read_excel(f'{filename}',
                       header=None) # can append [path]/filename

frame_len = data.shape[0]
ranges = data[0][2:9].tolist()
output_df = pd.DataFrame(columns=["FileName", "Region", "Partner", "Range", "Value"])

for i in range(2, frame_len, 10):
    region = data.iloc[i - 2, 0][:-2] # get region name without " г"
    partners = data.iloc[i - 1, 1:].dropna().tolist()
    values = data.iloc[i:i + 7, 1:].values.tolist()

    for j, partner in enumerate(partners):
        for c, _range in enumerate(ranges):
            value = values[c][j]
            if not pd.isna(value):
                output_df.loc[len(output_df)] = [filename, region, partner, _range, f'{value:.1f}'.replace('.', ',')]
output_df.to_csv("output.csv", index=False, sep=",", encoding='utf-8')
