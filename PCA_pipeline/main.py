import pandas as pd
import numpy as np
import pandas.api.types as ptypes
import sklearn.decomposition
import random
import matplotlib.pyplot as plt
from itertools import combinations 
from pathlib import Path
import pickle
import os
import shutil
from multiprocessing import Pool

base_dir = str(Path().resolve()) + '/data/'


def scale_series(series, mean, std):
    return (series - mean)/std


def generate_combination(country: str):
    country_path = base_dir + country + '_DataFrame.csv'
    country_df = pd.read_csv(country_path)
    bond_cat_comb = [['Term_Premium'], ['Risk_Premium'], ['Term_Premium', 'Risk_Premium']]
    equity_cat_comb = [['Stock_Prices_mom%_change'], ['Stock_Prices_mom24mma%_change'], ['Stock_Market_Volatility'],
                    ['Stock_Prices_mom%_change', 'Stock_Prices_mom24mma%_change'],
                    ['Stock_Prices_mom%_change', 'Stock_Market_Volatility'],
                    ['Stock_Prices_mom24mma%_change', 'Stock_Market_Volatility'],
                    ['Stock_Prices_mom%_change', 'Stock_Prices_mom24mma%_change', 'Stock_Market_Volatility']]
    macro_cat = set(['REER', 'Current_Account_Balance_change_yryr%', 'Current_Account_Balance_over_GDP',
                    'One-Day_Repo_Rate_AVG', 'One-Day_Repo_Rate_EOP',
                    'Policy_Rate_&_Fed_Funds_Rate_Differential_AVG', 'Policy_Rate_&_Fed_Funds_Rate_Differential_EOP'])
    mpf_cat = set(['Broad_Money_mo12m%_change', 'Velocity_of_Money_mo12m%_change', 'Portfolio_Flows',
                    'Foreign_Exchange_Reserve_change_yryr%', 'Foreign_Exchange_Reserve_over_GDP', 'Bank_Lending_mo12m%_change'])
    country_df_cols = set(country_df.columns.to_list())
    country_macro_cat = macro_cat & country_df_cols
    country_mpf_cat = mpf_cat & country_df_cols
    macro_cat_comb = []
    for i in range(len(country_macro_cat)):
        comb = combinations(country_macro_cat, i + 1)
        for c in comb:
            if 'Policy_Rate_&_Fed_Funds_Rate_Differential_EOP' in c and 'Policy_Rate_&_Fed_Funds_Rate_Differential_AVG' in c:
                continue
            elif 'One-Day_Repo_Rate_EOP' in c and 'One-Day_Repo_Rate_AVG' in c:
                continue
            macro_cat_comb.append(list(c))
    mpf_cat_comb = []
    for i in range(len(country_mpf_cat)):
        comb = combinations(country_mpf_cat, i + 1)
        for c in comb:
            mpf_cat_comb.append(list(c))
    country_comb = []
    for b in bond_cat_comb:
        for e in equity_cat_comb:
            for m in macro_cat_comb:
                for p in mpf_cat_comb:
                    country_comb.append(['Date'] + b + e + m + p)
    return country_comb

def PCA_module(df: pd.DataFrame, Country: str, Country_abbr: str, df_IMF = None):
    ''' Assert the names and the types of the columns. Assert the cov matrix is all positive. '''
    # assert (df.columns[0] == "Date")
    # assert (ptypes.is_datetime64_dtype(df["Date"]))
    assert all(ptypes.is_numeric_dtype(df[col]) for col in df.columns[1:])
    df = df.dropna(axis = "index")
    # assert ((df.cov(numeric_only=True).values > 0).all())

    ''' Get the date range '''
    df = df.sort_values(by= ["Date"], ascending=False, ignore_index=True)
    # print("The date range is :", df["Date"].iat[-1], "to", df["Date"].iat[0])

    # ''' Scale the data '''
    # for col in df.columns[1:]:
    #     df[col] = scale_series(df[col], df[col].mean(), df[col].std())

    ''' Select data frame that ends at 2020-03 '''
    end_index = None
    for index in range(len(df)):
        if df.iloc[index, 0] == "2020-03":
            end_index = index
            break
    assert (end_index is not None)
    

    ''' Scale the data '''
    for col_num in range(1, len(df.columns)):
        df.iloc[:, col_num] = scale_series(df.iloc[:, col_num], df.iloc[end_index: , col_num ].mean(), df.iloc[end_index: , col_num ].std())


    df_PCA_decomp = df.iloc[end_index:, 1:]
    ''' PCA decomposition'''
    pca = sklearn.decomposition.PCA(n_components = len(df_PCA_decomp.columns)) 
    pca.fit(df_PCA_decomp)

    # TODO: flip sign 
    df_transformed = pd.DataFrame(np.transpose(np.matmul(np.square(pca.components_),np.transpose(df.iloc[ :, 1:]))))
    # df_transformed = pd.DataFrame(pca.transform(df.iloc[ :, 1:]))
    df_transformed.insert(0, "Date", df["Date"], True)

    '''concatenate IMF FCI with our FCI'''
    if df_IMF is None:
        df_combined=    df_transformed
    else:
        df_combined = df_transformed.merge(df_IMF, how = 'left',on ="Date")

    '''normalize FCI, calculate Covariance Matrix (if IMF FCI is not None)'''
    end_index = None
    for index in range(len(df_combined)):
        if df_combined.iloc[index, 0] == "2020-03":
            end_index = index
            break
    assert (end_index is not None)
    for col_num in range(1, len(df_combined.columns)):
        df_combined.iloc[:, col_num] = scale_series(df_combined.iloc[:, col_num], df_combined.iloc[end_index: , col_num ].mean(), df_combined.iloc[end_index: , col_num ].std())
    corr_coef = np.corrcoef(df_combined.iloc[:, 1:].dropna(), rowvar = False)[-1]
    df_combined = df_combined.sort_values(by= ["Date"], ascending=True, ignore_index=True)

    # check eigenvector

    for i in range(len(df_PCA_decomp.columns)):
        eigenvector = pca.components_[i]
        if (pca.explained_variance_ratio_[i] > 0.2 and ((eigenvector < 0).all() or (eigenvector > 0).all())):
            # output the data combination and eigenvector and explained_variance_ratio
            decomp_id = str(random.randint(10**9, 10**10 - 1)) # random id
            with open("./PCA_pipeline/Output/" + Country_abbr +"/corr/"+decomp_id+".txt", "w") as f:
                print("-"*20, file = f)
                print("id", ":", decomp_id, file = f)
                if df_IMF is not None:
                    print("corr_coef", ":", corr_coef[i], file = f)
                print("explain variance ratio", ":", pca.explained_variance_ratio_[i], file = f)
                print("Weight", ":", file = f)
                for name, weight in zip(df_PCA_decomp.columns, eigenvector):
                    print(name, ":", weight, sep = " ", end = "\n", file = f)
                print("-"*20, file = f)
                f.write("\n")

            ## draw figure
            
            
            plt.plot(df_combined["Date"], df_combined.iloc[:,1+i], "-", color = "r", label = "PCA")
            if df_IMF is not None:
                plt.plot(df_combined["Date"], df_combined["IMF_FCI"], "-", color = "g", label = "IMF FCI")
                plt.title("correlation : "+ str(round(corr_coef[i], 3)))
            else:
                plt.title("number of eigenvectors: " + str(i+1) + 
                          ", No. series:" + str(len(df.columns)-1) + "\n explained variance ratio:" + str(round(pca.explained_variance_ratio_[i], 3))
                                                              )
            plt.xlabel("Date")
            x_major_locator = plt.MultipleLocator(24)
            ax = plt.gca()
            ax.xaxis.set_major_locator(x_major_locator)
            plt.legend(loc = "best")
            plt.savefig("./PCA_pipeline/Output/" + Country_abbr +"/fig/"+decomp_id+".jpg")
            plt.close()



    ''' '''
    

if __name__ == "__main__":
    Country = "Hungary" # Poland, Hungary
    Country_abbr = "Hun" # Pol, Hun

    # Only poland has IMF_FCI
    df_IMF_FCI=None
    if Country_abbr == "Hun" or Country_abbr == "Pol":
        df_IMF_FCI = pd.read_csv("./PCA_pipeline/IMF_FCI_"+Country +".csv")

    ## empty outputs
    if os.path.exists("./PCA_pipeline/Output/" + Country_abbr):
        shutil.rmtree("./PCA_pipeline/Output/" + Country_abbr)
    os.mkdir("./PCA_pipeline/Output/" + Country_abbr)
    os.mkdir("./PCA_pipeline/Output/" + Country_abbr +"/corr")
    os.mkdir("./PCA_pipeline/Output/" + Country_abbr +"/fig")

    ## read in data
    country_df = pd.read_csv(base_dir + Country +'_DataFrame.csv')
    country_comb = generate_combination(Country)

    # run PCA with multiprocessing
    p = Pool(10) 

    for i in range(len(country_comb)):
        p.apply_async(func=PCA_module, args=(country_df[country_comb[i]], Country, Country_abbr, df_IMF_FCI))
        if (i%1000 == 0): print(i//1000, "k", sep = "")
    p.close() 
    p.join()

