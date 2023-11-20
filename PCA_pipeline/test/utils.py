import pandas as pd
import pandas.api.types as ptypes
import sklearn.decomposition
import random
import numpy as np
import matplotlib.pyplot as plt
from itertools import combinations 
from pathlib import Path
base_dir = str(Path().resolve().parent) + '/data/'

def scale_series(series, mean, std):
    return (series - mean)/std


def generate_combination(country_df_col: list):

    # all contries have full bond and equity market data, so use default combinations
    bond_cat_comb = [['Term_Premium'], ['Risk_Premium'], ['Term_Premium', 'Risk_Premium']]
    equity_cat_comb = [['Stock_Prices_mom%_change'], ['Stock_Prices_mom24mma%_change'], ['Stock_Market_Volatility'],
                    ['Stock_Prices_mom%_change', 'Stock_Prices_mom24mma%_change'],
                    ['Stock_Prices_mom%_change', 'Stock_Market_Volatility'],
                    ['Stock_Prices_mom24mma%_change', 'Stock_Market_Volatility'],
                    ['Stock_Prices_mom%_change', 'Stock_Prices_mom24mma%_change', 'Stock_Market_Volatility']]
    
    # some countries lost entry in macro fundamental and money and portfolio flow data, 
    # use set operation to find exist entry in each broad component
    macro_cat = set(['REER', 'Current_Account_Balance_change_yryr%', 'Current_Account_Balance_over_GDP',
                    'One-Day_Repo_Rate_AVG', 'One-Day_Repo_Rate_EOP',
                    'Policy_Rate_&_Fed_Funds_Rate_Differential_AVG', 'Policy_Rate_&_Fed_Funds_Rate_Differential_EOP'])
    mpf_cat = set(['Broad_Money_mo12m%_change', 'Velocity_of_Money_mo12m%_change', 'Portfolio_Flows',
                    'Foreign_Exchange_Reserve_change_yryr%', 'Foreign_Exchange_Reserve_over_GDP', 'Bank_Lending_mo12m%_change'])
    country_df_cols = set(country_df_col)
    country_macro_cat = macro_cat & country_df_cols
    country_mpf_cat = mpf_cat & country_df_cols

    # generate combinations for macro fundamental as a list, each combination is a list of column names that in this combination
    macro_cat_comb = []
    for i in range(len(country_macro_cat)):
        comb = combinations(country_macro_cat, i + 1)
        for c in comb:
            # discard combinations that both have EOP and AVG values
            if 'Policy_Rate_&_Fed_Funds_Rate_Differential_EOP' in c and 'Policy_Rate_&_Fed_Funds_Rate_Differential_AVG' in c:
                continue
            elif 'One-Day_Repo_Rate_EOP' in c and 'One-Day_Repo_Rate_AVG' in c:
                continue
            macro_cat_comb.append(list(c))
    
    # same process for money and portfolio flow data
    mpf_cat_comb = []
    for i in range(len(country_mpf_cat)):
        comb = combinations(country_mpf_cat, i + 1)
        for c in comb:
            mpf_cat_comb.append(list(c))

    # cross product all four broad components' combinations to generate full possible combinations of each country
    # the full combinations is a list, each entry in list is a list of column names
    # the combination can be selected by calling country_df[country_comb[i]]
    country_comb = []
    for b in bond_cat_comb:
        for e in equity_cat_comb:
            for m in macro_cat_comb:
                for p in mpf_cat_comb:
                    country_comb.append(['Date'] + b + e + m + p)
    return country_comb

def generate_PCA(country_df: pd.DataFrame):
    ''' Assert the names and the types of the columns. Assert the cov matrix is all positive. '''
    # assert (df.columns[0] == "Date")
    # assert (ptypes.is_datetime64_dtype(df["Date"]))
    assert all(ptypes.is_numeric_dtype(country_df[col]) for col in country_df.columns[1:])
    country_df = country_df.dropna(axis = "index")
    # assert ((df.cov(numeric_only=True).values > 0).all())

    ''' Get the date range '''
    country_df = country_df.sort_values(by= ["Date"], ascending=False, ignore_index=True)
    # print("The date range is :", df["Date"].iat[-1], "to", df["Date"].iat[0])

    # ''' Scale the data '''
    # for col in df.columns[1:]:
    #     df[col] = scale_series(df[col], df[col].mean(), df[col].std())

    ''' Select data frame that ends at 2020-03 '''
    end_index = None
    for index in range(len(country_df)):
        if country_df.iloc[index, 0] == "2020-03":
            end_index = index
            break
    assert (end_index is not None)
    

    ''' Scale the data '''
    for col_num in range(1, len(country_df.columns)):
        country_df.iloc[:, col_num] = scale_series(country_df.iloc[:, col_num], country_df.iloc[end_index: , col_num ].mean(), country_df.iloc[end_index: , col_num ].std())


    df_PCA_decomp = country_df.iloc[end_index:, 1:] ##TODO: 1:
    ''' PCA decomposition'''
    pca = sklearn.decomposition.PCA(n_components = len(df_PCA_decomp.columns)) 
    pca.fit(df_PCA_decomp)
    df_transformed = pd.DataFrame(np.negative(np.transpose(np.matmul(np.square(pca.components_),np.transpose(country_df.iloc[ :, 1:])))))
    # df_transformed = pd.DataFrame(pca.transform(df.iloc[ :, 1:])) ##TODO: 1:
    df_transformed.insert(0, "Date", country_df["Date"], True)

    return pca, df_transformed

def dump_result(pca: sklearn.decomposition.PCA, df_transformed: pd.DataFrame, country):

    if country == 'Poland' or country == 'Hungary':
        imf_df = pd.read_csv(base_dir + 'IMF_FCI_' + country + '.csv')
        df_transformed = df_transformed.merge(imf_df, how = 'left',on ="Date")
        end_index = None
        for index in range(len(df_transformed)):
            if df_transformed.iloc[index, 0] == "2020-03":
                end_index = index
                break
        assert (end_index is not None)
        for col_num in range(1, len(df_transformed.columns)):
            df_transformed.iloc[:, col_num] = scale_series(df_transformed.iloc[:, col_num], df_transformed.iloc[end_index: , col_num ].mean(), df_transformed.iloc[end_index: , col_num ].std())
        corr_coef = np.corrcoef(df_transformed.iloc[:, 1:].dropna(), rowvar = False)[-1]
        df_transformed = df_transformed.sort_values(by= ["Date"], ascending=True, ignore_index=True)



    for i in range(len(pca.components_)):
        eigenvector = pca.components_[i]
        if (pca.explained_variance_ratio_[i] > 0.3 and ((eigenvector < 0).all() or (eigenvector > 0).all())):
            # output the data combination and eigenvector and explained_variance_ratio
            decomp_id = str(random.randint(10**9, 10**10 - 1)) # random id
            with open("./PCA_pipeline/corr/"+decomp_id+".txt", "w") as f:
                print("-"*20, file = f)
                print("id", ":", decomp_id, file = f)
                print("corr_coef", ":", corr_coef[i], file = f)
                print("explain variance ratio", ":", pca.explained_variance_ratio_[i], file = f)
                print("Weight", ":", file = f)
                for name, weight in zip(df_PCA_decomp.columns, eigenvector):
                    print(name, ":", weight, sep = " ", end = "\n", file = f)
                print("-"*20, file = f)
                f.write("\n")

            ## draw figure
            
            
            plt.plot(df_transformed["Date"], df_transformed.iloc[:,1+i], "-", color = "r", label = "PCA")
            plt.plot(df_transformed["Date"], df_transformed["IMF_FCI"], "-", color = "g", label = "IMF FCI")
            plt.xlabel("Date")
            x_major_locator = plt.MultipleLocator(24)
            ax = plt.gca()
            ax.xaxis.set_major_locator(x_major_locator)
            plt.legend(loc = "best")
            plt.savefig("./PCA_pipeline/fig/"+decomp_id+".jpg")
            plt.close()



    ''' '''