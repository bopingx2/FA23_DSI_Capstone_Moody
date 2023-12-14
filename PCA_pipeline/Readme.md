This folder contains the codes and results for PCA analysis.

### Code Descrption:

- __main.py__ contains the code for permutating data combination and running through PCA module. Please run this code under the project's main folder to ensure the path consistency. You can change the code from line 159 to 160 to run the program for five countries(Egypt, Nigeria, Romania, Poland, Hungary). Only the last two countries have FCI published by IMF. The result will be outputed to "Output" folder.

- __FCI_creator.ipynb__ takes the name of the country and the selected PCA result ID, it computes the FCI for that country by the weights according to the selected PCA result and it normalizes FCI from its beginning to 2020/03. The created FCI will be in "Output/$country_abbr" folder.

- __normalize_IMF_FCI.ipynb__ (Deprecated) normalize IMF FCI for online dashboard display.

- __vis.ipynb__ (Deprecated) create some graph for poster or report.

### Folder Descrption:

- __Output__: includes PCA results for each country. "corr" folder contains the information about correlation (for Poland and Hungary), explain variance ratio, and weight of every selected time series. "fig" folder contains the visualized FCI graph. "FCI.csv" is the final FCI we selected and created.

- __PCA results for visualization__(Deprecated): A folder created for dashboard visualization
