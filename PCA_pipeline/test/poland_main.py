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
from utils import generate_combination, PCA_module

base_dir = str(Path().resolve()) + '/data/'

if __name__ == "__main__":
    country = "Poland" # Poland, Hungary
    country_abbr = "Pol" # Pol, Hun
    country_path = base_dir + country +'_DataFrame.csv'
    dump_path = "./PCA_pipeline/test/Output/" + country_abbr
    txt_path = dump_path + "/corr"
    jpg_path = dump_path + "/fig"

    ## empty outputs
    if os.path.exists(dump_path):
        shutil.rmtree(dump_path)
    os.mkdir(dump_path)
    os.mkdir(txt_path)
    os.mkdir(jpg_path)
    ##

    country_df = pd.read_csv(country_path)
    country_comb = generate_combination(country)
    # PCA_module(country_df[country_comb[0]])

    if country == 'Poland' or country == 'Hungary':
        imf_df = pd.read_csv("./PCA_pipeline/IMF_FCI_" + country + ".csv")


    p = Pool(10) 

    for i in range(len(country_comb)):
        p.apply_async(func=PCA_module, args=(country_df[country_comb[i]], country, country_abbr, imf_df))
        if (i%1000 == 0): print(i//1000, "k", sep = "")
    p.close() 
    p.join()
    # combine_files = (os.listdir("./PCA_pipeline/corr"))
    # with open("./PCA_pipeline/corr/all.txt", "w") as outfile:
    #     for name in combine_files:
    #         if name.endswith("txt"):
    #             with open("./PCA_pipeline/corr/"+name, "r") as readfile:
    #                 shutil.copyfileobj(readfile, outfile)